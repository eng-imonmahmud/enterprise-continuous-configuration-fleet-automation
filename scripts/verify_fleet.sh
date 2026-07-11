#!/bin/bash
set -e

# Load instance ID from Terraform output
cd ../terraform
INSTANCE_ID=$(terraform output -raw instance_id)
cd ../scripts

echo "Checking Systems Manager Managed Instance Status for $INSTANCE_ID..."

# Wait up to 5 minutes for the instance to appear in SSM
MAX_RETRIES=30
RETRY_COUNT=0
STATUS="Unknown"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  STATUS=$(aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$INSTANCE_ID" --query "InstanceInformationList[0].PingStatus" --output text)
  if [ "$STATUS" == "Online" ]; then
    echo "Instance $INSTANCE_ID is Online in Systems Manager."
    break
  fi
  echo "Instance is $STATUS. Waiting 10 seconds... ($RETRY_COUNT/$MAX_RETRIES)"
  sleep 10
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ "$STATUS" != "Online" ]; then
  echo "ERROR: Instance failed to come online in Systems Manager."
  exit 1
fi

echo "Checking State Manager Association Compliance..."
# The associations might take a few minutes to run
MAX_RETRIES=30
RETRY_COUNT=0
COMPLIANCE="Unknown"

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  COMPLIANCE=$(aws ssm list-associations --query "Associations[?Targets[0].Values[0]=='$INSTANCE_ID'].DetailedStatus" --output text)
  
  if [[ "$COMPLIANCE" != *"Pending"* ]] && [[ "$COMPLIANCE" != *"Failed"* ]] && [[ "$COMPLIANCE" != *"Unknown"* ]]; then
     # Check if all associations succeeded
     FAILED_COUNT=$(echo "$COMPLIANCE" | grep -c "Failed" || true)
     SUCCESS_COUNT=$(echo "$COMPLIANCE" | grep -c "Success" || true)
     
     if [ "$FAILED_COUNT" -eq 0 ] && [ "$SUCCESS_COUNT" -gt 0 ]; then
       echo "All State Manager Associations Succeeded."
       break
     fi
  fi
  
  echo "Associations status: $COMPLIANCE. Waiting 10 seconds... ($RETRY_COUNT/$MAX_RETRIES)"
  sleep 10
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ "$RETRY_COUNT" -eq "$MAX_RETRIES" ]; then
  echo "ERROR: State Manager Associations failed or timed out."
  exit 1
fi

echo "Validating Nginx installation via Run Command..."
COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=['systemctl status nginx']" \
    --query "Command.CommandId" \
    --output text)

sleep 5

COMMAND_STATUS=$(aws ssm get-command-invocation \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --query "Status" \
    --output text)

while [ "$COMMAND_STATUS" == "Pending" ] || [ "$COMMAND_STATUS" == "InProgress" ]; do
  sleep 5
  COMMAND_STATUS=$(aws ssm get-command-invocation \
      --command-id "$COMMAND_ID" \
      --instance-id "$INSTANCE_ID" \
      --query "Status" \
      --output text)
done

if [ "$COMMAND_STATUS" == "Success" ]; then
  echo "Nginx is running successfully."
else
  echo "ERROR: Nginx is not running. Command status: $COMMAND_STATUS"
  aws ssm get-command-invocation --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --query "StandardErrorContent" --output text
  exit 1
fi

echo "Validation complete! All checks passed."

$ErrorActionPreference = "Stop"
$env:AWS_DEFAULT_REGION = "eu-central-1"

Set-Location -Path "../terraform"
$INSTANCE_ID = (terraform output -raw instance_id).Trim()
Set-Location -Path "../scripts"

Write-Host "Checking Systems Manager Managed Instance Status for $INSTANCE_ID..."

$MAX_RETRIES = 30
$RETRY_COUNT = 0
$STATUS = "Unknown"

while ($RETRY_COUNT -lt $MAX_RETRIES) {
    $STATUS = (aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$INSTANCE_ID" --query "InstanceInformationList[0].PingStatus" --output text).Trim()
    
    if ($STATUS -eq "Online") {
        Write-Host "Instance $INSTANCE_ID is Online in Systems Manager." -ForegroundColor Green
        break
    }
    
    Write-Host "Instance is $STATUS. Waiting 10 seconds... ($RETRY_COUNT/$MAX_RETRIES)"
    Start-Sleep -Seconds 10
    $RETRY_COUNT++
}

if ($STATUS -ne "Online") {
    Write-Error "Instance failed to come online in Systems Manager."
    exit 1
}

Write-Host "Checking State Manager Association Compliance..."
$RETRY_COUNT = 0
$MAX_RETRIES = 30
$COMPLIANCE = "Unknown"

while ($RETRY_COUNT -lt $MAX_RETRIES) {
    $rawOutput = (aws ssm list-associations --query "Associations[?Targets[0].Values[0]=='$INSTANCE_ID'].DetailedStatus" --output text)
    if ($null -eq $rawOutput) { $COMPLIANCE = "Unknown" } else { $COMPLIANCE = $rawOutput.Trim() }
    
    if ($COMPLIANCE -notmatch "Pending" -and $COMPLIANCE -notmatch "Failed" -and $COMPLIANCE -notmatch "Unknown" -and $COMPLIANCE -notmatch "None") {
        $FAILED_COUNT = ([regex]::Matches($COMPLIANCE, "Failed")).Count
        $SUCCESS_COUNT = ([regex]::Matches($COMPLIANCE, "Success")).Count
        
        if ($FAILED_COUNT -eq 0 -and $SUCCESS_COUNT -gt 0) {
            Write-Host "All State Manager Associations Succeeded." -ForegroundColor Green
            break
        }
    }
    
    Write-Host "Associations status: $COMPLIANCE. Waiting 10 seconds... ($RETRY_COUNT/$MAX_RETRIES)"
    Start-Sleep -Seconds 10
    $RETRY_COUNT++
}

if ($RETRY_COUNT -eq $MAX_RETRIES) {
    Write-Error "State Manager Associations failed or timed out."
    exit 1
}

Write-Host "Validating Nginx installation via Run Command..."
$COMMAND_ID = (aws ssm send-command `
    --instance-ids "$INSTANCE_ID" `
    --document-name "AWS-RunShellScript" `
    --parameters "commands=['systemctl status nginx']" `
    --query "Command.CommandId" `
    --output text).Trim()

Start-Sleep -Seconds 5

$COMMAND_STATUS = "Pending"
while ($COMMAND_STATUS -eq "Pending" -or $COMMAND_STATUS -eq "InProgress") {
    Start-Sleep -Seconds 5
    $COMMAND_STATUS = (aws ssm get-command-invocation `
        --command-id "$COMMAND_ID" `
        --instance-id "$INSTANCE_ID" `
        --query "Status" `
        --output text).Trim()
}

if ($COMMAND_STATUS -eq "Success") {
    Write-Host "Nginx is running successfully." -ForegroundColor Green
} else {
    Write-Error "Nginx is not running. Command status: $COMMAND_STATUS"
    $ERROR_LOG = (aws ssm get-command-invocation --command-id "$COMMAND_ID" --instance-id "$INSTANCE_ID" --query "StandardErrorContent" --output text)
    Write-Host "Error Log: $ERROR_LOG" -ForegroundColor Red
    exit 1
}

Write-Host "Validation complete! All checks passed." -ForegroundColor Green
exit 0

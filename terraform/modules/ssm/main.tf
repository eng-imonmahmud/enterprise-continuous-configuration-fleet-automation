resource "aws_ssm_parameter" "app_name" {
  name  = "/${var.project_name}/${var.environment}/app_name"
  type  = "String"
  value = "EnterpriseFleetApp"
}

resource "aws_ssm_parameter" "environment" {
  name  = "/${var.project_name}/${var.environment}/env"
  type  = "String"
  value = var.environment
}

resource "aws_ssm_parameter" "owner" {
  name  = "/${var.project_name}/${var.environment}/owner"
  type  = "String"
  value = var.owner
}

resource "aws_ssm_document" "install_nginx" {
  name            = "${var.project_name}-install-nginx"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("${path.root}/../documents/install_nginx.yaml")
}

resource "aws_ssm_document" "install_cw_agent" {
  name            = "${var.project_name}-install-cw-agent"
  document_type   = "Command"
  document_format = "YAML"
  content         = file("${path.root}/../documents/install_cw_agent.yaml")
}

resource "aws_ssm_association" "nginx_association" {
  name = aws_ssm_document.install_nginx.name

  targets {
    key    = "InstanceIds"
    values = [var.instance_id]
  }

  compliance_severity = "CRITICAL"
}

resource "aws_ssm_association" "cw_agent_association" {
  name = aws_ssm_document.install_cw_agent.name

  targets {
    key    = "InstanceIds"
    values = [var.instance_id]
  }

  compliance_severity = "CRITICAL"
}

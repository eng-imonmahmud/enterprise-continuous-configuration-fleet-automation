output "nginx_document_name" {
  value = aws_ssm_document.install_nginx.name
}

output "cw_agent_document_name" {
  value = aws_ssm_document.install_cw_agent.name
}

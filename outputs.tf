# Output the public IP of the instance
output "instance_public_ip" {
  value = aws_instance.flask_app.public_ip
}

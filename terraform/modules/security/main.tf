#########################################
# Platform Security Group
#########################################

resource "aws_security_group" "platform" {
  name        = "${var.project_name}-${var.environment}-platform-sg"
  description = "Security group for the enterprise cloud platform"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-platform-sg"
  }
}

# 1. Creación del Application Load Balancer
resource "aws_lb" "this" {
  name               = "alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(
    var.tags,
    {
      Name = "alb-${var.environment}"
    }
  )
}

#2. Creación del Target Group (Grupo Objetivo)
resource "aws_lb_target_group" "this" {
  name        = "tg-${var.environment}-backend-v2"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  tags = merge(
    var.tags, {
      Name = "tg-${var.environment}-backend"
    }
  )
}

#3. Listener HTTP (Puerto 80)
# Se redirecciona todo el trafico a HTTPS (443) si existe certificado SSL, o lo envia al target group si no
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != "" ? "redirect" : "forward"

    #Si hay certificado, fuerza la redirección segura 301
    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTPS_301"
      }
    }

    #Si no hay certificado SSL (entorno dev basico), reenvia directo al Target Group (TG)
    target_group_arn = var.certificate_arn == "" ? aws_lb_target_group.this.arn : null
  }
}

#4. Listener HTTPS (Puerto 443) - Se crea solo si enviamos un certificado SSL
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

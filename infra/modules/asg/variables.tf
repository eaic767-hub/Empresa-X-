variable "environment" {
  description = "Entorno de despliegue dev"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "target_group_arn" {
  description = "ARN del Target Group del ALB al que se registrarán las instancias"
  type        = string
}

variable "ami_id" {
  description = "ID de la AMI de Ubuntu traida del módulo EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo de Instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "instance_profile_name" {
  description = "Nombre de Instance Profile para asociar a la EC2"
  type        = string
}

variable "ec2_security_group_id" {
  description = "ID del Security Group para las instancias EC2"
  type        = string
}

variable "root_volume_size" {
  description = "Tamaño del disco principal en GB"
  type        = number
  default     = 20
}

variable "min_size" {
  description = "Número minimo de las instancias en el ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Número máximo de instancias en el ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Numero deseado de instancias en el ASG"
  type        = number
  default     = 1
}


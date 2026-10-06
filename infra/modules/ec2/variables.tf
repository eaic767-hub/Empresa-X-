variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_key_path" {
  type    = string
  default = "nginx-server.key.pub"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "root_volume_size" {
  description = "tamaño de disco de la instancia en Gb"
  type        = number
  default     = 8
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "private_subnet_id" {
  type        = string
  description = "ID de la subred privada donde se desplegará la instancia"
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
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
  description ="tamaño de disco de la instancia en Gb"
  type = number
  default = 8
}
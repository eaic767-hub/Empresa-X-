variable "environment" {
    type = string
    description ="Nombre del Entorno"
}

variable "vpc_id" {
    type = string
    description = "ID de la VPC donde estara el Security Group de la BD"
}

variable "private_subnet_ids" {
    type = list(string)
    description = "Lista de IDs de subredes privadas para el Subnet Group de la BD"
}

variable "ec2_security_group_id" {
    type =string
    description ="ID del Security Group de la EC2 para permitirle el acceso a la BD"
}

variable "db_name" {
    type= string
    description = "Nombre inicial de la BD"
    default = "appdb"
}

variable "db_user" {
    type = string
    description = "Usuario Maestro de la BD"
    default = "dbadmin"
}

variable "db_password" {
    type = string
    description = "Contraseña de la BD"
    sensitive=true #OJO IMPORTANTE PORQUE NO MUESTRA EL TEXTO PLANO EN CONSOLA O TRAZAS EN TERRAFORM APPLY 
}

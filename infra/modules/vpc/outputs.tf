output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_subnet.id] # 👈 Se encierra entre [] para devolver una lista
}

output "private_subnet_ids" {
  value = [aws_subnet.private_subnet.id] # 👈 Se encierra entre [] para devolver una lista
}

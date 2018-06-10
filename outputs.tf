output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

output "WebServer1IP" {
  value = "${aws_instance.Web.public_dns}"
}

output "WebServer2IP" {
  value = "${aws_instance.Web2.public_dns}"
}

output "DbServerIP" {
  value = "${aws_instance.DB.private_dns}"
}

output "ALBDns" {
  value = "${aws_alb.main.dns_name}"
}

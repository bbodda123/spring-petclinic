locals {
  admin_cidr_final = "${data.external.my_ip.result.ip}/32"
}

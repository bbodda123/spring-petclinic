locals {
  admin_cidr = "${data.external.my_ip.result.ip}/32"
}

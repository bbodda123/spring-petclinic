data "external" "my_ip" {
  program = [
    "bash",
    "-c",
    "ip=$(curl -s https://api.ipify.org) && jq -n --arg ip \"$ip\" '{ip: $ip}'"
  ]
}

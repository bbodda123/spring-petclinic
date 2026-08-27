data "external" "my_ip" {
  program = [
    "bash",
    "-c",
    "curl -s https://api.ipify.org | awk '{printf \"{\\\"ip\\\":\\\"%s\\\"}\\n\", $0}'"
  ]
}
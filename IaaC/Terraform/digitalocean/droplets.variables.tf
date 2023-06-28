variable "basic_droplet_sizes" {
  type = map(string)
  default = {
    "default"  = "512mb"
    "nano"     = "512mb"
    "small-1"  = "s-1vcpu-1gb"
    "small-2"  = "s-1vcpu-2gb"
    "medium-1" = "s-2vcpu-2gb"
    "medium-2" = "s-2vcpu-4gb"
    "large"    = "s-4vcpu-8gb"
    "x-large"  = "s-8vcpu-16gb"
  }
}

variable "region" {
  type = map(string)
  default = {
    "default" = "sfo3"
    "sfo1"    = "San Francisco 1"
    "sfo2"    = "San Francisco 2"
    "sfo3"    = "San Francisco 3"
    "nyc1"    = "New York 1"
    "nyc2"    = "New York 2"
    "nyc3"    = "New York 3"
    "ams3"    = "Amsterdam 3"
  }
}

variable "ssh_keys" {
  type = map(string)
  default = {
    "sshkey1"     = "key-registered-1"
    "sshkey2"     = "key-registered-2"
  }
}

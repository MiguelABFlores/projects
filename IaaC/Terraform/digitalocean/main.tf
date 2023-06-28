terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_account" "account_info" {}

# Authentication with SSH keys
data "digitalocean_ssh_key" "ssh_keys" {
  for_each = var.ssh_keys
  name     = each.value
}

# Create a Project and assign resources to it
resource "digitalocean_project" "project_name" {
  name        = "Project Name"
  description = "A project..."
  purpose     = "Purpose"
  resources = [
    digitalocean_droplet.bastion[0].urn,
    digitalocean_droplet.blueviper_web[0].urn,
    digitalocean_droplet.blueviper_jenkins[0].urn
  ]
}

# VPC
resource "digitalocean_vpc" "vpc_network" {
  name        = "vpc-network"
  description = "VPC for the project."
  region      = var.region["default"]
  ip_range    = "10.0.0.0/16"
}

# We declare which droplets will be assigned reserved ips
locals {
  droplets = [
    {
      name        = "server_1"
      droplet_ref = digitalocean_droplet.server_1[0]
    },
    {
      name        = "server_2"
      droplet_ref = digitalocean_droplet.server_2[0]
    },
    {
      name        = "server_3"
      droplet_ref = digitalocean_droplet.server_3[0]
    },
  ]
}

# We assign reserved ips to the droplets in locals
resource "digitalocean_reserved_ip" "project_reservedip" {
  for_each = { for droplet in local.droplets : droplet.name => droplet }

  droplet_id = each.value.droplet_ref.id
  region     = each.value.droplet_ref.region
}

# Instance type server_1
resource "digitalocean_droplet" "server_1" {
  count    = 1
  image    = "ubuntu-22-04-x64"
  name     = "server1-${var.region["default"]}-${count.index + 1}"
  droplet_tags = ["tag1", "tag2", "tagn..."]
  region   = var.region["default"]
  size     = var.basic_droplet_sizes["small-1"]
  initial_user  = "user"
  ssh_keys = [
    for ssh_key in data.digitalocean_ssh_key.ssh_keys : ssh_key.id
  ]

  vpc_uuid = digitalocean_vpc.vpc_network.id

  lifecycle {
    create_before_destroy = true
  }
}

# Instance creation web server
resource "digitalocean_droplet" "server_2" {
  count    = 1
  image    = "ubuntu-22-04-x64"
  name     = "server2-${var.region["default"]}-${count.index + 1}"
  droplet_tags = ["tag1", "tag2", "tagn..."]
  region   = var.region["default"]
  size     = var.basic_droplet_sizes["small-1"]
  initial_user  = "user"
  ssh_keys = [
    for ssh_key in data.digitalocean_ssh_key.ssh_keys : ssh_key.id
  ]

  vpc_uuid = digitalocean_vpc.vpc_network.id

  lifecycle {
    create_before_destroy = true
  }
}

# Instance creation jenkins
resource "digitalocean_droplet" "server_3" {
  count    = 1
  image    = "ubuntu-22-04-x64"
  name     = "server3-${var.region["default"]}-${count.index + 1}"
  droplet_tags = ["tag1", "tag2", "tagn..."]
  region   = var.region["default"]
  size     = var.basic_droplet_sizes["small-1"]
  initial_user  = "user"
  ssh_keys = [
    for ssh_key in data.digitalocean_ssh_key.ssh_keys : ssh_key.id
  ]

  vpc_uuid = digitalocean_vpc.vpc_network.id

  lifecycle {
    create_before_destroy = true
  }
}

# Output of the terraform actions
output "droplets_info" {
  value = {
    droplet_limit   = data.digitalocean_account.account_info.droplet_limit
    server1_ip      = digitalocean_droplet.server_1[0].ipv4_address
    server1_type    = "Public"
    server2_ip      = digitalocean_droplet.server_2[0].ipv4_address
    server2_type    = "Private"
    server3_ip      = digitalocean_droplet.server_3[0].ipv4_address
    server3_type    = "Private"
    vpc_name        = digitalocean_vpc.vpc_network.name
    vpc_ip_range    = digitalocean_vpc.vpc_network.ip_range
  }
}

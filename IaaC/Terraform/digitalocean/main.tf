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
data "digitalocean_ssh_key" "g15_key" {
  name = "MiguelABFlores-G15-Personal"
}

# Create a Project and assign resources to it
resource "digitalocean_project" "blueviper_project" {
  name        = "Blue Viper"
  description = "A project to represent development of my portfolio with CI/CD."
  purpose     = "Web Application"
  resources = [
    digitalocean_droplet.bastion[0].urn,
    digitalocean_droplet.blueviper_web[0].urn,
    digitalocean_droplet.blueviper_jenkins[0].urn
  ]
}

# VPC
resource "digitalocean_vpc" "blueviper_network" {
  name        = "blueviper-network"
  description = "VPC for the project."
  region      = var.region["default"]
  ip_range    = "10.0.0.0/16"
}

# We declare which droplets will be assigned reserved ips
locals {
  droplets = [
    {
      name        = "bastion"
      droplet_ref = digitalocean_droplet.bastion[0]
    },
    {
      name        = "blueviper_web"
      droplet_ref = digitalocean_droplet.blueviper_web[0]
    },
    {
      name        = "blueviper_jenkins"
      droplet_ref = digitalocean_droplet.blueviper_jenkins[0]
    },
  ]
}

# We assign reserved ips to the droplets in locals
resource "digitalocean_reserved_ip" "blueviper_reservedip" {
  for_each = { for droplet in local.droplets : droplet.name => droplet }

  droplet_id = each.value.droplet_ref.id
  region     = each.value.droplet_ref.region
}

# Instance bastion
resource "digitalocean_droplet" "bastion" {
  count    = 1
  image    = "ubuntu-22-04-x64"
  name     = "bastion-${var.region["default"]}-${count.index + 1}"
  region   = var.region["default"]
  size     = var.basic_droplet_sizes["small-1"]
  ssh_keys = [data.digitalocean_ssh_key.g15_key.id]

  vpc_uuid = digitalocean_vpc.blueviper_network.id

  lifecycle {
    create_before_destroy = true
  }
}

# Instance creation web server
resource "digitalocean_droplet" "blueviper_web" {
  count    = 1
  image    = "ubuntu-22-04-x64"
  name     = "blueviper-web-${var.region["default"]}-${count.index + 1}"
  region   = var.region["default"]
  size     = var.basic_droplet_sizes["small-1"]
  ssh_keys = [data.digitalocean_ssh_key.g15_key.id]

  vpc_uuid = digitalocean_vpc.blueviper_network.id

  lifecycle {
    create_before_destroy = true
  }
}

# Instance creation jenkins
resource "digitalocean_droplet" "blueviper_jenkins" {
  count    = 1
  image    = "ubuntu-22-04-x64"
  name     = "blueviper-jenkins-${var.region["default"]}-${count.index + 1}"
  region   = var.region["default"]
  size     = var.basic_droplet_sizes["small-1"]
  ssh_keys = [data.digitalocean_ssh_key.g15_key.id]

  vpc_uuid = digitalocean_vpc.blueviper_network.id

  lifecycle {
    create_before_destroy = true
  }
}

# Output of the terraform actions
output "droplets_info" {
  value = {
    droplet_limit   = data.digitalocean_account.account_info.droplet_limit
    bastion_ip      = digitalocean_droplet.bastion[0].ipv4_address
    bastion_type    = "Public"
    web_server_ip   = digitalocean_droplet.blueviper_web[0].ipv4_address
    web_server_type = "Private"
    jenkins_ip      = digitalocean_droplet.blueviper_jenkins[0].ipv4_address
    jenkins_type    = "Private"
    vpc_name        = digitalocean_vpc.blueviper_network.name
    vpc_ip_range    = digitalocean_vpc.blueviper_network.ip_range
  }
}

terraform {
  backend "http" {
  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.80.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    vngcloud = {
      source  = "vngcloud/vngcloud"
      version = "~> 1.3"
    }
  }
}

provider "vngcloud" {
  client_id     = var.client_id
  client_secret = var.client_secret
}

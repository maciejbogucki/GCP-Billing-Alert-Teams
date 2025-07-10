terraform {
  required_version = ">= 0.13"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.41"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.41"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.0"
    }
  }
  backend "gcs" {
  }
}

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

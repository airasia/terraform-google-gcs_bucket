terraform {
  required_version = "0.12.24" # see https://releases.hashicorp.com/terraform/
  experiments      = [variable_validation]
}

provider "google" {
  version = "3.13.0" # see https://github.com/terraform-providers/terraform-provider-google/releases
}

locals {
  bucket_name     = var.omit_name_suffix ? var.bucket_name : format("%s-%s", var.bucket_name, var.name_suffix)
  bucket_location = var.location != null ? var.location : data.google_client_config.google_client.region
  bucket_labels   = merge(var.labels, { "name_suffix" = var.name_suffix })
}

data "google_client_config" "google_client" {}

resource "google_project_service" "storage_api" {
  service            = "storage-api.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "gcs_bucket" {
  name               = local.bucket_name
  location           = local.bucket_location
  labels             = local.bucket_labels
  bucket_policy_only = var.uniform_access
  versioning { enabled = var.versioning_enabled }
  depends_on = [google_project_service.storage_api]
}

resource "google_storage_bucket_iam_member" "public_viewers" {
  count  = var.public_read ? 1 : 0
  bucket = google_storage_bucket.gcs_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

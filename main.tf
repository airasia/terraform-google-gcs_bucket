terraform {
  required_version = ">= 0.12.24" # see https://releases.hashicorp.com/terraform/
  experiments      = [variable_validation]
}

provider "google" {
  version = ">= 3.13.0" # see https://github.com/terraform-providers/terraform-provider-google/releases
}

locals {
  bucket_name     = var.omit_name_suffix ? var.bucket_name : format("%s-%s", var.bucket_name, var.name_suffix)
  bucket_location = var.location != null ? var.location : data.google_client_config.google_client.region
  bucket_labels   = merge(var.labels, { "name_suffix" = var.name_suffix })
}

data "google_client_config" "google_client" {}

resource "random_string" "random_id" {
  length  = 4
  special = false
  upper   = false
}

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

resource "google_storage_bucket_iam_member" "object_admins" {
  count  = length(var.object_admin_usergroups)
  bucket = google_storage_bucket.gcs_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "group:${var.object_admin_usergroups[count.index]}"
}

module "reader_sa" {
  source       = "airasia/service_account/google"
  version      = "1.1.1"
  providers    = { google = google }
  name_suffix  = var.name_suffix
  account_id   = "gcs-reader-sa-${random_string.random_id.result}"
  display_name = "gcs-${google_storage_bucket.gcs_bucket.name}-object-reader"
  description  = "Allowed to read all objects from the '${google_storage_bucket.gcs_bucket.name}' GCS bucket"
}

module "writer_sa" {
  source       = "airasia/service_account/google"
  version      = "1.1.1"
  providers    = { google = google }
  name_suffix  = var.name_suffix
  account_id   = "gcs-writer-sa-${random_string.random_id.result}"
  display_name = "gcs-${google_storage_bucket.gcs_bucket.name}-object-writer"
  description  = "Allowed to CRUD objects in the '${google_storage_bucket.gcs_bucket.name}' GCS bucket"
}

resource "google_storage_bucket_iam_member" "reader_sa_permission" {
  count  = var.enable_reader_sa ? 1 : 0
  bucket = google_storage_bucket.gcs_bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${module.reader_sa.email}"
}

resource "google_storage_bucket_iam_member" "writer_sa_permission" {
  count  = var.enable_writer_sa ? 1 : 0
  bucket = google_storage_bucket.gcs_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.writer_sa.email}"
}

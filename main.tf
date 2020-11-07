terraform {
  required_version = ">= 0.13.1" # see https://releases.hashicorp.com/terraform/
}

locals {
  is_domain_name    = length(regexall("[.]", var.bucket_name)) > 0 # contains a dot/period ?
  public_read       = local.is_domain_name ? true : var.public_read
  uniform_access    = local.is_domain_name ? true : var.uniform_access
  enable_versioning = local.is_domain_name ? true : var.enable_versioning
  bucket_name       = local.is_domain_name ? var.bucket_name : format("%s-%s", var.bucket_name, var.name_suffix)
  bucket_labels     = merge(var.labels, { "name_suffix" = var.name_suffix })
  bucket_location   = var.location != "" ? var.location : data.google_client_config.google_client.region
}

data "google_client_config" "google_client" {}

resource "google_project_service" "storage_api" {
  service            = "storage-api.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "gcs_bucket" {
  name                        = local.bucket_name
  location                    = local.bucket_location
  labels                      = local.bucket_labels
  uniform_bucket_level_access = local.uniform_access
  force_destroy               = false
  website {
    main_page_suffix = var.website_config.index_page
    not_found_page   = var.website_config.error_page
  }
  versioning { enabled = local.enable_versioning }
  depends_on = [google_project_service.storage_api]
  lifecycle {
    ignore_changes = [ # See https://www.terraform.io/docs/configuration/resources.html#ignore_changes
      cors             # ignore CORS changes. Use 'gsutil' tool instead. See https://cloud.google.com/storage/docs/configuring-cors
    ]
  }
}

resource "google_storage_bucket_iam_member" "public_viewers" {
  count  = local.public_read ? 1 : 0
  bucket = google_storage_bucket.gcs_bucket.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_iam_member" "object_admins" {
  for_each = toset(var.admin_usergroups)
  bucket   = google_storage_bucket.gcs_bucket.name
  role     = "roles/storage.objectAdmin"
  member   = "group:${each.value}"
}

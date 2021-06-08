terraform {
  required_version = ">= 0.13.1" # see https://releases.hashicorp.com/terraform/
}

locals {
  is_domain_name        = length(regexall("[.]", var.bucket_name)) > 0 # contains a dot/period ?
  public_read           = local.is_domain_name ? true : var.public_read
  uniform_access        = local.is_domain_name ? true : var.uniform_access
  enable_versioning     = local.is_domain_name ? true : var.enable_versioning
  bucket_name           = local.is_domain_name ? var.bucket_name : format("%s-%s", var.bucket_name, var.name_suffix)
  bucket_labels         = merge(var.labels, { "name_suffix" = var.name_suffix })
  bucket_location       = var.location != "" ? var.location : data.google_client_config.google_client.region
  sanitized_bucket_name = replace(var.bucket_name, ".", "-")
  resource_name_suffix  = format("%s-%s", local.sanitized_bucket_name, var.name_suffix)
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
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age            = lookup(lifecycle_rule.value.condition, "age", null)
        created_before = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state     = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class = contains(keys(lifecycle_rule.value.condition), "matches_storage_class") ? (
          split(",", lifecycle_rule.value.condition["matches_storage_class"])
        ) : null
        num_newer_versions = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
      }
    }
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

# Bucket LB components start here ------------------------------------------------------------------

resource "google_compute_backend_bucket" "bucket_backend" {
  count       = local.is_domain_name ? 1 : 0
  name        = format("bucket-backend-%s", local.resource_name_suffix)
  bucket_name = local.bucket_name
}

resource "google_compute_url_map" "url_map" {
  count           = local.is_domain_name ? 1 : 0
  name            = format("bucket-urlmap-%s", local.resource_name_suffix)
  default_service = google_compute_backend_bucket.bucket_backend.0.self_link
}

resource "google_compute_managed_ssl_certificate" "mcrt" {
  count = local.is_domain_name ? 1 : 0
  name  = format("bucket-cert-%s", local.resource_name_suffix)
  managed { domains = [local.bucket_name] }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  count            = local.is_domain_name ? 1 : 0
  name             = format("bucket-proxy-%s", local.resource_name_suffix)
  url_map          = google_compute_url_map.url_map.0.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.mcrt.0.self_link]
}

resource "google_compute_global_address" "lb_ip" {
  count        = local.is_domain_name ? 1 : 0
  name         = format("lb-ip-%s", local.resource_name_suffix)
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "fw_rule" {
  count      = local.is_domain_name ? 1 : 0
  name       = format("bucket-fwrule-%s", local.resource_name_suffix)
  target     = google_compute_target_https_proxy.https_proxy.0.self_link
  ip_address = google_compute_global_address.lb_ip.0.address
  port_range = "443"
}

# Bucket LB components end here --------------------------------------------------------------------

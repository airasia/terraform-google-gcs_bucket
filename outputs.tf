output "usage_IAM_roles" {
  description = "Basic IAM role(s) that are generally necessary for using the resources in this module. See https://cloud.google.com/iam/docs/understanding-roles."
  value = [
    "roles/storage.objectAdmin",
  ]
}

output "bucket_name" {
  description = "Outputs the finally constructed bucket name. Will be necessary for external resources (eg: ServiceAccounts) to be granted permissions to read/write to."
  value       = google_storage_bucket.gcs_bucket.name
}

output "lb_ip_address" {
  description = "The IP address that is reserved by the load-balancer (if any) of this bucket."
  value       = local.create_bucket_lb ? google_compute_global_address.lb_ip.0.address : null
}

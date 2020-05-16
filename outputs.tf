output "usage_IAM_roles" {
  description = "Basic IAM role(s) that are generally necessary for using the resources in this module. See https://cloud.google.com/iam/docs/understanding-roles."
  value = [
    "roles/storage.objectAdmin",
  ]
}

output "reader_sa_email" {
  description = "Email address of a ServiceAccount that may have permission(s) to read all objects in the GCS bucket."
  value       = module.reader_sa.email
}

output "writer_sa_email" {
  description = "Email address of a ServiceAccount that may have permission(s) to CRUD objects in the GCS bucket."
  value       = module.writer_sa.email
}

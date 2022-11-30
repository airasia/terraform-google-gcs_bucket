# ----------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "name_suffix" {
  description = "An arbitrary suffix that will be added to the end of the resource name(s). For example: an environment name, a business-case name, a numeric id, etc."
  type        = string
  validation {
    condition     = length(var.name_suffix) <= 14
    error_message = "A max of 14 character(s) are allowed."
  }
}

variable "bucket_name" {
  description = "A universally unique name for the bucket. Considered a 'domain name' if the value contains one (or more) period/dot [.]."
  type        = string
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "location" {
  description = "Regional / Dual-Regional / Multi-Regional location of the GCS bucket. Defaults to the google provider's region if nothing is specified here. See https://cloud.google.com/storage/docs/locations#available_locations."
  type        = string
  default     = ""
}

variable "storage_class" {
  description = "The storage class of the GCS bucket. Defaults to 'STANDARD' if nothing is specified here. Available options include 'STANDARD', 'NEARLINE', 'COLDLINE', 'ARCHIVE'. See https://cloud.google.com/storage/docs/storage-classes."
  type        = string
  default     = "STANDARD"
}

variable "uniform_access" {
  description = "If set to true, all objects in the GCS bucket will have the same access levels (uniform). Set this to 'false' to be able to specify distinct access-levels to individual objects explicitly (fine-grained). Cannot be set to 'false' if 90 days have passed with the 'true' setting.  Considered 'true' if 'var.bucket_name' is a domain name."
  type        = bool
  default     = false
}

variable "public_read" {
  description = "Whether the objects in the GCS bucket should be publicly readable by the open internet or not. Considered 'true' if 'var.bucket_name' is a domain name."
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Whether objects in the bucket should be versioneed or not. Considered 'true' if 'var.bucket_name' is a domain name."
  type        = bool
  default     = false
}

variable "create_bucket_lb" {
  description = "Whether to create a load balancer for this GCS bucket - complete with bucket-backend, forwarding rules, google managed certificate etc. Considered 'true' if 'var.bucket_name' is a domain name."
  type        = bool
  default     = false
}

variable "website_config" {
  description = "The default HTML pages that should be used for index and 404 pages."
  type = object({
    index_page = string
    error_page = string
  })
  default = {
    index_page = "index.html"
    error_page = "404.html"
  }
}

variable "admin_usergroups" {
  description = "List of email addresses of usergroups that may have permission to administer (CRUD) objects in the GCS bucket."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "A map of key-value string labels for organizing the GCS bucket."
  type        = map(string)
  default     = {}
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules to configure. Accepts action.type, action.storage_class, condition.age, condition.created_before, condition.with_state, condition.matches_storage_class, condition.num_newer_versions. Format is same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket.html#lifecycle_rule. Except condition.matches_storage_class should be a comma delimited string."
  type = set(object({
    action    = map(string)
    condition = map(string)
  }))
  default = []
}

variable "lb_ssl_certs" {
  description = "A list of additional SslCertificate names that can be used for SSL connections between end-users and the bucket load balancer. These additional certificates must be available in the same GCP project as the bucket itself. These certificates will be used in addition to the google-managed certs already created (if any) by this module."
  type        = list(string)
  default     = []
}

variable "lb_ip_name" {
  description = "Name of the static external IP that is created for the load-balancer. For backward-compatibility only. Not recommended for general use. Will be used only if \"var.create_bucket_lb\" is \"true\"."
  type        = string
  default     = ""
}

variable "lb_ssl_policy" {
  description = "A reference (self-link) to an SSLPolicy that will be associated with the bucket load-balancer (if any). If this variable is not set, a default SSL Policy (created & managed by google) will be used - which usually follows **COMPATIBLE** profile with **TLS v1.0**."
  type        = string
  default     = ""
}

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
  type = set(object({
    action = map(string)
    condition = map(string)
  }))
  description = "List of lifecycle rules to configure. Format is the same as described in provider documentation https://www.terraform.io/docs/providers/google/r/storage_bucket.html#lifecycle_rule except condition.matches_storage_class should be a comma delimited string."
  default     = []
}

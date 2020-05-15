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
  description = "A universally unique name for the bucket."
  type        = string
}

# ----------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

variable "omit_name_suffix" {
  description = "Whether to include (or omit) the name suffix from being used in the bucket name."
  type        = bool
  default     = false
}

variable "location" {
  description = "Regional / Dual-Regional / Multi-Regional location of the GCS bucket. Defaults to the google provider's region if nothing is specified here. See https://cloud.google.com/storage/docs/locations#available_locations."
  type        = string
  default     = null
}

variable "uniform_access" {
  description = "If set to true, all objects in the GCS bucket will have the same access levels (uniform). Set this to 'false' to be able to specify distonct access-levels to individual objects explicitly (fine-grained). Cannot be set to 'false' if 90 days have passed with the 'true' setting."
  type        = bool
  default     = false
}

variable "public_read" {
  description = "Whether the objects in the GCS bucket should be publicly readable by the open internet or not."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Whether objects in the bucket should be versioneed or not."
  type        = bool
  default     = false
}

variable "labels" {
  description = "A map of key-value string labels for organizing the GCS bucket."
  type        = map(string)
  default     = {}
}

variable "gcs_timeout" {
  description = "How long a GCS bucket operation is allowed to take before being considered a failure."
  type        = string
  default     = "5m"
}

variable "gcf_location" {
  description = "GCF deployment region"
  type        = string
}

variable "gcf_max_instance_count" {
  type        = number
  description = "MAX number of GCF instances"
}

variable "gcf_timeout_seconds" {
  type        = number
  description = "GCF execution timeout"
}

variable "gcs_location" {
  description = "GCS deployment region"
  type        = string
}

variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "csj_schedule" {
  description = "Cloud Schedule Job scheduler"
  type        = string
}

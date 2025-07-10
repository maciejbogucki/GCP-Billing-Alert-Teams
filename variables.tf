variable "project_id" {
  description = "GCP project ID."
  type        = string
  validation {
    condition     = var.project_id != ""
    error_message = "Error: project_id is required"
  }
}

variable "enable_apis" {
  type        = string
  description = "Whether or not to enable underlying apis in this solution."
  default     = true
}

variable "time_to_enable_apis" {
  description = "Time to enable APIs, approximate estimate is 5 minutes, can be more."
  type        = string
  default     = "30s"
}

variable "region" {
  description = "GCF deployment location/region."
  type        = string
  default     = "us-central1"
}

variable "gcf_max_instance_count" {
  type        = number
  description = "MAX number of GCF instances"
  default     = 1
}

variable "gcf_timeout_seconds" {
  type        = number
  description = "GCF execution timeout"
  default     = 120
}

variable "gcf_http_ingress_type_index" {
  type        = number
  description = "Ingres type index."
  default     = 1 # should be 1 or 2 in production environments
  # Index values map into:[ALLOW_ALL ALLOW_INTERNAL_ONLY ALLOW_INTERNAL_AND_GCLB]
}

variable "gcf_require_http_authentication" {
  type        = bool
  description = "Require authentication. Manage authorized users with Cloud IAM."
  default     = false # should be true in production environments
}

variable "gcf_annotation_features" {
  type        = string
  description = "Requested annotation features."
  default     = "FACE_DETECTION,PRODUCT_SEARCH,SAFE_SEARCH_DETECTION"
  # options: CROP_HINTS,DOCUMENT_TEXT_DETECTION,FACE_DETECTION,IMAGE_PROPERTIES,LABEL_DETECTION,
  #           LANDMARK_DETECTION,LOGO_DETECTION,OBJECT_LOCALIZATION,PRODUCT_SEARCH,SAFE_SEARCH_DETECTION,
  #           TEXT_DETECTION,WEB_DETECTION
}

variable "gcf_log_level" {
  type        = string
  description = "Set logging level for cloud functions."
  default     = ""
  # options are empty string or python logging level: NOTSET, DEBUG,INFO, WARNING, ERROR, CRITICAL
}

variable "gcf_location" {
  description = "GCF deployment region"
  type        = string
  default     = "us-central1"
}

variable "gcs_location" {
  description = "GCS deployment region"
  type        = string
  default     = "US"
}

variable "csj_schedule" {
  description = "Cloud Schedule Job scheduler"
  type        = string
  default     = "0 8 * * *"
}

variable "labels" {
  description = "A map of key/value label pairs to assign to the resources."
  type        = map(string)

  default = {
    app = "terraform-ml-image-annotation-gcf"
  }
}

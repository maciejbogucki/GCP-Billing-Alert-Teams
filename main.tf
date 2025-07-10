data "google_project" "project" {
  project_id = var.project_id
}

module "project-services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "18.0"
  disable_services_on_destroy = false

  project_id  = var.project_id
  enable_apis = var.enable_apis

  activate_apis = [
    "compute.googleapis.com",
    # required for GCF operation
    "cloudfunctions.googleapis.com",
    "logging.googleapis.com",
    "artifactregistry.googleapis.com",
    "pubsub.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    # Vision API
    "bigquery.googleapis.com",
    # events
    "eventarc.googleapis.com",
    "storage.googleapis.com",
    # other:
    "iam.googleapis.com",
    "secretmanager.googleapis.com",
    # Cloud Scheduler API - Error 403: Cloud Scheduler API has not been used in project xxx
    "cloudscheduler.googleapis.com",
  ]

  activate_api_identities = [
    {
      api = "eventarc.googleapis.com"
      roles = [
        "roles/eventarc.serviceAgent",
      ]
    },
  ]
}

resource "null_resource" "previous_time" {}

# gate resource creation until APIs are enabled, using approximate timeout
# if terraform reports an error, run "apply" again
resource "time_sleep" "wait_for_apis" {
  depends_on = [
    module.project-services
  ]

  create_duration = var.time_to_enable_apis
}

data "google_compute_zones" "cz_available" {
  depends_on = [
    module.project-services
  ]
  project = var.project_id
  region  = var.region
}

# Service Account for GCS, generates/publishes bucket events.
data "google_storage_project_service_account" "gcs_account" {
  depends_on = [time_sleep.wait_for_apis]
}

data "google_compute_default_service_account" "default" {
  depends_on = [time_sleep.wait_for_apis]
}

module "cloudfunction" {
  source     = "./module/cloudfunction"
  depends_on = [time_sleep.wait_for_apis]

  gcf_location           = var.gcf_location
  gcf_max_instance_count = var.gcf_max_instance_count
  gcf_timeout_seconds    = var.gcf_timeout_seconds
  gcs_location           = var.gcs_location
  project_id             = var.project_id
  csj_schedule           = var.csj_schedule
}

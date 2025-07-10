locals {
  code_bucket_prefix    = "billing_alerts_teams"
  functions_src_folder  = "src/gcf/" # local folder where function code resides
  functions_temp_folder = "/tmp/"     # local folder where function code resides
  functions_file_prefix = "gcf_code"
  zip_ext               = ".zip"
  function_url          = "https://${var.gcf_location}-${var.project_id}.cloudfunctions.net/billing_alerts_teams"
  message_payload       = jsonencode({ message = "Test message" })
}

data "google_project" "project" {}

# Create a fresh archive of the current function folder in a local temp folder
data "archive_file" "functions" {
  type        = "zip"
  output_path = "${local.functions_temp_folder}/${local.functions_file_prefix}_${timestamp()}.${local.zip_ext}" # create ZIP file with code in the local folder
  source_dir  = local.functions_src_folder
}

resource "google_storage_bucket" "code_bucket" {
  name                        = "${local.code_bucket_prefix}-${data.google_project.project.number}" # Every bucket name must be globally unique
  location                    = var.gcs_location                                                    # the same as where GCF resides
  uniform_bucket_level_access = true
  force_destroy               = true
}

# The archive in Cloud Stoage uses the md5 of the zip file
# This ensures the Function is redeployed only when the source is changed.
resource "google_storage_bucket_object" "gcf_code" {
  name = "${local.functions_file_prefix}_${data.archive_file.functions.output_md5}.${local.zip_ext}" # target name in GCS, will delete old items

  bucket = google_storage_bucket.code_bucket.name
  source = data.archive_file.functions.output_path

  depends_on = [google_storage_bucket.code_bucket, data.archive_file.functions]
}

# Create SA for GCF
resource "google_service_account" "gcf_sa" {
  account_id   = "bill-alerts-teams-gcf-sa"
  display_name = "Service Account - for cloud function and eventarc trigger for Billing Alerts Teams."
}

# Create SA for GCF for Build
resource "google_service_account" "gcf_build_sa" {
  account_id   = "bill-alerts-teams-gcf-build-sa"
  display_name = "Service Account - for cloud function build and eventarc trigger for Billing Alerts Teams."
}

# set all roles for GCF service account in one resource
resource "google_project_iam_member" "gcf_sa_roles" {
  for_each = toset([
    "roles/cloudfunctions.invoker",
    "roles/run.invoker",             # eventarc trigger
    "roles/eventarc.eventReceiver",  # receive events
    "roles/storage.objectAdmin",     # R/W objects into GCS
    "roles/logging.logWriter",       # logging
    "roles/artifactregistry.reader", # function deployment
    "roles/bigquery.dataEditor",     # BQ access
    "roles/bigquery.jobUser",        # BigQuery Job User - 403 POST https://bigquery.googleapis.com/bigquery/v2/projects/
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.gcf_sa.email}"
  project = data.google_project.project.id
}

# set all roles for GCF build service account in one resource
resource "google_project_iam_member" "gcf_build_sa_roles" {
  for_each = toset([
    "roles/cloudfunctions.invoker",
    "roles/run.invoker",             # eventarc trigger
    "roles/eventarc.eventReceiver",  # receive events
    "roles/storage.objectAdmin",     # R/W objects into GCS
    "roles/logging.logWriter",       # logging - 
    "roles/artifactregistry.reader", # function deployment
    "roles/artifactregistry.writer", # function deployment 
    "roles/bigquery.dataEditor",     # BQ access
    "roles/bigquery.jobUser",        # BigQuery Job User  
    # You must grant Storage Object Viewer permission to bill-alerts-teams-gcf-build-sa
    "roles/storage.objectViewer"     # Storage Object Viewer
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.gcf_build_sa.email}"
  project = data.google_project.project.id
}

resource "google_cloudfunctions_function" "billing_alerts_teams" {
  depends_on = [
    google_storage_bucket_object.gcf_code,
    google_project_iam_member.gcf_sa_roles,
    google_project_iam_member.gcf_build_sa_roles,
  ]

  name        = "billing_alerts_teams"
  description = "Vision API Image Annotate with GCS"
  runtime = "python311"
  region = var.gcf_location

  available_memory_mb = 256
  source_archive_bucket = google_storage_bucket.code_bucket.name
  source_archive_object = google_storage_bucket_object.gcf_code.name
  trigger_http = true
  entry_point = "billing_alerts_teams"
  service_account_email = google_service_account.gcf_sa.email
  build_service_account = "projects/${var.project_id}/serviceAccounts/${google_service_account.gcf_build_sa.email}"
}


### Cloud Scheduler

# service account for Cloud Scheduler
resource "google_service_account" "scheduler_sa" {
  account_id   = "bill-aler-teams-invoker"
  display_name = "Service Account for Cloud Scheduler for Billing Alerts Teams"
}

# service account permissions
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = var.gcf_location
  cloud_function = google_cloudfunctions_function.billing_alerts_teams.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# Cloud Scheduler Job which executes Cloud Run function which sends notification to Teams channel
resource "google_cloud_scheduler_job" "billing_alerts_job" {
  name        = "call-billing-alerts-teams"
  description = "Daily call to billing_alerts_teams function"
  schedule    = var.csj_schedule
  time_zone   = "America/Los_Angeles"
  region      = var.gcf_location

  http_target {
    http_method = "POST"
    uri         = local.function_url
    body        = base64encode(local.message_payload)

    oidc_token {
      service_account_email = google_service_account.scheduler_sa.email
    }

    headers = {
      "Content-Type" = "application/json"
    }
  }
}

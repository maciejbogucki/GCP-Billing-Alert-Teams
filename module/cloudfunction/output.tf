output "billing_alerts_teams_function_name" {
  description = "The name of the Cloud Function that annotates an image triggered by a GCS event."
  value       = google_cloudfunctions_function.billing_alerts_teams.name
}

output "code_bucket" {
  description = "The name of the bucket where the Cloud Function code is stored."
  value       = google_storage_bucket.code_bucket.name
}

output "source_code_filename" {
  description = "The name of the file containing the Cloud Function code."
  value       = google_storage_bucket_object.gcf_code.name
}

output "gcf_sa" {
  description = "Cloud Functions SA."
  value       = "GCF SA=${google_service_account.gcf_sa.email}"
}

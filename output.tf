output "billing_alerts_teams_function_name" {
  description = "The name of the cloud function that annotates an image triggered by a GCS event."
  value       = module.cloudfunction.billing_alerts_teams_function_name
}
output "source_code_url" {
  description = "The URL of the source code for Cloud Functions."
  value       = "gs://${module.cloudfunction.code_bucket}/${module.cloudfunction.source_code_filename}"
}

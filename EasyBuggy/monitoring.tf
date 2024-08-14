resource "google_monitoring_notification_channel" "webhook" {
  display_name = "Webhook to Cloud Function"
  type         = "webhook_tokenauth"

  labels = {
    "url" = "https://${var.region}-${var.project}.cloudfunctions.net/issue-creator-function"
  }
}

resource "google_storage_bucket" "easybuggy_monitoring_function_bucket" {
  name          = "easybubby_monitoring-functions-bucket"
  location      = "ASIA-NORTHEAST1"
  force_destroy = true
}

resource "google_storage_bucket_object" "function_source_object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.easybuggy_monitoring_function_bucket.name
  source = "function-source.zip"
}

resource "google_cloudfunctions_function" "function" {
  name        = "issue-creator-function"
  description = "Receive Webhook from Google Cloud Monitoring and create a GitHub issue"

  runtime    = "python39"
  source_archive_bucket = google_storage_bucket.easybuggy_monitoring_function_bucket.name
  source_archive_object = google_storage_bucket_object.function_source_object.name
  trigger_http          = true
  entry_point           = "create_github_issue"
  region                = var.region

  environment_variables = {
    "GITHUB_API_TOKEN" = var.github_api_token
    "GITHUB_REPO"      = var.github_repo
    "GITHUB_OWNER"     = var.github_owner
  }
}

resource "google_monitoring_alert_policy" "memory_usage_policy" {
  display_name = "High Memory Utilization Alert"
  combiner     = "OR"

  conditions {
    display_name  = "CPU usage over 80%"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
      duration        = "0s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8  

      aggregations {
        alignment_period  = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }


  enabled = true

  notification_channels = [google_monitoring_notification_channel.webhook.id]
}
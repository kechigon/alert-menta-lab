resource "google_pubsub_topic" "alerts_topic" {
  name = "alerts-topic"
}

resource "google_pubsub_subscription" "alerts_subscription" {
  name  = "alerts-subscription"
  topic = google_pubsub_topic.alerts_topic.name
}

resource "google_monitoring_notification_channel" "pubsub_channel" {
  display_name = "Pub/Sub to Cloud Function"
  type         = "pubsub"

  labels = {
    "topic" = google_pubsub_topic.alerts_topic.id
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

resource "google_cloudfunctions_function" "issue_creator_function" {
  name        = "issue-creator-function"
  description = "Receive Pub/Sub message from Google Cloud Monitoring and create a GitHub issue"

  runtime    = "python39"
  source_archive_bucket = google_storage_bucket.easybuggy_monitoring_function_bucket.name
  source_archive_object = google_storage_bucket_object.function_source_object.name
  entry_point           = "main"
  region                = var.region

  environment_variables = {
    "GITHUB_API_TOKEN" = var.github_api_token
    "GITHUB_REPO"      = var.github_repo
    "GITHUB_OWNER"     = var.github_owner
  }

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.alerts_topic.id
  }
}

#resource "google_monitoring_alert_policy" "cpu_usage_policy" {
#  display_name = "High CPU Utilization Alert"
#  combiner     = "OR"

#  conditions {
#    display_name  = "CPU usage over 80%"
#    condition_threshold {
#      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
#      duration        = "60s"
#      comparison      = "COMPARISON_GT"
#      threshold_value = 0.8  
#    }
#  }

#  enabled = true

#  notification_channels = [google_monitoring_notification_channel.pubsub_channel.id]
#}
variable "project" {
  default = "gen-ai-lab-391309"
}

variable "credential_file" {
  description = "Path to service account"
}

variable "region" {
  default = "asia-northeast1"
}

variable "zone" {
  default = "asia-northeast1-b"
}

variable "my_ip" {
  description = "My global ip"
}

variable "github_api_token" {
  description = "github api token"
}

variable "github_repo" {
  default = "alert-menta-lab"
}

variable "github_owner" {
  default = "kechigon"
}
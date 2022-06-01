packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "arm_client_id" {
  type    = string
  default = "${env("arm_client_id")}"
  validation {
    condition     = length(var.arm_client_id) > 0
    error_message = <<EOF
The arm_client_id environment variable must be set.
EOF
  }
}

variable "arm_client_secret" {
  type    = string
  default = "${env("arm_client_secret")}"
  validation {
    condition     = length(var.arm_client_secret) > 0
    error_message = <<EOF
The arm_client_secret environment variable must be set.
EOF
  }
}

variable "arm_subscription_id" {
  type    = string
  default = "${env("arm_subscription_id")}"
  validation {
    condition     = length(var.arm_subscription_id) > 0
    error_message = <<EOF
The arm_subscription_id environment variable must be set.
EOF
  }
}

variable "arm_tenant_id" {
  type    = string
  default = "${env("arm_tenant_id")}"
  validation {
    condition     = length(var.arm_tenant_id) > 0
    error_message = <<EOF
The arm_tenant_id environment variable must be set.
EOF
  }
}
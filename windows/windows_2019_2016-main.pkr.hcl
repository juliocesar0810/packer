packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp         = regex_replace(timestamp(), "[- TZ:]", "") 
  region            = "eu-west-1"
  vpc_id            = "vpc-0388c9895160ff515"
  subnet_id         = "subnet-020b942e8598e2622"
  security_group_id = "sg-0422205fb460447bc"
  instance_type     = "t2.micro"
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

source "azure-arm" "windows-2016" {
  azure_tags = {
    dept = "Engineering"
    task = "Image deployment"
  }

  client_id                         = "${var.arm_client_id}"
  client_secret                     = "${var.arm_client_secret}"
  subscription_id                   = "${var.arm_subscription_id}"
  tenant_id                         = "${var.arm_tenant_id}"
  communicator                      = "winrm"
  image_offer                       = "WindowsServer"
  image_publisher                   = "MicrosoftWindowsServer"
  image_sku                         = "2016-Datacenter"
  location                          = "East US"
  managed_image_name                = "packer-windows-demo-${local.timestamp}"
  managed_image_resource_group_name = "myPackerGroup"
  os_type                           = "Windows"
  vm_size                           = "Standard_D2_v2"
  winrm_insecure                    = true
  winrm_use_ssl                     = true
  winrm_username                    = "Packer_User"
  user_data_file                    = "./azure/bootstrap.ps1"
}

source "azure-arm" "windows-2019" {
  azure_tags = {
    dept = "Engineering"
    task = "Image deployment"
  }

  client_id                         = "${var.arm_client_id}"
  client_secret                     = "${var.arm_client_secret}"
  subscription_id                   = "${var.arm_subscription_id}"
  tenant_id                         = "${var.arm_tenant_id}"
  communicator                      = "winrm"
  image_offer                       = "WindowsServer"
  image_publisher                   = "MicrosoftWindowsServer"
  image_sku                         = "2019-Datacenter"
  location                          = "East US"
  managed_image_name                = "packer-windows-demo-${local.timestamp}"
  managed_image_resource_group_name = "myPackerGroup"
  os_type                           = "Windows"
  vm_size                           = "Standard_D2_v2"
  winrm_insecure                    = true
  winrm_use_ssl                     = true
  winrm_username                    = "Packer_User"
  user_data_file                    = "./azure/bootstrap.ps1"
}

source "amazon-ebs" "windows-2016" {
  ami_name          = "packer-windows-2016-${local.timestamp}"
  communicator      = "winrm"
  //winrm_username    = "Packer_User"
  winrm_username    = "Administrator"
  winrm_use_ssl     = true
  winrm_insecure    = true
  force_deregister = true
  force_delete_snapshot = true
  instance_type     = "${local.instance_type}"
  region            = "${local.region}"
  vpc_id            = "${local.vpc_id}"
  subnet_id         = "${local.subnet_id}"
  security_group_id = "${local.security_group_id}"
  associate_public_ip_address = true
  source_ami_filter {
    filters = {
      name                = "*Windows_Server-2016-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  user_data_file = "./aws/bootstrap.ps1"
}

source "amazon-ebs" "windows-2019" {
  ami_name          = "packer-windows-2019-${local.timestamp}"
  communicator      = "winrm"
  //winrm_username    = "Packer_User"
  winrm_username    = "Administrator"
  winrm_use_ssl     = true
  winrm_insecure    = true
  force_deregister = true
  force_delete_snapshot = true
  instance_type     = "${local.instance_type}"
  region            = "${local.region}"
  vpc_id            = "${local.vpc_id}"
  subnet_id         = "${local.subnet_id}"
  security_group_id = "${local.security_group_id}"
  associate_public_ip_address = true
  source_ami_filter {
    filters = {
      name                = "*Windows_Server-2019-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  user_data_file = "./aws/bootstrap.ps1"
}


build {
  name    = "builder"
  sources = ["source.azure-arm.windows-2016", "source.azure-arm.windows-2019", "source.amazon-ebs.windows-2016", "source.amazon-ebs.windows-2019"]

  provisioner "powershell" {
    script = "./ansible/remote_config.ps1"  
  }
  
  provisioner "powershell"{
    inline = ["winrm enumerate winrm/config/Listener"]
  }

  provisioner "ansible" {
    playbook_file = "./ansible/playbook.yml"
    extra_arguments = ["--extra-vars", "winrm_password=${build.Password} winrm_user=${build.User}"]
    use_proxy = false

  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    only = ["azure-arm.windows"]
    script = "./azure/sysprep.ps1"  
  }

  provisioner "powershell" {
    only = ["amazon-ebs.windows"]
    script = "./aws/reset.ps1"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }
}
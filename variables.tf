#variables for ansible machine
variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "ranjansir"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
  default     = "Ranjansir2025!"
}
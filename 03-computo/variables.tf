variable "subscription_id" {
  description = "ID de la suscripción Azure for Students"
  type        = string
}

variable "workload" {
  type    = string
  default = "lz-prod"
}

variable "app_service_sku" {
  description = "Plan de App Service Linux (B1 soporta integración con VNet)"
  type        = string
  default     = "B1"
}

variable "node_version" {
  type    = string
  default = "22-lts"
}

variable "vm_size" {
  description = "VM worker Linux B2ats_v2"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "vm_admin_username" {
  type    = string
  default = "azureworker"
}

variable "tags" {
  type = map(string)
  default = {
    proyecto = "landing-zone"
    entorno  = "prod"
    curso    = "aplicaciones-web-progresivas"
    gestion  = "terraform"
  }
}

variable "subscription_id" {
  description = "ID de la suscripción Azure for Students"
  type        = string
}

variable "location" {
  description = "Región de Azure (debe estar permitida por la política de la suscripción)"
  type        = string
  default     = "mexicocentral"
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos compartido por los tres proyectos"
  type        = string
  default     = "rg-lz-prod"
}

variable "vnet_name" {
  description = "Nombre de la red virtual"
  type        = string
  default     = "vnet-lz-prod"
}

variable "vnet_address_space" {
  description = "Espacio de direcciones de la VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  description = "Prefijos de cada subred del diagrama"
  type = object({
    app       = string
    db        = string
    vm        = string
    endpoints = string
    bastion   = string
  })
  default = {
    app       = "10.0.1.0/24"
    db        = "10.0.2.0/24"
    vm        = "10.0.3.0/24"
    endpoints = "10.0.4.0/24"
    bastion   = "10.0.5.0/24"
  }
}

variable "bastion_sku" {
  description = "SKU de Azure Bastion (Basic es suficiente para SSH desde el portal)"
  type        = string
  default     = "Basic"
}

variable "tags" {
  description = "Etiquetas comunes"
  type        = map(string)
  default = {
    proyecto = "landing-zone"
    entorno  = "prod"
    curso    = "aplicaciones-web-progresivas"
    gestion  = "terraform"
  }
}

variable "subscription_id" {
  description = "ID de la suscripción Azure for Students"
  type        = string
}

variable "workload" {
  description = "Identificador corto de la carga de trabajo para los nombres"
  type        = string
  default     = "lz-prod"
}

variable "postgres_version" {
  type    = string
  default = "16"
}

variable "postgres_sku" {
  description = "Servidor flexible Burstable B1ms"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  type    = number
  default = 32768
}

variable "database_name" {
  type    = string
  default = "appdb"
}

variable "pe_postgres_ip" {
  description = "IP privada del Private Endpoint de PostgreSQL (snet-db)"
  type        = string
  default     = "10.0.2.4"
}

variable "pe_blob_ip" {
  description = "IP privada del Private Endpoint de Blob (snet-endpoints)"
  type        = string
  default     = "10.0.4.4"
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

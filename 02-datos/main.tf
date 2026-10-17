############################################
# Lectura del estado del proyecto 01-red
############################################
data "terraform_remote_state" "red" {
  backend = "local"

  config = {
    path = "${path.module}/../01-red/terraform.tfstate"
  }
}

data "azurerm_client_config" "current" {}

locals {
  rg_name      = data.terraform_remote_state.red.outputs.resource_group_name
  location     = data.terraform_remote_state.red.outputs.location
  subnet_ids   = data.terraform_remote_state.red.outputs.subnet_ids
  dns_zone_ids = data.terraform_remote_state.red.outputs.private_dns_zone_ids
}

# Sufijo para nombres globalmente únicos (storage, servidor PostgreSQL, web app)
resource "random_string" "sufijo" {
  length  = 5
  upper   = false
  special = false
}

############################################
# PostgreSQL Flexible Server (acceso público deshabilitado)
############################################
resource "azurerm_postgresql_flexible_server" "pg" {
  name                = "psql-${var.workload}-${random_string.sufijo.result}"
  resource_group_name = local.rg_name
  location            = local.location
  version             = var.postgres_version
  sku_name            = var.postgres_sku
  storage_mb          = var.postgres_storage_mb

  backup_retention_days         = 7
  public_network_access_enabled = false

  # Solo autenticación Microsoft Entra (token de Managed Identity)
  authentication {
    active_directory_auth_enabled = true
    password_auth_enabled         = false
    tenant_id                     = data.azurerm_client_config.current.tenant_id
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.pg.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

############################################
# Storage Account Blob (acceso público deshabilitado)
############################################
resource "azurerm_storage_account" "blob" {
  name                = "stlzprod${random_string.sufijo.result}"
  resource_group_name = local.rg_name
  location            = local.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false

  tags = var.tags
}

############################################
# Private Endpoints + registro en Private DNS
############################################
resource "azurerm_private_endpoint" "postgres" {
  name                = "pep-postgres-${var.workload}"
  location            = local.location
  resource_group_name = local.rg_name
  subnet_id           = local.subnet_ids.db
  tags                = var.tags

  private_service_connection {
    name                           = "psc-postgres"
    private_connection_resource_id = azurerm_postgresql_flexible_server.pg.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "ipconfig-postgres"
    private_ip_address = var.pe_postgres_ip
    subresource_name   = "postgresqlServer"
  }

  private_dns_zone_group {
    name                 = "dnszg-postgres"
    private_dns_zone_ids = [local.dns_zone_ids.postgres]
  }
}

resource "azurerm_private_endpoint" "blob" {
  name                = "pep-blob-${var.workload}"
  location            = local.location
  resource_group_name = local.rg_name
  subnet_id           = local.subnet_ids.endpoints
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.blob.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "ipconfig-blob"
    private_ip_address = var.pe_blob_ip
    subresource_name   = "blob"
  }

  private_dns_zone_group {
    name                 = "dnszg-blob"
    private_dns_zone_ids = [local.dns_zone_ids.blob]
  }
}

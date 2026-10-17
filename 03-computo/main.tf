############################################
# Lectura de los proyectos 01-red y 02-datos
############################################
data "terraform_remote_state" "red" {
  backend = "local"

  config = {
    path = "${path.module}/../01-red/terraform.tfstate"
  }
}

data "terraform_remote_state" "datos" {
  backend = "local"

  config = {
    path = "${path.module}/../02-datos/terraform.tfstate"
  }
}

data "azurerm_client_config" "current" {}

locals {
  rg_name    = data.terraform_remote_state.red.outputs.resource_group_name
  location   = data.terraform_remote_state.red.outputs.location
  subnet_ids = data.terraform_remote_state.red.outputs.subnet_ids

  sufijo        = data.terraform_remote_state.datos.outputs.sufijo
  pg_name       = data.terraform_remote_state.datos.outputs.postgres_server_name
  pg_fqdn       = data.terraform_remote_state.datos.outputs.postgres_fqdn
  db_name       = data.terraform_remote_state.datos.outputs.database_name
  storage_id    = data.terraform_remote_state.datos.outputs.storage_account_id
  blob_endpoint = data.terraform_remote_state.datos.outputs.blob_endpoint
}

############################################
# App Service Linux B1 + VNet Integration (snet-app)
############################################
resource "azurerm_service_plan" "plan" {
  name                = "asp-${var.workload}"
  resource_group_name = local.rg_name
  location            = local.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags                = var.tags
}

resource "azurerm_linux_web_app" "web" {
  name                      = "app-${var.workload}-${local.sufijo}"
  resource_group_name       = local.rg_name
  location                  = local.location
  service_plan_id           = azurerm_service_plan.plan.id
  virtual_network_subnet_id = local.subnet_ids.app
  https_only                = true
  tags                      = var.tags

  # System-Assigned Managed Identity (MI en el diagrama)
  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on              = true
    minimum_tls_version    = "1.2"
    ftps_state             = "Disabled"
    vnet_route_all_enabled = true

    application_stack {
      node_version = var.node_version
    }
  }

  app_settings = {
    PGHOST        = local.pg_fqdn
    PGPORT        = "5432"
    PGDATABASE    = local.db_name
    PGUSER        = "app-${var.workload}-${local.sufijo}"
    PGSSLMODE     = "require"
    BLOB_ENDPOINT = local.blob_endpoint
  }
}

############################################
# VM Linux B2ats_v2 (worker) en snet-vm, sin IP pública
############################################
resource "tls_private_key" "vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_sensitive_file" "vm_pem" {
  content         = tls_private_key.vm.private_key_pem
  filename        = "${path.module}/vm-worker.pem"
  file_permission = "0600"
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-worker-${var.workload}"
  location            = local.location
  resource_group_name = local.rg_name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig-vm"
    subnet_id                     = local.subnet_ids.vm
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "worker" {
  name                            = "vm-worker-${var.workload}"
  computer_name                   = "vm-worker"
  resource_group_name             = local.rg_name
  location                        = local.location
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm.id]
  tags                            = var.tags

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm.public_key_openssh
  }

  # System-Assigned Managed Identity (MI en el diagrama)
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

############################################
# RBAC: Managed Identities -> Blob Storage (HTTPS 443, RBAC)
############################################
resource "azurerm_role_assignment" "web_blob" {
  scope                = local.storage_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.web.identity[0].principal_id
}

resource "azurerm_role_assignment" "vm_blob" {
  scope                = local.storage_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.worker.identity[0].principal_id
}

############################################
# Entra ID en PostgreSQL: las MI entran con token (puerto 5432, TLS)
############################################
resource "azurerm_postgresql_flexible_server_active_directory_administrator" "web" {
  server_name         = local.pg_name
  resource_group_name = local.rg_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = azurerm_linux_web_app.web.identity[0].principal_id
  principal_name      = azurerm_linux_web_app.web.name
  principal_type      = "ServicePrincipal"
}

resource "azurerm_postgresql_flexible_server_active_directory_administrator" "vm" {
  server_name         = local.pg_name
  resource_group_name = local.rg_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = azurerm_linux_virtual_machine.worker.identity[0].principal_id
  principal_name      = azurerm_linux_virtual_machine.worker.name
  principal_type      = "ServicePrincipal"

  # Se crean en secuencia para evitar conflictos de actualización del servidor
  depends_on = [azurerm_postgresql_flexible_server_active_directory_administrator.web]
}

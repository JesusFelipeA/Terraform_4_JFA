output "sufijo" {
  value = random_string.sufijo.result
}

output "postgres_server_name" {
  value = azurerm_postgresql_flexible_server.pg.name
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.pg.fqdn
}

output "database_name" {
  value = azurerm_postgresql_flexible_server_database.app.name
}

output "storage_account_id" {
  value = azurerm_storage_account.blob.id
}

output "storage_account_name" {
  value = azurerm_storage_account.blob.name
}

output "blob_endpoint" {
  value = azurerm_storage_account.blob.primary_blob_endpoint
}

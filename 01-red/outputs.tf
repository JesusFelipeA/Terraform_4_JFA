output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "location" {
  value = azurerm_resource_group.rg.location
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  value = {
    app       = azurerm_subnet.app.id
    db        = azurerm_subnet.db.id
    vm        = azurerm_subnet.vm.id
    endpoints = azurerm_subnet.endpoints.id
    bastion   = azurerm_subnet.bastion.id
  }
}

output "private_dns_zone_ids" {
  value = { for k, z in azurerm_private_dns_zone.zona : k => z.id }
}

output "bastion_name" {
  value = azurerm_bastion_host.bastion.name
}

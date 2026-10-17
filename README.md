# Landing Zone en Azure for Students con Terraform

Infraestructura del diagrama "Arquitectura de referencia - Azure for Students (Landing Zone + Well-Architected)", dividida en tres proyectos de Terraform que se aplican en orden.

| Proyecto | Recursos |
|---|---|
| `01-red` | Resource group, VNet `vnet-lz-prod` (10.0.0.0/16), 5 subredes, 5 NSG, 2 zonas Private DNS enlazadas a la VNet, Azure Bastion |
| `02-datos` | PostgreSQL Flexible Server B1ms (sin acceso público), Storage Account Blob Standard LRS (sin acceso público), Private Endpoints de ambos con registro en Private DNS |
| `03-computo` | App Service Linux B1 con VNet Integration, VM Linux B2ats_v2 (sin IP pública), Managed Identities, roles RBAC a Blob y administradores Entra en PostgreSQL |

Los proyectos se comunican con `terraform_remote_state` (backend local), por eso se aplican en orden y se destruyen en orden inverso.

## Requisitos

- Terraform >= 1.6, Azure CLI, sesión iniciada con `az login`
- Suscripción Azure for Students con permisos de Owner

## Despliegue (PowerShell)

```powershell
az login
az account show --query id -o tsv   # copiar el subscription_id

foreach ($p in "01-red","02-datos","03-computo") {
  cd $p
  Copy-Item terraform.tfvars.example terraform.tfvars   # editar subscription_id
  terraform init
  terraform validate
  terraform plan -out tfplan
  terraform apply tfplan
  cd ..
}
```

Haz las capturas (plan, apply, portal de Azure) después de cada proyecto.

## Destrucción (para no gastar crédito)

```powershell
cd 03-computo; terraform destroy; cd ..
cd 02-datos;   terraform destroy; cd ..
cd 01-red;     terraform destroy; cd ..
```

## Antes de aplicar

- Región: por defecto `mexicocentral`. Verifica que existan los SKU ahí:
  `az vm list-skus -l mexicocentral --size Standard_B2ats_v2 -o table` y
  `az postgres flexible-server list-skus -l mexicocentral -o table`.
  Si alguno falla, cambia `location` en `01-red/terraform.tfvars` (todo vive en la misma región por la VNet Integration).
- Cuota: si el plan B1 de App Service marca error de cuota, prueba otra región.
- Costo: Bastion, B1, B1ms y la VM consumen crédito por hora. Destruye al terminar las capturas.

## Llave SSH de la VM

`03-computo` genera `vm-worker.pem` (ignorado por Git). Úsala en el portal: VM `vm-worker-lz-prod` > Conectar > Bastion > Llave privada desde archivo (usuario `azureworker`).

## Plan de commits sugerido

1. `chore: estructura inicial del repositorio y .gitignore`
2. `feat(01-red): resource group, VNet y subredes`
3. `feat(01-red): NSG por subred y asociaciones`
4. `feat(01-red): zonas Private DNS y Azure Bastion`
5. `feat(02-datos): PostgreSQL Flexible Server y Storage Account sin acceso público`
6. `feat(02-datos): Private Endpoints con registro en Private DNS`
7. `feat(03-computo): App Service Linux con VNet Integration`
8. `feat(03-computo): VM worker, Managed Identities y roles RBAC`
9. `docs: README y evidencias`

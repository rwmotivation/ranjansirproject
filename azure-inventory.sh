#!/bin/bash

# Azure Resource Inventory Script
# This script lists all Azure resources in your subscription

echo "=================================================="
echo "         AZURE RESOURCE INVENTORY"
echo "=================================================="
echo ""

# Check if Azure CLI is installed and user is logged in
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Get current subscription info
echo "🔍 Current Subscription:"
az account show --query "{Name:name, ID:id, TenantId:tenantId}" -o table
echo ""

echo "📋 RESOURCE GROUPS:"
echo "==================="
az group list --query "[].{Name:name, Location:location, Status:properties.provisioningState}" -o table
echo ""

echo "💻 VIRTUAL MACHINES:"
echo "===================="
az vm list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, Size:hardwareProfile.vmSize, Status:powerState}" -o table 2>/dev/null || echo "No VMs found"
echo ""

echo "🌐 VIRTUAL NETWORKS:"
echo "===================="
az network vnet list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, AddressSpace:addressSpace[0]}" -o table
echo ""

echo "🔌 NETWORK INTERFACES:"
echo "======================"
az network nic list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, PrivateIP:ipConfigurations[0].privateIpAddress}" -o table
echo ""

echo "🌍 PUBLIC IP ADDRESSES:"
echo "======================="
az network public-ip list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, IP:ipAddress, Method:publicIpAllocationMethod}" -o table
echo ""

echo "🔒 NETWORK SECURITY GROUPS:"
echo "============================"
az network nsg list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o table
echo ""

echo "💾 STORAGE ACCOUNTS:"
echo "===================="
az storage account list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, Tier:sku.tier, Replication:sku.name}" -o table
echo ""

echo "🗄️ DISKS:"
echo "=========="
az disk list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, SizeGB:diskSizeGb, Type:sku.name}" -o table
echo ""

echo "🔑 KEY VAULTS:"
echo "=============="
az keyvault list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location}" -o table 2>/dev/null || echo "No Key Vaults found"
echo ""

echo "🗃️ DATABASES:"
echo "============="
echo "SQL Servers:"
az sql server list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, Version:version}" -o table 2>/dev/null || echo "No SQL Servers found"
echo ""

echo "📊 COSMOS DB:"
az cosmosdb list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, Kind:kind}" -o table 2>/dev/null || echo "No Cosmos DB accounts found"
echo ""

echo "⚙️ APP SERVICES:"
echo "================"
az webapp list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, State:state, DefaultHostName:defaultHostName}" -o table 2>/dev/null || echo "No App Services found"
echo ""

echo "🚀 CONTAINER SERVICES:"
echo "======================"
echo "Container Registries:"
az acr list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, LoginServer:loginServer}" -o table 2>/dev/null || echo "No Container Registries found"
echo ""

echo "AKS Clusters:"
az aks list --query "[].{Name:name, ResourceGroup:resourceGroup, Location:location, Status:powerState.code, Version:kubernetesVersion}" -o table 2>/dev/null || echo "No AKS clusters found"
echo ""

echo "📈 SUMMARY BY RESOURCE GROUP:"
echo "=============================="
for rg in $(az group list --query "[].name" -o tsv); do
    count=$(az resource list --resource-group "$rg" --query "length(@)")
    echo "$rg: $count resources"
done
echo ""

echo "💰 COST SUMMARY (if available):"
echo "================================"
# Note: This requires cost management permissions
az consumption usage list --top 5 --query "[].{Date:usageStart, Service:instanceName, Cost:pretaxCost}" -o table 2>/dev/null || echo "Cost data not available (requires billing permissions)"
echo ""

echo "=================================================="
echo "         INVENTORY COMPLETE"
echo "=================================================="
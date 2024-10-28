provider "azurerm" {
  features {}
  client_id       = "dd2f42db-9fe4-4d32-9593-cdf7e597b07a"
  client_secret   = "1mf8Q~N2x1sM_TiFDKCABEGVTgzlPVgCnyZFQb8b"
  subscription_id = "cd06d49d-6ae2-4d2b-82e4-50b2b98f55dd"
  tenant_id       = "ed27b597-cea0-4942-8c6f-40e6a78bf47d"
}

resource "azurerm_resource_group" "dev_rg" {
  name     = "myResourceGroup"
  location = "East US"
}

resource "azurerm_virtual_network" "dev_vnet" {
  name                = "dev-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.dev_rg.location
  resource_group_name = azurerm_resource_group.dev_rg.name
}

resource "azurerm_subnet" "dev_subnet" {
  name                 = "dev-subnet"
  resource_group_name  = azurerm_resource_group.dev_rg.name
  virtual_network_name = azurerm_virtual_network.dev_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "dev_nsg" {
  name                = "dev-nsg"
  location            = azurerm_resource_group.dev_rg.location
  resource_group_name = azurerm_resource_group.dev_rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP-Outbound"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-NodePort-Range-Inbound"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-NodePort-Range-Outbound"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "dev_public_ip" {
  name                = "dev-public-ip"
  location            = azurerm_resource_group.dev_rg.location
  resource_group_name = azurerm_resource_group.dev_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "dev_nic" {
  name                = "dev-nic"
  location            = azurerm_resource_group.dev_rg.location
  resource_group_name = azurerm_resource_group.dev_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dev_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.dev_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "dev_nic_nsg" {
  network_interface_id      = azurerm_network_interface.dev_nic.id
  network_security_group_id = azurerm_network_security_group.dev_nsg.id
}

resource "azurerm_linux_virtual_machine" "dev_vm" {
  name                = "dev-vm"
  resource_group_name = azurerm_resource_group.dev_rg.name
  location            = azurerm_resource_group.dev_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("D:/Terraform/id_rsa.pub")
  }

  network_interface_ids = [azurerm_network_interface.dev_nic.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
      #!/bin/bash
      set -ex

      # Install Docker
      sudo apt-get update -y
      sudo apt-get install -y docker.io
      sudo systemctl start docker
      sudo systemctl enable docker
      sudo usermod -aG docker azureuser

      # Install kind
      curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.0/kind-linux-amd64
      chmod +x ./kind
      sudo mv ./kind /usr/local/bin/kind

      # Install kubectl
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      chmod +x ./kubectl
      sudo mv ./kubectl /usr/local/bin/kubectl

      # Create kind-config.yaml in the home directory
      cat <<EOT > /home/azureuser/kind-config.yaml
      kind: Cluster
      apiVersion: kind.x-k8s.io/v1alpha4
      nodes:
      - role: control-plane
        extraPortMappings:
        - containerPort: 6443
          hostPort: 6443
          listenAddress: "127.0.0.1"
          protocol: TCP
      EOT

      # Create kind cluster using the configuration file
      sleep 30  # Wait for Docker to be fully up
      kind create cluster --config /home/azureuser/kind-config.yaml || { echo 'Cluster creation failed. Retrying...'; kind delete cluster; sleep 10; kind create cluster --config /home/azureuser/kind-config.yaml; }
  EOF
  )
}

resource "azurerm_container_registry" "acr" {
  name                = "shreyas3799"
  resource_group_name = azurerm_resource_group.dev_rg.name
  location            = azurerm_resource_group.dev_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

output "vm_public_ip" {
  value = azurerm_public_ip.dev_public_ip.ip_address
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

../PowerShell
# Declare variables
  $VNetName  = "VNet1"
  $RG = "TestRG1"
  $Location = "East US"
  $FESubName = "FrontEnd"
  $BESubName = "BackEnd"
  $GWSubName = "GatewaySubnet"
  $VNetPrefix1 = "10.1.0.0/16"
  $FESubPrefix = "10.1.0.0/24"
  $BESubPrefix = "10.1.1.0/24"
  $GWSubPrefix = "10.1.255.0/27"
  $VPNClientAddressPool = "192.168.0.0/24"
  $GWName = "VNet1GW"
  $GWIPName = "VNet1GWIP"
  $GWIPconfName = "gwipconf"
  $LNGName = "Site1"
# Create a resource group
New-AzResourceGroup -Name $RG -Location $Location
# Create a virtual network
$virtualNetwork = New-AzVirtualNetwork `
  -ResourceGroupName $RG `
  -Location $Location `
  -Name $VNetName `
  -AddressPrefix $VNetPrefix1
# Create a subnet configuration
$subnetConfig = Add-AzVirtualNetworkSubnetConfig `
  -Name $FESubName `
  -AddressPrefix $FESubPrefix `
  -VirtualNetwork $virtualNetwork
# Set the subnet configuration for the virtual network
$virtualNetwork | Set-AzVirtualNetwork
# Add a gateway subnet
$vnet = Get-AzVirtualNetwork -ResourceGroupName $RG -Name $VNetName
Add-AzVirtualNetworkSubnetConfig -Name $GWSubName -AddressPrefix $GWSubPrefix -VirtualNetwork $vnet
# Set the subnet configuration for the virtual network
$vnet | Set-AzVirtualNetwork
# Request a public IP address
$gwpip= New-AzPublicIpAddress -Name $GWIPName -ResourceGroupName $RG -Location $Location `
 -AllocationMethod Dynamic
# Create the gateway IP address configuration
$vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $RG
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $GWSubName -VirtualNetwork $vnet
$gwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name $GWIPconfName -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id
# Create the VPN gateway
New-AzVirtualNetworkGateway -Name $GWName -ResourceGroupName $RG `
 -Location $Location -IpConfigurations $gwipconfig -GatewayType Vpn `
 -VpnType RouteBased -GatewaySku VpnGw1
# Create the local network gateway
New-AzLocalNetworkGateway -Name $LNGName -ResourceGroupName $RG `
 -Location $Location -GatewayIpAddress '23.99.221.164' -AddressPrefix @('10.101.0.0/24','10.101.1.0/24')
# Configure your on-premises VPN device
# Create the VPN connection
$gateway1 = Get-AzVirtualNetworkGateway -Name $GWName -ResourceGroupName $RG
$local = Get-AzLocalNetworkGateway -Name $LNGName -ResourceGroupName $RG
New-AzVirtualNetworkGatewayConnection -Name VNet1toSite1 -ResourceGroupName $RG `
-Location $Location -VirtualNetworkGateway1 $gateway1 -LocalNetworkGateway2 $local `
-ConnectionType IPsec -ConnectionProtocol IKEv2 -RoutingWeight 10 -SharedKey 'abc123'
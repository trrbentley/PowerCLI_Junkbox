# Get HBA Info
# By Tim Bentley
# This small script will get the HBA info for a cluster

#get creds
$cred = Get-Credential

#ask for vcenter
$vCenterDefault = "XXXXX" #put a default vcenter here...

$vCenter = (Read-Host "Enter a vCenter name [$vCenterDefault]").Trim()

If ($vCenter -eq "") {
    $vCenter = $vCenterDefault
}

#connect to vcenter
Connect-VIServer -Server $vCenter -Credential $cred

#ask for cluster name
$clustername = Read-Host "Enter a cluster name"
$dscluster = get-cluster $clustername | get-datastore | get-datastorecluster

#generate report
Write-Host
Write-Host
Write-Host "HBA info for $clustername"
Write-Host
Write-Host "--------------------------------------------------------"
Write-Host
Write-Host "Cluster Name:"$dscluster.Name
Get-Cluster $clustername | Get-VMhost | Get-VMHostHBA -Type FibreChannel | Select VMHost,Device,@{N="WWPN";E={"{0:X}" -f $_.PortWorldWideName}},@{N="WWNN";E={"{0:X}" -f $_.NodeWorldWideName}} | Sort VMhost,Device | Format-Table

Disconnect-VIServer $vCenter -Force -Confirm:$false
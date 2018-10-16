#get all VMs on a Host
#by Tim Bentley

#get Creds
$cred = Get-Credential

#connect to host of choice

$hostname = Read-host "Enter a vsphere host"

Connect-VIServer -Server $hostname -Credential $cred -WarningAction SilentlyContinue

#get all VMs that are powered ON

$hostname
Get-vm | Where-Object {$_.PowerState -eq "PoweredOn"} | Format-Table

Disconnect-VIServer -Server $hostname
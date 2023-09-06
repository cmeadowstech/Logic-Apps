<#
.SYNOPSIS
    Use to add allowed IP addresses to Consumption Logic Apps
.DESCRIPTION
    This is only for adding IPs allowed to trigger the Logic App, it does not impact the separate allowed list for content (run history)

    Please use at your own risk.
.PARAMETER laName
    The name of your Logic App
.PARAMETER rgGroup
    The name of the Resource Group
.PARAMETER ipAddresses
    List of IP addresses you want to add to the allowed list (for triggers)
.NOTES
    Author: Cody Meadows
    Date: September 6th, 2023
#>

$laName = ""
$rgGroup = ""
$ipAddresses = ("1.1.1.1/24","2.2.2.2/24","3.3.3.3/24")

$la = Get-AzResource -ResourceGroupName $rgGroup -ResourceType Microsoft.Logic/workflows -ResourceName $laName 
$newIPs = @()

foreach ($ip in $ipAddresses) {
    if ($la.Properties.accessControl.Triggers.allowedCallerIpAddresses.addressRange.Contains($ip)) {
        Write-Host "IP $($ip) is already allowed" -ForegroundColor Cyan
    } else {
        $la.Properties.accessControl.Triggers.allowedCallerIpAddresses += @{"addressRange"= $ip}
        $newIPs += $ip
    }
}

$la | Set-AzResource

Write-Host "The following IP addresses have been successfully added:" ($newIPs -join ", ") -ForegroundColor Green


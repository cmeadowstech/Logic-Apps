<#
.SYNOPSIS
    Used to generate an ARM Template for a specific API Connection. Designed for usage with
    Standard Logic Apps, but the resulting ARM template can be easily modified for Consumption.
.DESCRIPTION
    When using, make sure you have api-template-base.json in the same directory. When the script
    completes, it will export a {connector}_arm.json to the working directory.

    The ARM template includes an access policy for the API Connection as well as an output for
    the connectionRuntimeUrl, which will need to be added to connections.json.
.PARAMETER subscriptionId
    Subscription ID you want to deploy this connector to
.PARAMETER location
    The location you want to deploy this connector to
.PARAMETER connector
    The connector you are wanting to deploy. If you don't know the shorthand for the connector,
    it's usually listed in the connector reference for that connector in our documentation.

    Example: https://learn.microsoft.com/en-us/connectors/office365/

    The Office 365 Outlook connector shorthand would be office365
.EXAMPLE
    C:\PS> 
    <Description of example>
.NOTES
    Author: Cody Meadows
    Date:   January 09, 2023
#>

Param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string[]]$subscriptionId,
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string[]]$location,
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string[]]$connector
)

$token = (Get-AzAccessToken).Token

$header = @{
    "authorization" = "Bearer $token"
}

# Make API request

try {
    $request = Invoke-RestMethod "https://management.azure.com/subscriptions/$($subscriptionId)/providers/Microsoft.Web/locations/$($location)/managedApis/$($connector)?api-version=2018-07-01-preview" -Headers $header
}
catch {
    Write-Host ($_.errordetails.message | ConvertFrom-Json).error.message -ForegroundColor Red
    exit
}

# Choose which authentication method to use

if ($request.properties.connectionParameterSets) {
    $authenticationMethods = $request.properties.connectionParameterSets.values | Select-Object `
        name,
        @{n="Display Name"; e={$_.uiDefinition.displayName}},
        @{n="Description"; e={$_.uiDefinition.description}}
} else {
    $authenticationMethods = $request.properties.connectionParameters.psObject.Properties | Select-Object `
        Name,
        @{n="Display Name"; e={$_.value.uiDefinition.displayName}},
        @{n="Description"; e={$_.value.uiDefinition.description}}
}

$GridArguments = @{
    OutputMode = 'Single'
    Title      = 'Please select an authentication method and click OK'
}

Write-Host "Please select an authentication method from the pop-up and click OK..." -ForegroundColor Cyan
Start-Sleep -Seconds 1

$authenticationMethod = $authenticationMethods | Out-GridView @GridArguments | foreach {
    $_.name
}

if ($request.properties.connectionParameterSets) {
    $connectionParameterSets = ($request.properties.connectionParameterSets.values | where name -eq $authenticationMethod).parameters
} else {
    $connectionParameterSets = $request.properties.connectionParameters
}
# Write to ARM template

if ($authenticationMethod -ne $null) {
    $template = Get-Content api-template-base.json | ConvertFrom-Json
} else {
    Write-Host "Please run again and select authentication method." -ForegroundColor Red
    exit
}

$parametersObject = @{}
$connectionParameterSets.PSObject.Properties | foreach {
    $parametersObject[$_.Name] = "$($_.value.uiDefinition.description) | Required: $($_.value.uiDefinition.constraints.required)"
}

if ($parametersObject['token']) {
    $template.resources[0].properties.parameterValues = @{}                                # OAuth typically doesn't take parameterValues
} else {
    $template.resources[0].properties.parameterValues = $parametersObject
}

$template.parameters.connector_type.defaultValue = $connector
$template.resources[0].properties.api.id = "[concat('subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', resourceGroup().location, '/managedApis/$($connector)')]"

# Export template to working directory

$template | ConvertTo-Json -Depth 6 | Out-File "$($connector)_arm.json"

Write-Host "The ARM template has been exported to the working directory as $($connector)_arm.json" -ForegroundColor Green


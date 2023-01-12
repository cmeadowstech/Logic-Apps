<#
.SYNOPSIS
    Used to reauthenticate the 7 day access tokens used by Visual Studio Code.
.DESCRIPTION
    Upon running the script, you will be asked to choose a Subscription to make sure the script is run
    in the correct environment.

    Using an established connections.json file, this will go throuh established connections and create new
    7 day access tokens for them. It will then export the new values to a new.local.settings.json
    from which you can copy and paste into your working local.settings.json

    Optionally, you can set a Key Vault to store these access tokens in and it will give you
    Key Vault references to use in your local.settings.json
.PARAMETER connectionsJson
    The path to your connections.json file
.PARAMETER keyVault
    Optional. The name of your Key Vault in Azure
.EXAMPLE
    C:\PS> 
    If you just want to export new access tokens, call the script without the keyVault parameter

    .\reauth-vscode-tokens.ps1 -connectionsJson 'connections.json'

    If you do want to store these in Key Vault, add the -keyVault parameter

    .\reauth-vscode-tokens.ps1 -connectionsJson 'connections.json' -keyVault 'keyvault'
.NOTES
    Author: Cody Meadows
    Date:   January 12, 2023
#>

Param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)][string[]]$connectionsJson,
    [Parameter(Mandatory=$false)][string]$keyVault
)

# Set Subscription

$GridArguments = @{
    OutputMode = 'Single'
    Title      = 'Please select a Subscription'
}

$subscriptionId = Get-AzSubscription | Out-GridView @GridArguments

Set-AzContext -SubscriptionId $subscriptionId 

# Gets a new Access Token for a given API Connection

function Get-Token {
    param(
        $resourceId,
        $accessToken
    )
    
    $url = "https://management.azure.com$($resourceId)/listConnectionKeys?api-version=2018-07-01-preview"
    
    $header = @{
        "authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    $body = @{"validityTimeSpan" = "7"}
    $json = $body | ConvertTo-Json

    Invoke-RestMethod -Uri $url -Method "Post" -Headers $header -Body $json
}

# If using Key Vault

function UploadTo-KeyVault {
    param(
        $keyVault,
        $connectionsJson
    )

    $accessToken = (Get-AzAccessToken).Token

    $connectionsJson = Get-Content $connectionsJson | ConvertFrom-Json                                                                                                  # Fetch connections.json

    $localSettings = @{}

    foreach ($connection in $connectionsJson.managedApiConnections.psobject.properties) {
        $resourceId = $connection.value.connection.id
        $token = (Get-Token -resourceId $resourceId -accessToken $accessToken).connectionKey | ConvertTo-SecureString -AsPlainText -Force
        $secretName = ("$($connection.name)-connectionKey").Replace('_','-')

        Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue $token

        $localSettings["$($connection.name)-connectionKey"] = "@Microsoft.KeyVault(SecretUri=https://$($KeyVault).vault.azure.net/secrets/$($secretName)/)"
    }   

    $localSettings | ConvertTo-Json | Out-File new.local.settings.json
}

# If not using Key Vault

function Export-Tokens {
    param(
        $connectionsJson
    )

    $accessToken = (Get-AzAccessToken).Token

    $connectionsJson = Get-Content $connectionsJson | ConvertFrom-Json                                                                                                  # Fetch connections.json

    $localSettings = @{}

    foreach ($connection in $connectionsJson.managedApiConnections.psobject.properties) {
        $resourceId = $connection.value.connection.id
        $token = (Get-Token -resourceId $resourceId -accessToken $accessToken).connectionKey
        $localSettings["$($connection.name)-connectionKey"] = "$($token)"
    }

    $localSettings | ConvertTo-Json | Out-File new.local.settings.json
}

# Logic to determine if $keyVault was set via pipeline or not

if ($PSBoundParameters.ContainsKey('keyVault') -eq $true) {
    UploadTo-KeyVault -connectionsJson $connectionsJson -keyVault $keyVault
} else {
    Export-Tokens -connectionsJson $connectionsJson
}
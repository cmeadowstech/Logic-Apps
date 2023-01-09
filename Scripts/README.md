# Scripts

## create-api-arm-template.ps1

Make sure you download api-template-base.json alongside this script, as it is used as a base to create the ARM template.

```powershell
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
    .\create-api-arm-template.ps1 -subscriptionId "0620cb41-76ea-45fb-a437-f94f581c1e1a" -location "eastus" -connector "office365"
.NOTES
    Author: Cody Meadows
    Date:   January 09, 2023
#>
```

## cancel-logic-app-runs.ps1

This will cancel any queued runs in parallel. 

- < 3 minutes to find 2890 stalled runs
- 2.5 minutes to cancel 2890 runs as a result of concurrency

Not tested with more than 2890 runs, please proceed with caution. Too many runs could potentially cause PowerShell to freeze.
function Close-ServiceRequest {
    param (
        [string]$UserAccount,
        [string]$Record
    )

    #Define URL to close ticket
    $resourcePath = "HEAT/api/odata/businessobject/ServiceReqs"
    $urlPut = "${baseUrl}${resourcePath}('$record')"
    # Ivanti call to close SR
    $bodyPut = @{
        "Status" = "Closed"
        "Owner"  = "Nick Fairbairn"
    } | ConvertTo-Json

   Invoke-RestMethod -Method Put -Uri $urlPut -Headers $headers -Body $bodyPut
}

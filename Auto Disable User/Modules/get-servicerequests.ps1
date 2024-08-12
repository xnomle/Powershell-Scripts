function Get-ServiceRequests {

    # Call Ivanti to GET Incidents
    # SR Get Params
    $params = "`$filter=(Status%20eq%20%27Submitted%27%20and%20OwnerTeam%20eq%20%27IT%27)&`$select=RecId,subject,Status,Email"
    $resourcePath = "HEAT/api/odata/businessobject/ServiceReqs"
    $url = "${baseUrl}${resourcePath}?${params}"

    $response = Invoke-RestMethod -Uri $url -Headers $headers
    $json = ConvertTo-Json $response
    #Write-Host $json

    $serviceRequests = $response.value | Where-Object { $_.Subject -eq "Disable Customer Operator - AMS Pulse" } | ForEach-Object {
        [PSCustomObject]@{
            RecId = $_.RecId
            Email = $_.Email
        }
    } 

     $serviceRequests = $serviceRequests | Select-Object -Unique # Remove duplicates from the variable 

    Write-Output $serviceRequests
    return $serviceRequests
}

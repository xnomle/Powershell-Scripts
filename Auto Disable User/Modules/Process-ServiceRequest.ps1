
function Process-ServiceRequest {
    param (
        [string]$Record,
        [string]$RaiserEmail
    )

    $params = "`$filter=(ParentLink_RecID%20eq%20%27$Record%27)&`$select=ParameterName,ParameterValue"
    $resourcePath = "HEAT/api/odata/businessobject/ServiceReqParams"
    $url = "${baseUrl}${resourcePath}?${params}"
    # Write-Output $url

    # Execute the REST API call
    $response = Invoke-RestMethod -Uri $url -Headers $headers

    # Check if the response contains an EndDate parameter with today's date
    $todaysDate = Get-Date -Format "yyyy-MM-dd"
    $endDateParameter = $response.value | Where-Object { $_.ParameterName -eq "EndDate" }
    $userAccount = $response.value | Where-Object { $_.ParameterName -eq "text_username" } | Select-Object -ExpandProperty ParameterValue

    if ($endDateParameter) {
        try {
            $endDate = [DateTime]::ParseExact($endDateParameter.ParameterValue, "yyyy-MM-ddTHH:mm:ss.fffffffZ", $null)
            if ($endDate.ToString("yyyy-MM-dd") -eq $todaysDate) {
                # Check if the user's OU matches the raiser's OU
                $ouMatch = Check-UserOUs -UserAccount $userAccount -RaiserEmail $RaiserEmail
                if ($ouMatch) {
                    Disable-UserAccount -UserAccount $userAccount -Record $Record
                }
            }
            else {
                # Log when the user account is found but the end date doesn't match today's date
                $logEntry = "User account $userAccount found, but end date $($endDate.ToString('yyyy-MM-dd')) does not match today's date ($todaysDate)"
                Write-Log -LogEntry $logEntry
            }
        }
        catch {
            # Log the error when parsing the end date
            $errorMessage = "Error parsing end date value '$($endDateParameter.ParameterValue)' for user $userAccount. Error: $($_.Exception.Message)"
            Write-Log -LogEntry $errorMessage
        }
    }
    else {
        # Log when no end date parameter is found
        $logEntry = "No end date parameter found for record $Record"
        Write-Log -LogEntry $logEntry
    }
}

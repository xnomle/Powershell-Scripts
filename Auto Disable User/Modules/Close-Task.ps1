function Close-Task {
    param (
        [string]$UserAccount,
        [string]$Record
    )

    # Define API Query for finding the task
    $params = "`$filter=(status%20eq%20%27logged%27%20and%20Parentlink_recid%20eq%20%27$Record%27)&`$select=RecId,Parentlink_RecID"
    $resourcePath = "HEAT/api/odata/businessobject/task__assignments"
    $url = "${baseUrl}${resourcePath}?${params}"

    # Call Ivanti to GET Tasks
    Write-Output "Calling Ivanti to GET Requests for user $UserAccount"

    try {
        # Ivanti Call to find Task
        $response = Invoke-RestMethod -Uri $url -Headers $headers
        $jsonResponse = ConvertTo-Json $response
        Write-Output "Response: $jsonResponse"

        $TaskRecID = ($response.value | Where-Object { $_.ParentLink_RecID -eq "$Record" } | Select-Object -ExpandProperty RecId)

        if ($TaskRecID) {
            # Ivanti call to close task
            $bodyPut = @{
                "Status" = "Completed"
                "Owner"  = "Nick Fairbairn"
            } | ConvertTo-Json

            $urlPut = "${baseUrl}${resourcePath}('$TaskRecID')"

            Write-Output "Updating Task: $TaskRecID"
            Write-Output "Request Body: $bodyPut"

            $response = Invoke-RestMethod -Method Put -Uri $urlPut -Headers $headers -Body $bodyPut
            $jsonResponse = ConvertTo-Json $response

            Write-Output "Task $TaskRecID has been closed for disabled user $UserAccount."

            Close-ServiceRequest -UserAccount $UserAccount -Record $Record
        }
        else {
            Write-Output "Task RecID not found. Cannot close the task for user $UserAccount."
        }
    }
    catch {
        Write-Error "An error occurred while processing the request: $($_.Exception.Message)"
    }
}

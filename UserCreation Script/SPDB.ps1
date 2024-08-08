function Put-Password {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Ticket,

        [Parameter(Mandatory=$true)]
        [string]$Username,
    
        [Parameter(Mandatory=$true)]
        [string]$description,

        [Parameter(Mandatory=$true)]
        [string]$Password
    )

    if ($env:USERDNSDOMAIN -eq "AMS.NZ") {
        $uri = "https://spdb.ams.nz:9119/api/passwords"
        $ListID = "1445"    
    }
    else {
        $uri = "https://spdb.npr.ams.nz:9119/api/passwords"
        $ListID = "1444" }
     
    
    
    $apikey = "2343eda6c8f75b9b58a637cedf943243"
 
    # JSON data for the object
    $jsonData = @{
        PasswordListID = $ListID
        Title = $Ticket
        UserName = $Username
        password = $Password
    } | ConvertTo-Json

    $PasswordstateUrl = $uri

    try {
        $result = Invoke-RestMethod -Method Post -Uri $PasswordstateUrl -ContentType "application/json" -Body $jsonData -Header @{ "APIKey" = $apikey }
    
        if ($result.PasswordID) {
            Write-Host "Password Written to SPDB" -ForegroundColor Green
        }
        else {
            Write-Host "Password Not Written to SPDB: No PasswordID returned" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error writing password to SPDB: $($_.Exception.Message)" -ForegroundColor Red
    }
}   
Import-Module ActiveDirectory
Import-Module ".\modules\Check-UserOus.ps1"
Import-Module ".\modules\Close-ServiceRequest.ps1"
Import-Module ".\modules\Close-Task.ps1"
Import-Module ".\modules\Disable-UserAccount.ps1"
Import-Module ".\modules\get-servicerequests.ps1"
Import-Module ".\modules\Process-ServiceRequest.ps1"
Import-Module ".\modules\Write-Log.ps1"

# Directly defined parameters within the script
$baseUrl = "https://ism.ams.nz/"
$authorization = "rest_api_key=E0248BCF00D1423892350506B1B1F458"


#Variables
$logFilePath = "D:\Scripts\DisableUsers\DisableUserAccounts.log"
$headers = @{
    "Authorization" = $authorization
}

# Main execution
$serviceRequests = Get-ServiceRequests

if ($serviceRequests) {
    $serviceRequests | ForEach-Object {
        $record = $_.RecId
        $raiserEmail = $_.Email
        Process-ServiceRequest -Record $record -RaiserEmail $raiserEmail
    }
}
else {
    Write-Output "No service requests found for disabling user accounts."
}
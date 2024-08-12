# Import the SMS sending module
Import-Module "\\File\CommonRepository\ManagementScripts\User_Management_Scripts\Create RDS User Gui - Protego\sendSMS.ps1" | Out-Null

function Get-PasswordStateEntries {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Title
    )

    if (-not $Title) {
        $Title = Read-Host "Please enter Service Request number"
    }

    $encodedTitle = [uri]::EscapeDataString($Title)

    if ($env:USERDNSDOMAIN -eq "AMS.NZ") {
        $uri = "https://spdb.ams.nz:9119/api/passwords/1445/?Title=$encodedTitle&QueryAll&PreventAuditing=true"
    } else {
        $uri = "https://spdb.npr.ams.nz:9119/api/passwords/1444/?Title=$encodedTitle&QueryAll&PreventAuditing=true"
    }

    $apikey = "NotTheApiKey"

    try {
        $result = Invoke-RestMethod -Method Get -Uri $uri -Headers @{ "APIKey" = $apikey }
        return $result | Where-Object { $_.Title -eq $Title }
    } catch {
        Write-Error "Failed to query PasswordState: $_"
        return $null
    }
}

# Usage
$passwords = Get-PasswordStateEntries

if ($passwords) {
    Write-Host "`nFound $($passwords.Count) password entries for Service Request: " -NoNewline
    Write-Host "$($passwords[0].Title)" -ForegroundColor Cyan -BackgroundColor DarkBlue
    Write-Host ""

    $passwords | ForEach-Object {
        Write-Host "----------------------------------------" -ForegroundColor Yellow
        Write-Host "Username    : " -NoNewline -ForegroundColor Green
        Write-Host "$($_.UserName)" -ForegroundColor White
        Write-Host "Password    : " -NoNewline -ForegroundColor Green
        Write-Host "$($_.Password)" -ForegroundColor White
        if ($_.Description) {
            Write-Host "Description : " -NoNewline -ForegroundColor Green
            Write-Host "$($_.Description)" -ForegroundColor White
        }
        Write-Host "----------------------------------------" -ForegroundColor Yellow
        Write-Host ""

        $sendMessage = Read-Host "Would you like to send this password? (Y/N)"
        if ($sendMessage -eq 'Y' -or $sendMessage -eq 'y') {
            $tck = $_.Title
            $pw = $_.Password
            $num = Read-Host "Enter the phone number to send the password to - Please append +64 and drop the leading 0"
            Write-Host "Sending message..." -ForegroundColor Yellow
            Send-Message -msg "$tck - $pw" -num "$num"
        }
        
        Write-Host ""
    }
} else {
    Write-Host "No passwords found for the specified Service Request number" -ForegroundColor Red
}

# Keep the PowerShell prompt open
Write-Host "Press Enter to close this window..." -ForegroundColor Yellow
Read-Host
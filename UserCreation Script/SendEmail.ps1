function Send-Email {
    param(
        [Parameter(Mandatory=$true)]
        [string]$to,

        [Parameter(Mandatory=$true)]
        [string]$subject,

        [Parameter(Mandatory=$true)]
        [string]$body,

        [bool]$isHtml = $false 
    )

    # Ensure domain is trimmed and in a consistent case for comparison
    $domain = $env:USERDNSDOMAIN.Trim().ToUpper()

    if ($domain -eq "NPR.AMS.NZ") {
        Write-Host "Matched NPR.AMS.NZ"
        $smtpServer = "smtp.npr.ams.nz"
        $from = "noreply@npr.ams.nz"
    } elseif ($domain -eq "AMS.NZ") {
        Write-Host "Matched AMS.NZ"
        $smtpServer = "smtp.ams.nz"
        $from = "noreply@ams.nz"
    } else {
        Write-Error "Script is running in an unsupported domain: $domain"
        return
    }

    # Define parameters for Send-MailMessage
    $mailMessageParameters = @{
        SmtpServer = $smtpServer
        From = $from
        To = $to -split ',' | ForEach-Object { $_.Trim() } # Split and trim each email address
        Subject = $subject
        Body = $body
        Priority = "High"  # Set priority to High
    }

    if ($isHtml) {
        $mailMessageParameters['BodyAsHtml'] = $true # Conditionally add BodyAsHtml parameter
    }

    # Sending the email
    try {
        Send-MailMessage @mailMessageParameters
        Write-Host "High priority email sent successfully to $to from $from using SMTP server $smtpServer." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to send email. Error: $_" -ForegroundColor Red
    }
}
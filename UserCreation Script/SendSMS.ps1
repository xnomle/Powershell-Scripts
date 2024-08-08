function Send-Message {
    param(
        [Parameter(Mandatory=$true)]
        [string]$msg,

        [Parameter(Mandatory=$true)]
        [string]$num
    )

    $url = 'https://api.messagemedia.com/v1/messages'

    $message = @{
        content = "From AMS: $msg - Do not reply"
        destination_number = $num
    }

    $body = @{
        messages = @($message)
    } | ConvertTo-Json

    $username = 'dsnXgHzpusnCtAr6Apnu'
    $password = 'aAiRkZnPa6FwUZVsKTpt74scUWw77d'
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))

    $headers = @{
        "Accept" = "application/json"
        "Content-Type" = "application/json"
        "Authorization" = "Basic $base64AuthInfo"
    }

    $response = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -Body $body

    if ($response -match "queued") {
        Write-Host "Password sent via SMS successfully" -ForegroundColor Green
    }
    else {
        Write-Host "Password failed to send" -ForegroundColor Red
    }

    #Write-Host $response
}

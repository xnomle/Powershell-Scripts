# Your PowerShell script that generates logs
$logOutput = @{
    "message" = "This is a log message sent via api - NickF"
    "timestamp" = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    # Add other relevant fields
}

# Convert to JSON
$jsonPayload = $logOutput | ConvertTo-Json

# InsightIDR API details
$apiKey = "8c080e36-6acb-4fc2-8563-3ffb9d6d7f4c"
$region = "au" # e.g., "us", "eu", "au", "ca", "uk"
$apiUrl = "https://$region.api.insight.rapid7.com/log/ingest/YOUR_LOG_SET_TOKEN"

# Send to InsightIDR
$headers = @{
    "X-Insight-Token" = $apiKey
    "Content-Type" = "application/json"
}

Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $jsonPayload
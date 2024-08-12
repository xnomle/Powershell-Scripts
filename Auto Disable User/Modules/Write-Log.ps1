
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogEntry
    )

    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $LogEntry"
    $logEntry | Out-File -FilePath $logFilePath -Append
    Write-Host $logEntry
}

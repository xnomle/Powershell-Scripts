# Auto Git Sync Script

# Set the path to your folder
$folderPath = "C:\temp\PowerShell-Scripts"

# Set the branch name (default is "main")
$branchName = "main"

# Function to perform Git operations
function Sync-Git {
    Set-Location $folderPath
    git add .
    git commit -m "Auto-commit: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git push origin $branchName
}

# Create a FileSystemWatcher to monitor the folder
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $folderPath
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Define the action to take when a file is changed
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    Write-Host "File $changeType : $path"
    Sync-Git
}

# Register the event handler
Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Changed" -Action $action
Register-ObjectEvent $watcher "Deleted" -Action $action
Register-ObjectEvent $watcher "Renamed" -Action $action

# Keep the script running
while ($true) { Start-Sleep 5 }
function Disable-UserAccount {
    param (
        [string]$UserAccount,
        [string]$Record
    )

    try {
        # Check if the username contains the domain
        if ($UserAccount -notlike "*@*") {
            # Get the root domain
            $rootDomain = (Get-ADDomain).DNSRoot
            # Append the root domain to the username
            $UserAccount = "$UserAccount@$rootDomain"
        }

        # Get the user's domain
        $userDomain = ($UserAccount.Split('@'))[1].trim()
        # Get the root domain
        $rootDomain = (Get-ADDomain).DNSRoot 

        if ($userDomain -eq $rootDomain) {
            #split the username
            $UserAccount = ($UserAccount.Split('@'))[0].Trim()
            #disable the user account
            Disable-ADAccount -Identity $UserAccount

            # Log the disabled user account
            $logEntry = "User account $UserAccount has been disabled on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            Write-Log -LogEntry $logEntry

            # Check if the account is disabled
            if (-not (Get-ADUser -Identity $UserAccount -Properties Enabled).Enabled) {
                Close-Task -UserAccount $UserAccount -Record $Record
            }
        }
        else {
            # Log when the user's domain doesn't match the root domain
            $logEntry = "Skipping user account $UserAccount. User's domain ($userDomain) does not match the root domain ($rootDomain)"
            Write-Log -LogEntry $logEntry
        }
    }
    catch {
        # Log the error
        $errorMessage = "Error disabling account for user $UserAccount. Error: $($_.Exception.Message)"
        Write-Log -LogEntry $errorMessage
    }
}

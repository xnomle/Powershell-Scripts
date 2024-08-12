function Check-UserOUs {
    param (
        [string]$UserAccount,
        [string]$RaiserEmail
    )

    try {
        # Strip the '@' character and everything after it from the user account
        $strippedUserAccount = $UserAccount.Split('@')[0]

        # Get the AD user object for the user account
        $user = Get-ADUser -Identity $strippedUserAccount -Properties DistinguishedName

        # Get the AD user object associated with the raiser's email
        $raiserUser = Get-ADUser -Filter "EmailAddress -eq '$RaiserEmail'" -Properties EmailAddress, DistinguishedName

        if ($user -and $raiserUser) {
            # Get the OU of the user account
            $userOU = ($user.DistinguishedName -split ",", 2)[1]

            # Get the OU of the raiser's AD account
            $raiserOU = ($raiserUser.DistinguishedName -split ",", 2)[1]

            if ($userOU -ne $raiserOU) {
                # Log when the user's OU doesn't match the raiser's OU
                $logEntry = "User account $UserAccount OU ($userOU) does not match the raiser's OU ($raiserOU)"
                Write-Log -LogEntry $logEntry
                return $false
            }
            else {
                return $true
            }
        }
        else {
            # Log when either user account or raiser's account is not found
            $logEntry = "User account $UserAccount or raiser's account $RaiserEmail not found in Active Directory"
            Write-Log -LogEntry $logEntry
            return $false
        }
    }
    catch {
        # Log any errors that occur during the check
        $errorMessage = "Error checking OUs for user $UserAccount and raiser $RaiserEmail. Error: $($_.Exception.Message)"
        Write-Log -LogEntry $errorMessage
        return $false
    }
}

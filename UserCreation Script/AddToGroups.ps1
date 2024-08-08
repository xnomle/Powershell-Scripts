# Function to add user to AD groups based on API response
function Add-UserToADGroups {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Username,
        [Parameter(Mandatory=$true)]
        [string]$Company,
        [Parameter(Mandatory=$true)]
        [string[]]$Environments,
        [Parameter(Mandatory=$true)]
        [string[]]$Roles
    )

    # Import the Active Directory module if not already imported
    if (-not (Get-Module -Name ActiveDirectory)) {
        Import-Module ActiveDirectory -ErrorAction Stop
    }

    # Base OU to start the search
    $baseOU = "OU=InsCustomers,DC=npr,DC=ams,DC=nz"

    # Function to find the correct OU
    function Find-CorrectOU {
        param (
            [string]$BaseOU,
            [string]$CompanyName
        )
        
        $ous = Get-ADOrganizationalUnit -Filter * -SearchBase $BaseOU -ErrorAction Stop
        foreach ($ou in $ous) {
            if ($ou.Name -eq $CompanyName) {
                return $ou.DistinguishedName
            }
        }
        return $null
    }

    # Function to add user to groups
    function Add-UserToGroups {
        param (
            [string]$Username,
            [string]$GroupsOU,
            [string[]]$Environments,
            [string[]]$Roles
        )
        
        $groups = Get-ADGroup -Filter * -SearchBase $GroupsOU -ErrorAction Stop
        foreach ($group in $groups) {
            foreach ($env in $Environments) {
                foreach ($role in $Roles) {
                    $roleShort = switch ($role.ToLower()) {
                        "value blue" { "vblue" }
                        "vfe" { "vfe" }
                        "claims" { "claims" }
                        default { $role.ToLower() }
                    }
                    # Handle environment names and ensure lowercase
                    $envShort = if ($env.Length -ge 3) { $env.ToLower().Substring(0,3) } else { $env.ToLower() }
                    $groupPattern = "g-$envShort-$roleShort-*".ToLower()
                    if ($group.Name -like $groupPattern) {
                        try {
                            Add-ADGroupMember -Identity $group -Members $Username -ErrorAction Stop
                            Write-Host "Added user $Username to group $($group.Name)" -ForegroundColor Green
                        }
                        catch {
                            Write-Warning "Failed to add user $Username to group $($group.Name): $_"
                        }
                    }
                }
            }
        }
    }

    # Main function execution
    try {
        Write-Host "Starting to add user $Username to AD groups for company $Company" -ForegroundColor Cyan

        # Find the correct OU for the company
        $companyOU = Find-CorrectOU -BaseOU $baseOU -CompanyName $Company
        if ($null -eq $companyOU) {
            throw "Could not find OU for company: $Company"
        }

        # Construct the Groups OU path
        $groupsOU = "OU=Groups,$companyOU"

        # Check if the Groups OU exists
        if (-not (Get-ADOrganizationalUnit -Filter {DistinguishedName -eq $groupsOU} -ErrorAction Stop)) {
            throw "Groups OU not found: $groupsOU"
        }

        # Add user to appropriate groups
        Add-UserToGroups -Username $Username -GroupsOU $groupsOU -Environments $Environments -Roles $Roles

        Write-Host "User $Username has been processed for environments: $($Environments -join ', ') and roles: $($Roles -join ', ')" -ForegroundColor Cyan
    }
    catch {
        Write-Error "An error occurred while adding user to AD groups: $_"
        throw  # Re-throw the error to be caught by the calling script
    }
}
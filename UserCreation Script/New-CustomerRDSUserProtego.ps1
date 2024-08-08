function New-CustomerRDSUser-updated {
    <# 
       .SYNOPSIS
    
         Function to create new customer user accounts within protego domains
    
    .DESCRIPTION
    
         Function to create new customer user accounts within WaaS domains.
         In order to allow this function to allow users to be added to the correct RDS groups, ensure the customer RDS tenant has been created using the "New-RDSTenant.PS1" PowerShell script.
         This function will create the user account in the customers OU and assign the required groups.
         The following parameters are compulsory;
            -FirstName
            -LastName
            -Title
            -EmailAddress
            -Company
            -CompanyDesignator

    .EXAMPLE
         New-CustomerRDSUser -FirstName Robert -LastName Dylan -Department Entertainment -Title Artist -PhoneNumber 5556627 -Description "Example RDS user" -Company "IB Testing" -CompanyDesignator IBTE -G3Access -ReportBuilderAccess -DetailedOutput
    
    .EXAMPLE
         New-CustomerRDSUser -FirstName Shuan -LastName Nicholas -Department Logistics -Title "Delivery Technician" -Company "NP Workshops" -CompanyDesignator NPWS -ACTORAccess -AccountExpiration 22/01/2020
        
    .NOTES
    
         Author             : Chris McDermott - chris@ams.co.nz
         Revision History   :
        +---------+------------+-------------------------+----------------------------------+
        | Version |    Date    |       Updated By        |             Comments             |
        +---------+------------+-------------------------+----------------------------------+
        |     1.0 | 22/11/2019 | Chris McDermott         | First release                    |
        |     1.1 | 23/06/2021 | Daniel Slater           | Added UPN (Ln. 99 & 136, 196)    |
        +---------+------------+-------------------------+----------------------------------+
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FirstName,
    
        [Parameter(Mandatory = $true)]
        [string]$LastName,
    
        [Parameter()]
        [string]$Department,
    
        [Parameter(Mandatory = $true)]
        [string]$Title,
    
        [Parameter(Mandatory = $true, HelpMessage = "This is the users email address")]
        [string]$EmailAddress,
    
        [Parameter()]
        [string]$PhoneNumber,
    
        [Parameter()]
        [string]$Description,
    
        [Parameter(Mandatory = $true)]
        [string]$Company,
    
        [Parameter(Mandatory = $true)]
        [string]$CompanyDesignator,
    
        [Parameter()]
        [bool]$G3Access = $false,
    
        [Parameter()]
        [bool]$ReportBuilderAccess = $false,
    
        [Parameter()]
        [bool]$ACTORAccess = $false,
    
        [Parameter()]
        [string]$AccountExpiration = "0",
    
        [Parameter()]
        [switch]$DetailedOutput,
    
        [Parameter()]
        [switch]$Claims = $false,

        [Parameter()]
        [switch]$vblue = $false,

        [Parameter()]
        [switch]$vfe = $false,

        [Parameter()]
        [switch]$clmsm1 = $false,

        [Parameter()]
        [switch]$clmsm2 = $false,

        [Parameter()]
        [switch]$clmsop = $false,

        [Parameter()]
        [switch]$clmsuw = $false,
    
        [Parameter()]
        [bool]$ISMhosted = $false,
    
        [Parameter()]
        [bool]$Ismportalmanager = $false
                
       ) # End of Parameters
    
    Begin {
        if ($AccountExpiration -ne "0") { $AccountExpiration = Get-Date $AccountExpiration -Format dd\MM\yyyy }

        $CompanyDisplayName = $Company
        
        if (!($Description)) { $Description = "$Company Remote Application User" }
        if (!($Department)) { $Department = "Protego User" }
        if (!($PhoneNumber)) { $PhoneNumber = "0000" }
    
        # Map to UNC Path to load Password Functions Module
        if ($DetailedOutput -eq $true) { Write-Host "Mapping PSDrive Y to \\file\CommonRepository" -ForegroundColor Cyan }
        $psd = New-PSDrive -Name Y -PSProvider FileSystem -Root "\\file\CommonRepository"
        if (!($psd)) { $psd = New-PSDrive -Name Y -PSProvider FileSystem -Root "\file\CommonRepository" -Credential $(Get-Credential "PROD\a-prd-chrism" -Message "Please provide credential to connect to the File Service") }
        if (!($psd)) {
            Write-Host "ERROR: Failed to connect to the File Service to load dependencies."
            Break
        }
    
        if ($DetailedOutput -eq $true) { Write-Host "Importing Passwordfunctions.psm1 module" -ForegroundColor Cyan }
        Import-Module "Y:\ManagementScripts\PSModules\PasswordFunctions.psm1" -WarningAction Ignore
    
        if ($DetailedOutput -eq $true) { Write-Host "Un-Mapping PSDrive Y" -ForegroundColor Cyan }
        Remove-PSDrive -Name Y -Force
    
        # Variables
        if ($DetailedOutput -eq $true) { Write-Host "Setting function variables" -ForegroundColor Cyan }
        $ADDomainDN = (get-ADDomain).DistinguishedName
        $ADDomainDNSRoot = (get-ADDomain).DNSRoot #Required for UPN
        if ($DetailedOutput -eq $true) { Write-Host "Active Directory Domain Distinguished Name: $ADDomainDN" -ForegroundColor Cyan }
        $custOU = Get-ADOrganizationalUnit -Filter * | ? { $_.DistinguishedName -like "OU=$CompanyDesignator,OU=InsCustomers*" }
        if (!($custOU)) {
            Write-Host "ERROR: Unable to locate Customer OU AD Organizational unit." -ForegroundColor Red
            if ((Read-Host -Prompt "Do you wish to create this OU in Active Directory?") -eq "y") {
                $baseOU = Get-ADOrganizationalUnit -Filter * | ? { $_.DistinguishedName -like "OU=INSCustomers*" }
                New-ADOrganizationalUnit -Name $CompanyDesignator -Path $baseOU
                $custOU = Get-ADOrganizationalUnit -Filter * | ? { $_.DistinguishedName -like "OU=$CompanyDesignator,OU=INSCustomers*" }
            }
            else { break }
        }
        $custUserOU = Get-ADOrganizationalUnit -Filter * | ? { $_.DistinguishedName -like "OU=User Accounts,OU=$CompanyDesignator,OU=InsCustomers*" }
        if (!($custUserOU)) {
            Write-Host "ERROR: Unable to locate Customer User Accounts OU AD Organizational unit." -ForegroundColor Red
            if ((Read-Host -Prompt "Do you wish to create this OU in Active Directory?") -eq "y") {
                New-ADOrganizationalUnit -Name $CompanyDesignator -Path $baseOU
                $custUserOU = Get-ADOrganizationalUnit -Filter * | ? { $_.DistinguishedName -like "OU=User Accounts,$custOU" }
            }
            else { break }
        }

        if ($DetailedOutput -eq $true) { Write-Host "Customer User Accounts OU Distinguished Name: $custUserOU" -ForegroundColor Cyan }

    
    } # End of Begin
    
    Process {
    
        
        # Create the user login name
        if ($DetailedOutput -eq $true) { Write-Host "Creating user Logon name" -ForegroundColor Cyan }
        $LogonName = ($FirstName.ToCharArray()[0] + $LastName).ToLower()
        $UPN = $LogonName + "@" + $ADDomainDNSRoot #Join the logon name to the DNS root to create a full UPN
        $Name = $FirstName + " " + $LastName
        if ($LogonName.length -gt "16") {
            if ($DetailedOutput -eq $true) { Write-Host "Truncating logon name to maximum of 16 characters" -ForegroundColor Cyan }
            $LogonName = $LogonName.Substring(0, 16)
        }
        $counter = 0
        $orgLogonName = $LogonName
        do {
            $chkADuser = ""
            try {
                $chkADuser = Get-ADUser -Identity $LogonName -ErrorAction SilentlyContinue
            }
            catch {
                
            }
    
            if ($chkADuser) {
                if ($DetailedOutput -eq $true) { Write-Host "User logon name $LogonName is in use. incrementing suffix" -ForegroundColor Cyan }
                if ($orgLogonName.Length -gt "14") { $LogonName = $orgLogonName.Substring(0, 16) }
                $counter = $counter + 1
                $LogonName = $OrgLogonName + $($counter.ToString("00"))
            } #end of if
            if ($DetailedOutput -eq $true) { Write-Host "User logon name: $LogonName" -ForegroundColor Cyan }  
        } until (!($chkADuser))
         
        ### # Check Name
        # Initialize the user's logon name and UPN
        $LogonName = ($FirstName.ToCharArray()[0] + $LastName).ToLower()
        $UPN = $LogonName + "@" + $ADDomainDNSRoot
        $DisplayName = $FirstName + " " + $LastName
        $Name = $DisplayName # Typically the CN attribute in AD
        $originalLogonName = $LogonName
        $counter = 1

        # Ensure LogonName does not exceed length restrictions
        if ($LogonName.length -gt 14) {
            $LogonName = $LogonName.Substring(0, 14)
        }

        # Check if any unique attribute already exists and increment if it does
        do {
            $userExists = Get-ADUser -Filter "SamAccountName -eq '$LogonName' -or UserPrincipalName -eq '$UPN' -or DisplayName -eq '$DisplayName' -or Name -eq '$Name'" -ErrorAction SilentlyContinue
            if (-not $userExists) {
                break
            }
            if ($DetailedOutput) {
                Write-Host "Conflict found for SamAccountName, UPN, DisplayName, or Name. Incrementing..." -ForegroundColor Cyan
            }
            # Increment the counter to make all attributes unique
            $suffix = $counter.ToString("00")
            $LogonName = $originalLogonName + $suffix
            $UPN = $LogonName + "@" + $ADDomainDNSRoot
            $DisplayName = $FirstName + " " + $LastName + " " + $suffix
            $Name = $DisplayName
            $counter++
        } while ($userExists)
        # After ensuring other attributes are unique, check for email uniqueness
        #    $emailExists = Get-ADUser -Filter "mail -eq '$EmailAddress'"
        #    if ($emailExists) {
        #    throw "The email address $EmailAddress is already in use. Please Check if this user can be reactivated."
        

        if ($DetailedOutput) {
            Write-Host "Using SamAccountName: $LogonName" -ForegroundColor Cyan
            Write-Host "Using UPN: $UPN" -ForegroundColor Cyan
            Write-Host "Using DisplayName: $DisplayName" -ForegroundColor Cyan
            Write-Host "Using Name: $Name" -ForegroundColor Cyan
            Write-Host "Using Email: $EmailAddress" -ForegroundColor Cyan

        }
        ###########      
    
        # Generate Password
        if ($DetailedOutput -eq $true) { Write-Host "Creating initial password" -ForegroundColor Cyan }
        $ptPass = Generate-RandomPassword -Complexity 2
        $secPass = $ptPass | ConvertTo-SecureString -Force -AsPlainText
    
        # Create AD User
        $DisplayName = $FirstName + " " + $LastName
        if ($DetailedOutput -eq $true) { Write-Host "Creating user $LogonName in $custUserOU for $CompanyDispayName" -ForegroundColor Cyan }
        New-ADUser -GivenName $FirstName -Surname $LastName -SamAccountName $LogonName -UserPrincipalName $UPN -Name $Name -DisplayName $DisplayName -Description $Description -AccountPassword $secPass -Company $CompanyDisplayName -Path $custUserOU -EmailAddress $EmailAddress -Department $Department -Title $Title -OfficePhone $PhoneNumber -ChangePasswordAtLogon $true -Enabled $true
        Start-Sleep -Seconds 5
        # Confirm Creation
        $chkADuser = ""
        $chkADuser = Get-ADUser -Identity $LogonName -ErrorAction SilentlyContinue
        if ($chkADuser) { Write-Host "User $LogonName created" -ForegroundColor Green }
    
        # Add user to groups
        if ($DetailedOutput -eq $true) { Write-Host "Checking for RDS groups for $Company" -ForegroundColor Cyan }
        $custGroups = Get-ADGroup -Filter * -Properties * | where { $_.DistinguishedName -like "*OU=$CompanyDesignator,OU=INSCustomers,*" } | select Name, DistinguishedName, Description
                       
        if ($Claims) {
            if ($DetailedOutput) { Write-Host "Checking for Claims RDS group for $Company" -ForegroundColor Cyan }
    
            # Retrieve the group 
            $ClaimsGroup = $custGroups | Where-Object { $_.description -like "*Claims Desktop*" } | Select-Object -First 1

            if ($ClaimsGroup) {
                if ($DetailedOutput) { Write-Host "Adding $LogonName to $($ClaimsGroup.Name)" -ForegroundColor Cyan }
                Add-ADGroupMember -Identity $ClaimsGroup.DistinguishedName -Members $LogonName
            }
            else {
                Write-Host "ERROR: Claims RDS group for $Company not found. Skipping..." -ForegroundColor Red
            }
        }
        else {
            if ($DetailedOutput) { Write-Host "Claims RDS access not selected for $LogonName" -ForegroundColor Cyan }
        }

        if ($vblue) {
            if ($DetailedOutput) { Write-Host "Checking for Value Blue RDS group for $Company" -ForegroundColor Cyan }
    
            # Retrieve the group 
            $vblueGroup = $custGroups | Where-Object { $_.description -like "*VALUE Blue*" } | Select-Object -First 1

            if ($vblueGroup) {
                if ($DetailedOutput) { Write-Host "Adding $LogonName to $($vblueGroup.Name)" -ForegroundColor Cyan }
                Add-ADGroupMember -Identity $vblueGroup.DistinguishedName -Members $LogonName
            }
            else {
                Write-Host "ERROR: Value Blue RDS group for $Company not found. Skipping..." -ForegroundColor Red
            }
        }
        else {
            if ($DetailedOutput) { Write-Host "Value Blue RDS access not selected for $LogonName" -ForegroundColor Cyan }
        }

        if ($vfe) {
            if ($DetailedOutput) { Write-Host "Checking for VFE RDS group for $Company" -ForegroundColor Cyan }
    
            # Retrieve the group 
            $vfeGroup = $custGroups | Where-Object { $_.description -like "* VFE Underwriting*" } | Select-Object -First 1

            if ($vfeGroup) {
                if ($DetailedOutput) { Write-Host "Adding $LogonName to $($vfeGroup.Name)" -ForegroundColor Cyan }
                Add-ADGroupMember -Identity $vfeGroup.DistinguishedName -Members $LogonName
            }
            else {
                Write-Host "ERROR: VFE RDS group for $Company not found. Skipping..." -ForegroundColor Red
            }
        }
        else {
            if ($DetailedOutput) { Write-Host "VFE RDS access not selected for $LogonName" -ForegroundColor Cyan }
        }



        if ($Ismportalmanager) {
            if ($DetailedOutput) { Write-Host "Attempting to add $LogonName to ISM Portal Manager Group..." -ForegroundColor Cyan }
            # Retrieve the group object
            $Ismportalmanagergroup = Get-ADGroup -Filter { Name -eq "g-prd-itsm-portalmanager" }
            if ($Ismportalmanagergroup) {
                if ($DetailedOutput) { Write-Host "Adding $LogonName to $($Ismportalmanagergroup.Name)" -ForegroundColor Cyan }
                Add-ADGroupMember -Identity $Ismportalmanagergroup.DistinguishedName -Members $LogonName
            }
            else {
                Write-Host "ERROR: adding user to ISM portal manager group for Skipping..." -ForegroundColor Red
            }
        }
        else {
            if ($DetailedOutput) { Write-Host "ISM Portal manager access not selected for $LogonName" -ForegroundColor Cyan }
        }
        
        if ($ISMhosted) {
            if ($DetailedOutput) { Write-Host "Attempting to add $LogonName to ISM Hosted Group..." -ForegroundColor Cyan }
            # Retrieve the group object
            $ISMhostedGroup = Get-ADGroup -Filter { Name -eq "g-prd-itsm-hostedP" }

            if ($ISMhostedGroup) {
                if ($DetailedOutput) { Write-Host "Adding $LogonName to $($ISMhostedGroup.Name)" -ForegroundColor Cyan }
                Add-ADGroupMember -Identity $ISMhostedGroup.DistinguishedName -Members $LogonName
            }
            else {
                Write-Host "ERROR: ISM Hosted group for $Company not found. Skipping..." -ForegroundColor Red
            }
        }
        else {
            if ($DetailedOutput) { Write-Host "ISM Hosted access not selected for $LogonName" -ForegroundColor Cyan }
        }
           
        if ($clmsm1) {
            if ($DetailedOutput) { Write-Host "Attempting to add $LogonName to g-prd-clmsm1-nib..." -ForegroundColor Cyan }
            # Retrieve the group object
            $clmsm1group = Get-ADGroup -Filter { Name -eq "g-prd-clmsm1-nib" }

            if ($clmsm1group) {
                if ($DetailedOutput) { Write-Host "Adding $LogonName to $($clmsm1group.Name)" -ForegroundColor Cyan }
                Add-ADGroupMember -Identity $clmsm1group.DistinguishedName -Members $LogonName
            }
            else {
                Write-Host "ERROR: adding user to g-prd-clmsm1-nib group for Skipping..." -ForegroundColor Red
            }
        }
        else {
            if ($DetailedOutput) { Write-Host " g-prd-clmsm1-nib access not selected for $LogonName" -ForegroundColor Cyan }
        }

        if ($clmsm2) {
            if ($DetailedOutput) { Write-Host "Attempting to add $LogonName to g-prd-clmsm2-nib..." -ForegroundColor Cyan }
            # Retrieve the group object
            $clmsm2group = Get-ADGroup -Filter { Name -eq "g-prd-clmsm2-nib" }

            if ($clmsm2group) {
                if ($DetailedOutput) { Write-Host "Adding $LogonName to $($clmsm2group.Name)" -ForegroundColor Cyan }
                Add-ADGroupMember -Identity $clmsm2group.DistinguishedName -Members $LogonName
            }
            else {
                Write-Host "ERROR: adding user to g-prd-clmsm2-nib group for Skipping..." -ForegroundColor Red
            }
        }
        else {
            if ($DetailedOutput) { Write-Host " g-prd-clmsm2-nib access not selected for $LogonName" -ForegroundColor Cyan }
        }

        if ($clmsop) {
            if ($DetailedOutput) { Write-Host "Attempting to add $LogonName to g-prd-clmsop-nib..." -ForegroundColor Cyan }
            # Retrieve the group object
            $clmsopgroup = Get-ADGroup -Filter { Name -eq "g-prd-clmsop-nib" }

            if ($clmsopgroup) {
                if ($DetailedOutput) { Write-Host "Adding $LogonName to $($clmsopgroup.Name)" -ForegroundColor Cyan }
                Add-ADGroupMember -Identity $clmsopgroup.DistinguishedName -Members $LogonName
            }
            else {
                Write-Host "ERROR: adding user to g-prd-clmsop-nib group for Skipping..." -ForegroundColor Red
            }
        }
        else {
            if ($DetailedOutput) { Write-Host " g-prd-clmsop-nib access not selected for $LogonName" -ForegroundColor Cyan }
        }

        if ($clmsuw) {
            if ($DetailedOutput) { Write-Host "Attempting to add $LogonName to g-prd-clmsuw-nib..." -ForegroundColor Cyan }
            # Retrieve the group object
            $clmsuwgroup = Get-ADGroup -Filter { Name -eq "g-prd-clmsuw-nib" }

            if ($clmsuwgroup) {
                if ($DetailedOutput) { Write-Host "Adding $LogonName to $($clmsuwgroup.Name)" -ForegroundColor Cyan }
                Add-ADGroupMember -Identity $clmsuwgroup.DistinguishedName -Members $LogonName
            }
            else {
                Write-Host "ERROR: adding user to g-prd-clmsuw-nib group for Skipping..." -ForegroundColor Red
            }
        }
        else {
            if ($DetailedOutput) { Write-Host " g-prd-clmsuw-nib access not selected for $LogonName" -ForegroundColor Cyan }
        }

        

      Start-Sleep -Seconds 2
    }        
    # End of Process

    
    end {
        $grpMbrshp = ((Get-ADPrincipalGroupMembership -Identity $LogonName).SamAccountName) -join ","
    
        $Output = @(
            @{Name = $DisplayName; LogonName = $LogonName; Description = $Description; Password = $ptPass; GroupMembership = $grpMbrshp }
        ) | % { New-Object object | Add-Member -NotePropertyMembers $_ -PassThru }
    
        Return $Output | Select Name, LogonName, Description, Password, GroupMembership
    }
} # End of Function

   

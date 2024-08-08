# Ensure the ActiveDirectory module is loaded
Import-Module ActiveDirectory
#import User creation script 
Import-Module "\\File\CommonRepository\ManagementScripts\User_Management_Scripts\Create RDS User Gui - Protego\New-CustomerRDSUserProtego.ps1" | Out-Null
#import text script 
Import-Module "\\File\CommonRepository\ManagementScripts\User_Management_Scripts\Create RDS User Gui - Protego\sendSMS.ps1" | Out-Null
#import Email function 
Import-Module "\\File\CommonRepository\ManagementScripts\User_Management_Scripts\Create RDS User Gui - Protego\sendEmail.ps1" | Out-Null
#import email body 
import-module "\\File\CommonRepository\ManagementScripts\User_Management_Scripts\Create RDS User Gui - Protego\EmailBody.ps1"
#import SPDB Module
Import-Module "\\file\CommonRepository\ManagementScripts\User_Management_Scripts\Create RDS User Gui - Protego\SPDB.ps1"
#import Add user to Groups - NPR Module
Import-Module "\\file\CommonRepository\ManagementScripts\User_Management_Scripts\Create RDS User Gui - Protego\AddToGroups.ps1"

# Declare a script-level variable to store the QueryISM result
$script:queryIsmResult = $null

$ShowFormScriptBlock = {
# Load the Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
Add-Type -AssemblyName System.Drawing


# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'AMS Protego User Creation Gui'
$form.Size = New-Object System.Drawing.Size(600,700) # Adjusted size to accommodate more fields
$form.StartPosition = 'CenterScreen'

# Path to your image
$imagePath = "\\File\CommonRepository\ManagementScripts\User_Management_Scripts\Create RDS User Gui - Protego\AMSProtego Logo.png"

if (Test-Path $imagePath) {
    $image = [System.Drawing.Image]::FromFile($imagePath)
    $pictureBox = New-Object System.Windows.Forms.PictureBox
    $pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $pictureBox.Size = New-Object System.Drawing.Size(600, 100) # Adjust width and height as needed
    $pictureBox.Location = New-Object System.Drawing.Point(0, 0) # Adjust X and Y as needed
    $pictureBox.Image = $image
    $form.Controls.Add($pictureBox)
} else {
    Write-Warning "Image path $imagePath not found."
}


# Function to add a label and text box or checkbox to the form
function Add-InputField {
    param($form, $labelText, $position, $isCheckbox = $false, $isSwitch = $false, $labelWidth = 180)
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, $position)
    $label.Size = New-Object System.Drawing.Size($labelWidth, 20)
    $label.Text = $labelText
    $form.Controls.Add($label)

    if ($isCheckbox -or $isSwitch) {
        $inputControl = New-Object System.Windows.Forms.CheckBox
        $inputControl.Location = New-Object System.Drawing.Point(200, $position)
        $inputControl.Size = New-Object System.Drawing.Size(15, 14)
    } else {
        $inputControl = New-Object System.Windows.Forms.TextBox
        $inputControl.Location = New-Object System.Drawing.Point(200, $position)
        $inputControl.Size = New-Object System.Drawing.Size(180, 20)
        $inputControl.Text = $defaultValue # Set default value
    }

    $form.Controls.Add($inputControl)

    return $inputControl
}


# Checking domain script is running on and setting base domain var
$domain = $env:USERDNSDOMAIN.Trim().ToUpper()

if ($domain -eq "NPR.AMS.NZ") {
    #Write-Host "Matched NPR.AMS.NZ"
    $baseOU = "OU=InsCustomers,DC=npr,DC=ams,DC=nz"
} elseif ($domain -eq "AMS.NZ") {
    #Write-Host "Matched AMS.NZ"
    $baseOU = "OU=InsCustomers,DC=ams,DC=nz"
} else {
    Write-Error "Unable to find domain"
    return
}

# Retrieve list of direct child OUs within the specified base OU
#$ouList = Get-OUs -baseOU $baseOU

# Initialize position
$position = 100

# Add input fields - add Free form box in gui 
$tck = Add-InputField -form $form -labelText "Service Request Number" -position $position
$position += 30
$firstNameTextBox = Add-InputField -form $form -labelText "First Name :" -position $position
$position += 30
$lastNameTextBox = Add-InputField -form $form -labelText "Last Name :" -position $position
$position += 30
$titleTextBox = Add-InputField -form $form -labelText "Job Title:" -position $position
$position += 30
$emailAddressTextBox = Add-InputField -form $form -labelText "EmailAddress:" -position $position
$position += 30
$companyComboBox = Add-InputField -form $form -labelText "Company:" -position $position
$position += 30
$num = Add-InputField -form $form -labelText "Number to send password to" -position $position
$position += 30
$PwrUserEmail = Add-InputField -form $form -labelText "Email User Details to" -position $position
$position += 30




# checkbox - add new text box here
$Claims = Add-InputField -form $form -labelText "Claims" -position $position -isCheckbox $true
$position += 30
$vblue = Add-InputField -form $form -labelText "Value Blue" -position $position -isCheckbox $true
$position += 30
$VFE = Add-InputField -form $form -labelText "VFE" -position $position -isCheckbox $true
$position += 30
$clmsm1 = Add-InputField -form $form -labelText "g-prd-clmsm1-nib" -position $position -isCheckbox $true
$position += 30
$clmsm2 = Add-InputField -form $form -labelText "g-prd-clmsm2-nib" -position $position -isCheckbox $true
$position += 30
$clmsop = Add-InputField -form $form -labelText "g-prd-clmsop-nib" -position $position -isCheckbox $true
$position += 30
$clmsuw = Add-InputField -form $form -labelText "g-prd-clmsuw-nib" -position $position -isCheckbox $true
$position += 30
$ismHosted = Add-InputField -form $form -labelText "Support Portal Hosted" -position $position -isCheckbox $true
$position += 30
$Ismportalmanager = Add-InputField -form $form -labelText "Support Portal Manager" -position $position -isCheckbox $true
$position += 30

# Create populate ticket button
$populateTicketButton = New-Object System.Windows.Forms.Button  # Use a different variable name
$populateTicketButton.Location = New-Object System.Drawing.Point(310, $position)  # Adjust position if needed
$populateTicketButton.Size = New-Object System.Drawing.Size(120, 30)  # Adjust size if needed
$populateTicketButton.Text = 'Populate Ticket'
$form.Controls.Add($populateTicketButton) 

$populateTicketButton.Add_Click({
    $ticketText = $tck.Text.Trim()
    
    if ([string]::IsNullOrEmpty($ticketText)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid ticket number.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    $scriptPath = "\\File\CommonRepository\ManagementScripts\User_Management_Scripts\Create RDS User Gui - Protego\QueryISM.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        [System.Windows.Forms.MessageBox]::Show("The required script file does not exist: $scriptPath", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    try {
        # Execute the QueryISM script and capture its output
        $script:queryIsmResult = & $scriptPath -tck $ticketText -ErrorAction Stop

        # Print the entire returned object to the PowerShell prompt
        #Write-Host ("QueryISM.ps1 returned the following result for ticket {0}:" -f $ticketText) -ForegroundColor Cyan
        #  $script:queryIsmResult | Format-List | Out-String | Write-Host
        
        if ($null -eq $script:queryIsmResult) {
            [System.Windows.Forms.MessageBox]::Show("No results found for the given ticket number.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }
        
        # Populate form fields
        $firstNameTextBox.Text = $script:queryIsmResult.FirstName
        $lastNameTextBox.Text = $script:queryIsmResult.LastName
        $titleTextBox.Text = $script:queryIsmResult.Title
        $emailAddressTextBox.Text = $script:queryIsmResult.Email
        $num.Text = $script:queryIsmResult.MobileNumber
        $PwrUserEmail.Text = $script:queryIsmResult.TicketRaiser
        $companyComboBox.Text = $script:queryIsmResult.UserOU
        
        # Update checkboxes
        $VFE.Checked = $script:queryIsmResult.VFE
        $Claims.Checked = $script:queryIsmResult.Claims
        $vblue.Checked = $script:queryIsmResult.ValueBlue
        $clmsm1.Checked = $script:queryIsmResult.Clmsm1
        $clmsm2.Checked = $script:queryIsmResult.Clmsm2
        $clmsop.Checked = $script:queryIsmResult.Clmsop
        $clmsuw.Checked = $script:queryIsmResult.Clmsuw
        $ismHosted.Checked = $script:queryIsmResult.ISMHosted
        $Ismportalmanager.Checked = $script:queryIsmResult.ISMPortalManager

    }
    catch {
        Write-Host "An error occurred while executing QueryISM.ps1:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show("An error occurred while retrieving ticket information. Check the console for details.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

#create submit button

$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Location = New-Object System.Drawing.Point(200, $position)
$submitButton.Size = New-Object System.Drawing.Size(100, 30)
$submitButton.Text = 'Submit'
$form.Controls.Add($submitButton)


$submitButton.Add_Click({

    
    # Collect input data
    $firstName = $firstNameTextBox.Text.trim()
    $lastName = $lastNameTextBox.Text.trim()
    $title = $titleTextBox.Text.trim()
    $emailAddress = $emailAddressTextBox.Text.trim()
    $num = $num.text.trim()
    $tck = $tck.text.trim()
    $to = $PwrUserEmail.text.trim()
    $company = $companyComboBox.Text.Trim()
    
    # Check if the number starts with '0'
    if ($num.StartsWith("0")) {
    # Replace the leading '0' with '+64'
    $num = "+64" + $num.Substring(1)
    }
    # Check if the number does not start with '+64' after potential modification
    elseif (-not $num.StartsWith("+64")) {
    # If the number doesn't start with '+64', stop the script and write an error
    Write-Host "Error: Number must start with +64, Only NZ numbers are allowed through the gateway. Script execution stopped." -ForegroundColor Red
    exit
        }

    # Ensure to call ToString() only if an item is selected
    #$company = if ($companyComboBox.SelectedItem -ne $null) { $companyComboBox.SelectedItem.ToString() } else { "" }

    # Convert checkbox states to boolean - add new text box variables here -
    $ISMhosted = $ISMhosted.Checked
    $Ismportalmanager = $Ismportalmanager.Checked
    $Claims = $Claims.Checked
    $vblue = $vblue.Checked
    $vFE = $vFE.Checked
    $clmsm1 = $clmsm1.Checked
    $clmsm2 = $clmsm2.Checked
    $clmsop = $clmsop.Checked
    $clmsuw = $clmsuw.Checked

    #Important for find right OU
    $companyDesignator = $company
    

    # Initialize a hashtable for parameters - if a new text box is added it'll need adding here. 
    $paramHash = @{
        FirstName = $firstName
        LastName = $lastName
        Title = $title
        EmailAddress = $emailAddress
        Company = $company
        CompanyDesignator = $companyDesignator
    }

    # Conditionally add switch parameters based on the checkbox states - update here for new tick box also. 
    if ($ISMhosted) { $paramHash['ISMhosted'] = $true }
    if ($Ismportalmanager) { $paramHash['Ismportalmanager'] = $true }
    if ($Claims) { $paramHash['Claims'] = $true }
    if ($vblue) { $paramHash['VBlue'] = $true }
    if ($vFE) { $paramHash['VFE'] = $true }
    if ($clmsm1) { $paramHash['Clmsm1'] = $true }
    if ($clmsm2) { $paramHash['Clmsm2'] = $true }
    if ($clmsop) { $paramHash['Clmsop'] = $true }
    if ($clmsuw) { $paramHash['Clmsuw'] = $true }
    

    # Call the function using splatting
    $result = New-CustomerRDSUser-updated @paramHash

    if ($result -and $env:USERDNSDOMAIN -eq "NPR.AMS.NZ") {
        try {
            # Ensure we have the necessary data from the ISM query result
            if ($null -eq $script:queryIsmResult) {
                throw "ISM query result is null. Please ensure you've queried the ticket information first."
            }
    
            # Extract the required information from the ISM query result
            $username = $result.LogonName  # This comes from the user creation result
            $environments = $script:queryIsmResult.Environment
            $roles = $script:queryIsmResult.ListRole
            $company
    
            # Validate the extracted data
            if ([string]::IsNullOrWhiteSpace($username)) {
                throw "Username is empty or null"
            }
            if ([string]::IsNullOrWhiteSpace($company)) {
                throw "Company is empty or null"
            }
            if ($null -eq $environments -or $environments.Count -eq 0) {
                throw "No environments specified"
            }
            if ($null -eq $roles -or $roles.Count -eq 0) {
                throw "No roles specified"
            }
    
            # Call the Add-UserToADGroups function
            Add-UserToADGroups -Username $username `
                               -Company $company `
                               -Environments $environments `
                               -Roles $roles
    
            Write-Host "User successfully added to AD groups" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to add user to AD groups: $_"
            [System.Windows.Forms.MessageBox]::Show("Failed to add user to AD groups. Please check the console for details.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        
        Write-Host "Domain = $env:USERDNSDOMAIN - Group Access by RDS User Creation Script."
    }
   

    #Outputs from New User RDS Script 
    $pw = $result.password
    $User = $result.logonname
    $name = $result.name
    $adgroups = $result.GroupMembership
    $result | Format-Table -AutoSize

    #Send PW via SMS to puser 
    if ($company -ne "Chub"){ Send-Message -msg "$tck - $pw" -num "$num" }                
    
    #email logic for chubb users.
    # Set Email body vars
    if ($company -eq "chub"){
        $emailBody = Get-HTMLFormattedEmailBody -Username "$User" -FullName "$name"  -password "Texted To Number On Ticket" -groups "$ADgroups" -domain $domain 
    }
        else {
            $emailBody = Get-HTMLFormattedEmailBody -Username "$User" -FullName "$name"  -password "Texted To Number On Ticket" -groups "$ADgroups" -domain $domain
        }
    #send Email to user with Username
     if ($company -eq "chub"){    Send-Email  -to "protegouserrequests@ams.co.nz" -subject "$tck - New Chubb User Created" -body "$emailBody" -isHtml $true
     #if ($company -eq "chub"){    Send-Email  -to "Nick.fairbairn@ams.co.nz,IT@ams.co.nz" -subject "$tck - New Chubb User Created" -body "$emailBody" -isHtml $true
     #Put User Password into SPDB.
        Put-Password -Ticket $tck -Username $User -Password $pw -description $tck
    } 
        else {
            Send-Email  -to "$to" -subject "$tck - New User Created" -body "$emailBody" -isHtml $true
        } 

        #add user detials into ISM Ticket and trim trailing spaces on ticket number
     $tcktrim = $tck.Trim()
     $emailBody = Get-HTMLFormattedEmailBody -Username "$User" -FullName "$name"  -password "Removed" -groups "$ADgroups" -domain $domain
     Send-Email  -to "support@ams.nz" -subject "Service Request# $tcktrim" -body "$emailBody" -isHtml $true

    # show a confirmation message or handle errors
    [System.Windows.Forms.MessageBox]::Show("Check Script Output for result.")
    })


   
# Show the form
 $form.ShowDialog() | Out-Null
  # After the form is closed, dispose of it to free up resources.
 $form.Dispose()
 }

 # run the script block in a loop to create a new instance of the form each time.
do {
    # Call the script block to show the form
    & $ShowFormScriptBlock

    # Prompt the user to see if they wish to create another user.
    $userChoice = [System.Windows.Forms.MessageBox]::Show("Do you want to create another user?", "Continue", [System.Windows.Forms.MessageBoxButtons]::YesNo)
} while ($userChoice -eq 'Yes')

# If the user selects "No", the script will end.
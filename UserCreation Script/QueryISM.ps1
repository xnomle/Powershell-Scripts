# region ---------------------------------------------------------------------------------------- Ingest and popluate variables

# Adding a param block to accept a ticket number as an argument
param(
    [Parameter(Mandatory=$true)]
    [int]$tck  
)

# Directly defined parameters within the script
$baseUrl = "https://ism.ams.nz/"
$authorization = "rest_api_key=E0248BCF00D1423892350506B1B1F458"


# Variables
$headers = @{
    "Authorization" = $authorization
}
$number = $tck
$EmailFrom = $env:EMAIL_FROM

# Incidents Get Params
$parent=$response.RecId
$params = "`$filter=(ServiceReqNumber%20eq%20$number)&`$select=RecId"
$resourcePath = "HEAT/api/odata/businessobject/ServiceReqs"
$url = "${baseUrl}${resourcePath}?${params}"

# Create the Authorization header
$Pair = $apiKey + ":" + $apiSecret
$EncodedPair = [System.Text.Encoding]::UTF8.GetBytes($Pair)
$Base64Pair = [System.Convert]::ToBase64String($EncodedPair)
$SmsHeaders = @{
    Authorization = "Basic $Base64Pair"
    Accept = "application/json"
    'Content-Type' = "application/json"
}

# endregion

# Call Ivanti to GET Incidents
Write-Output "Calling Ivanti to GET Requests"

#start with SR which is like 12345
# make thiis call, passing the SR as a filter
$response = Invoke-RestMethod -Uri $url -Headers $headers
$jsonData = $response | ConvertTo-Json -Depth 100
#Write-Output $jsonData
#Write-Output $response 
#extract the rec ID and assign it to $parent
$parent = $response.value[0].RecId			
$params = "`$filter=(ParentLink_RecID%20eq%20%27$parent%27)&`$select=ParameterName,ParameterValue"

# set url for second call, to get parameters
$resourcePath = "HEAT/api/odata/businessobject/ServiceReqParams"
$url = "${baseUrl}${resourcePath}?${params}"
#Write-Output $url

# Execute the REST API call
$response = Invoke-RestMethod -Uri $url -Headers $headers
# Print the raw response for debugging/verification
#Write-Output "Raw Response:"
#Write-Output ($response | ConvertTo-Json -Depth 100)

# Initialize the hashtable
$paramTable = @{}

# Create hashtable of data returned in var $response & Iterate over each parameter in the response value
foreach ($param in $response.value) {
    if ($null -ne $param.ParameterName) {
        # Check if the current parameter is 'list_role' or 'Environment'
        if ($param.ParameterName -eq 'list_role' -or $param.ParameterName -eq 'Environment') {
            # Split the value and assign it as an array
            $paramTable[$param.ParameterName] = $param.ParameterValue -split '~\^'
        } else {
            # For all other parameters, assign the value directly
            $paramTable[$param.ParameterName] = $param.ParameterValue
        }
    } else {
        # Warning for null parameter names
        Write-Warning "A parameter with a null name was encountered and will be skipped."
    }
}

$rolesArray = @()
if ($paramTable.ContainsKey('list_role') -and $paramTable['list_role'] -ne $null) {
    $rolesArray = $paramTable['list_role']
}

$environmentArray = @()
if ($paramTable.ContainsKey('Environment') -and $paramTable['Environment'] -ne $null) {
    $environmentArray = $paramTable['Environment']
}

if ($rolesArray.Count -eq 0) {
    Write-Host "The API response for this service ticket doesn't contain access groups, Please manually assign them via the GUI." -ForegroundColor Darkyellow
}

# Check for specific roles and assign boolean values
$hasVFE = $rolesArray -contains "VFE"
$hasValueBlue = $rolesArray -contains "Value Blue"
$hasClaims = $rolesArray -contains "Claims"

# Perform AD lookup for the value assigned to 'combo_Employee'
# Retrieve the username from the combo_Employee value
$username = $paramTable.combo_1

# Strip "@ams.nz" from the username
$strippedUsername = $username.Replace("@ams.nz", "")

try {
    # Retrieve the user object from Active Directory
    $userObject = Get-ADUser -Identity $strippedUsername -Properties EmailAddress, DistinguishedName

    # Retrieve the user's email address
    $externalEmail = $userObject.EmailAddress

    # Update the combo_Employee value in the parameter table with the retrieved email address
    $paramTable.combo_Employee = $externalEmail

    # Split the DistinguishedName by comma and retrieve the value after "OU=User Accounts,"
    $distinguishedNameParts = $userObject.DistinguishedName.Split(',')
    $userOUIndex = $distinguishedNameParts.IndexOf('OU=User Accounts') + 1
    if ($userOUIndex -ge 0 -and $userOUIndex -lt $distinguishedNameParts.Count) {
        $userOU = $distinguishedNameParts[$userOUIndex].Split('=')[1]
    }
    else {
        $userOU = $null
    }

    # Assign the user's OU to a variable
    $userOUVariable = $userOU
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    # User not found in Active Directory
    Write-Warning "User '$strippedUsername' not found in Active Directory. Setting combo_Employee to `$null."
    $paramTable.combo_1 = $null
}
catch {
    # Handle any other errors that may occur
    Write-Error "An error occurred while retrieving user information from Active Directory: $_"
    $paramTable.combo_1 = $null
}
Write-Output $paramTable | Format-List

# ... [Previous code remains unchanged] ...

$customObject = [PSCustomObject]@{
    Email        = if ($paramTable["text_email"]) { $paramTable["text_email"].Trim() } else { $null }
    LastName     = if ($paramTable["LastName"]) { $paramTable["LastName"].Trim() } else { $null }
    FirstName    = if ($paramTable["FirstName"]) { $paramTable["FirstName"].Trim() } else { $null }
    Title        = if ($paramTable["Title"]) { $paramTable["Title"].Trim() } else { $null }
    MobileNumber = if ($paramTable["text_mobile"]) { $paramTable["text_mobile"].Trim() } else { $null }
    ListRole     = if ($paramTable["list_role"]) { $paramTable["list_role"] } else { $null }
    Company      = if ($paramTable["text_company"]) { $paramTable["text_company"].Trim() } else { $null }
    TicketRaiser = if ($paramTable["combo_Employee"]) { $paramTable["combo_Employee"].Trim() } else { $null }
    Environment  = if ($paramTable["Environment"]) { $paramTable["Environment"] } else { @("TRN", "QA", "TST", "Dev") }
    UserOU       = $userOUVariable
    VFE          = $hasVFE
    Claims       = $hasClaims
    ValueBlue    = $hasValueBlue
    Clmsm1       = $rolesArray -contains "g-prd-clmsm1-nib"
    Clmsm2       = $rolesArray -contains "g-prd-clmsm2-nib"
    Clmsop       = $rolesArray -contains "g-prd-clmsop-nib"
    Clmsuw       = $rolesArray -contains "g-prd-clmsuw-nib"
    ISMHosted    = $rolesArray -contains "Support Portal Hosted"
    ISMPortalManager = $rolesArray -contains "Support Portal Manager"
}

return $customObject
$sourceUser = "sourceusername"
$targetUser = "targetusername"

# Get the groups for the source user
$sourceUserGroups = Get-ADPrincipalGroupMembership -Identity $sourceUser | Select-Object -ExpandProperty Name

# Add the source user's groups to the target user
foreach ($group in $sourceUserGroups) {
    Add-ADGroupMember -Identity $group -Members $targetUser
}

Write-Host "Finished copying groups from $sourceUser to $targetUser."

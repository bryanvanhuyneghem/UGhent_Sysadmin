# Student: Bryan Van Huyneghem

# Add the following AD groups.
# New-ADGroup "Employees" -GroupScope global -DisplayName "personeel"
# New-ADGroup "Students" -GroupScope global -DisplayName "studenten"
# New-ADGroup "Printers" -GroupScope global -DisplayName "printers"
# New-ADOrganizationalUnit 'hrimport'
$adRemoveWhitelist = @( "Students", "Employees", "Printers" )

$employees = Import-Csv -Path $Home\Documents\lab5_hrexport.csv -Delimiter ';'
$users_added = @()
$users_updated = @()
$users_disabled = @()
$users_enabled = @()
$users_error = @()

foreach ($employee in $employees) {
    Try {
        # Get the AD User (based on username)
        $username = $employee.gebruikersnaam
        $user = Get-ADUser -SearchBase "OU=hrimport,DC=os3,DC=local" -Properties MemberOf -Filter "Name -eq '$username'"
        $appropriate_groups = $employee.groepen.Split(',')
        
        # Check if the AD User exists (based on username)
        if($user){
            # Update the user's fields in the AD based on csv file
            
            # User should not be active, but is active in AD -> disable
            if(($employee.actief -eq 'n') -And $user.Enabled) {
                Write-Output "User $username was disabled."
                $users_disabled += $username # keep track of disabled users
            }
            # User should be active, but is not active in AD -> enable
            if(($employee.actief -eq 'y') -And !$user.Enabled) {
                Write-Output "User $username was enabled."
                $users_enabled += $username # keep track of enabled users
            }
            Set-ADUser -Identity $user -EmailAddress $employee."e-mail" -EmployeeNumber $employee.nummer `
                -GivenName $employee.voornaam -Surname $employee.achternaam -Enabled $($employee.actief -eq 'y')
            $users_updated += $username # keep track of updated users
            Write-Output "User $username was updated in AD."
            # Assign user to groups listed in csv and unassign user from groups not listed in csv
            # Groups the user should be added to
            foreach ($group in $appropriate_groups) {
                $grp = Get-ADGroup -Filter "DisplayName -eq '$group'"
                $displayname = $grp.Name
                if(!($user.MemberOf.Contains($grp.DistinguishedName))) {
                    # User is not a member of a group he should be a member of; add him
                    Add-ADGroupMember -Identity $grp -Members $user.Name
                    Write-Output "User $username was added in $displayname."
                } else {
                    Write-Output "User $username was already in $displayname."
                }
            }
            # Groups the user should be removed from
            foreach ($group in $user.MemberOf) {
                $grp = Get-ADGroup -Identity $group -Properties DisplayName
                if(!($appropriate_groups.Contains($grp.DisplayName))) {
                    if($adRemoveWhitelist.Contains($grp.Name)) {
                        # User is member of a group he should not be a member of and the group is in the whitelist
                        $username = $user.Name
                        $removed_group = $grp.DisplayName
                        Write-Output "Removed $username from $removed_group."
                        Remove-ADGroupMember -Identity $grp -Members $user.Name -Confirm $false
                    } else {
                        # Group is not in whitelist
                        $group_name = $grp.Name
                        Write-Output "User $username was not removed from $group_name because the AD group is not on the whitelist."
                    }
                }
            }
        } else{
            # The user does not exist; CREATE an AD account
            $username = $employee.gebruikersnaam
            Write-Output "User $username does not exist. Adding user."
            $newUserParams = @{
                Name = $employee.gebruikersnaam
                EmailAddress = $employee."e-mail"
                EmployeeNumber = $employee.nummer
                GivenName = $employee.voornaam
                Surname = $employee.achternaam
                Enabled = $employee.actief -eq 'y'
                AccountPassword = $(ConvertTo-SecureString "dfskljDDdfsdfskljdfshkldfshkl74507$" -AsPlainText -Force)
                ChangePasswordAtLogon = $true
                Confirm = $false
                Path = "OU=hrimport,DC=os3,DC=local"
            }
            
            New-ADUser @newUserParams
            $users_added += $username # keep track of users added

            # Add user to the appropriate group
            foreach ($group in $appropriate_groups) {
                $grp = Get-ADGroup -Filter "DisplayName -eq '$group'"
                Add-ADGroupMember -Identity $grp -Members $employee.gebruikersnaam
            }
            
        }
    }
    # Write out the errors as requested in document: "exception message along with the account name"
    Catch {
        $username = $employee.gebruikersnaam
        $users_error += "$username $_"
    }
}

Write-Output "-------------------------------------------"
Write-Output "The following users were added:"
foreach ($user in $users_added) {
    Write-Output $user
}
Write-Output "-------------------------------------------"
Write-Output "The following users were updated:"
foreach ($user in $users_updated) {
    Write-Output $user
}
Write-Output "-------------------------------------------"
Write-Output "The following users were disabled:"
foreach ($user in $users_disabled) {
    Write-Output $user
}
Write-Output "-------------------------------------------"
Write-Output "The following users were enabled:"
foreach ($user in $users_enabled) {
    Write-Output $user
}
Write-Output "-------------------------------------------"
Write-Output "The following records had an error:"
foreach ($user in $users_error) {
    Write-Output $user
}



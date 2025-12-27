<#
./SYNOPSIS:

    Write a script that scans through all users on the system and 
    identifies those who haven't logged in within 180 days.


./DESCRIPTION:
    
    This script scans through all Active Directory users and identifies those who have not logged in for a specified number of days.
    Inactive user accounts are then disabled to enhance security.
    $DaysInactive = desired number of max days a user is allowed to be inactive before disabling the account.
    This script will also create a .csv file of all the accounts disabled. 


./PARAMETER:

    DaysInactive: Number of days a user can be inactive before being disabled. Default is 180 days.
    This parameter can be changed to suit different requirements.

./EXAMPLE:

    .\Disable_InactiveUsers.ps1

    No parameters are passed, so the script uses the default of 180 days.

./NOTE:

    Code was developed on a VM with Windows Server. 
    Further testing may be required to ensure that accounts are disabled.

#>

Import-Module ActiveDirectory

param(
    [int]$DaysInactive = 180
)


# Calculate cutoff date
$CutoffDate = (Get-Date).AddDays(-$DaysInactive)


Write-Host "Searching for users inactive since before $CutoffDate ..." -ForegroundColor Green


#Get users whose last logon timestamp is older than cutoff
$InactiveUsers = Get-ADUser -Filter * -Properties LastlogonDate, Enable |
    Where-Object{
        $_.Enable -eq $true -and(
            # No login ever recorded or last logon older than cutoff
            ($_.LastLogonDate -eq $null) -or
            ($_.LastlogonDate -lt $CutoffDate)
        )
    }

# In case no inactive users are found
if ($InactiveUsers.Count -eq 0){
    Write-Host "No inactive users found." -ForegroundColor Green
    return
}

Write-Host "Found $($InactiveUsers.Count) inactive users. Disabling accounts..." -ForegroundColor Green

# Disable User Accounts
foreach($user in $InactiveUsers){
    Disable-ADAccount -Identity $user.SamAccountName
}

# Prepare / layout for csv file
$Report = $InactiveUsers | Select-Object SamAccountName, Name, LastLogonDate
# Name CSV file
$OutputPath = "InactiveUsersDisabled.csv"
# Export CSV file
$Report | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "Inactive users disabled and report saved to $OutputPath" -ForegroundColor Green
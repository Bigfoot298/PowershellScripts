$email = Read-Host -prompt "Email address of User leaving"

$session = New-PSSession -ComputerName eg-dc-01 
Invoke-Command -Session $session -ArgumentList $email -ScriptBlock {
	param($email)

$User = (get-aduser -filter {EmailAddress -eq $email}).SamAccountName
$UPN = (get-aduser -filter {EmailAddress -eq $email}).UserPrincipalName

#Disable User

Disable-ADAccount -Identity $user

#remove all groups 

Get-AdPrincipalGroupMembership -Identity $user | Where-Object -Property Name -Ne -Value 'Domain Users' | Remove-AdGroupMember -Members $user

#set attributes mailnick and hiddenfromgal

Set-ADUser -Identity $user -Replace @{MailNickName = "$UPN"}

Set-ADUser -identity $user -Replace @{msExchHideFromAddressLists=$true}

#move to oldusers OU

get-aduser -identity $User | Move-ADObject -TargetPath "OU=Old Users,OU=Users,OU=ENTERPRISE,DC=enterprise,DC=local"
}

remove-pssession -session $session


$session2 = New-PSSession -ComputerName ef-srv-02 
Invoke-Command -Session $session2 -ScriptBlock {Start-ADSyncSyncCycle}

remove-pssession -session $session2


#exch online

connect-exchangeonline

#mailbox access?

$answer = Read-Host -prompt "Is mailbox access required, Y/N?"

If ($answer -eq 'Y')
{
$access = Read-Host -prompt "Exact email address of the user wanting permissions"


Add-MailboxPermission -Identity $Email -User $access -AccessRights FullAccess -InheritanceType All
}

#mail forward?

$answer2 = Read-Host -prompt "Is mail forward needed, Y/N?"
If ($answer2 -eq 'Y')
{

$forward = Read-Host -prompt "Exact email address of the user emails are forwarding to"

Set-Mailbox -Identity $email -forwardingsmtpaddress $forward

}



#convert mailbox to shared

Set-Mailbox $email -Type Shared

#remove enra specialist finance

Remove-UnifiedGroupLinks -Identity "EnraGroup1@enterprisefinance.co.uk" -LinkType Members -Links $email

#remove cloud groups 

Connect-AzureAD

$userid = (Get-AzureADuser -objectid $email).objectid

$Groups = Get-AzureADUserMembership -ObjectId $userID 

foreach($Group in $Groups){ 
   
        Remove-AzureADGroupMember -ObjectId $Group.ObjectID -MemberId $userID -erroraction Stop 
    }


connect-msolservice

(get-MsolUser -UserPrincipalName $email).licenses.AccountSkuId |
foreach{
    Set-MsolUserLicense -UserPrincipalName $email -RemoveLicenses $_
}

#open papercut, horizon and business systems 

[system.Diagnostics.Process]::Start("chrome","http://10.0.0.12:9191/app")
[system.Diagnostics.Process]::Start("chrome","https://www.unlimitedhorizon.co.uk/webapp/signin")

[system.Diagnostics.Process]::Start("chrome","https://www.google.com")
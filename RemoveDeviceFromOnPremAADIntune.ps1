$Computer = read-host -prompt 'Computer Name'

$session = New-PSSession -ComputerName eg-dc-01 
Invoke-Command -Session $session -ArgumentList $Computer -ScriptBlock {
	param($Computer)


Get-ADComputer -Identity $Computer | Remove-ADObject -Recursive

}
remove-pssession -session $session


$session2 = New-PSSession -ComputerName ef-srv-02 

Invoke-Command -Session $session2 -ScriptBlock {Start-ADSyncSyncCycle}

remove-pssession -session $session2


connect-msgraph


$IntuneDevice = Get-IntuneManagedDevice –Filter "deviceName eq '$Computer'"

Remove-IntuneManagedDevice –managedDeviceId $IntuneDevice.Id
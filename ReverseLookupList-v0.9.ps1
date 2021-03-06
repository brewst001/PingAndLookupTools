<#
****------------- Script Information -------------****
Brief			:	Reverse lookup a list of computers
Function		:	Reverse lookup a list of "computers" in a text file. Write the results to the screen and a .csv file.
Author  		:	Mike Yurick
Website			:	www.mikeyurick.com
Twitter			:	@mikeyurick
Version			:	v1.0
Last Updated	:	09/23/2015
Prerequisites	:	Create a text file called "ReverseLookupListToSearch.txt"
Options			:	None
Usage			:	Populate the .txt file with Hostnames, IPs, FQDN's, and/or Domain Names with one on each line and run the script.
License 		:	Free for personal use and shareable if you keep this Script information section and commenting in tact.
Warranty		:	No warranties expressed or implied.
Warnings		:	Use at your own risk. Understand the code before running.
Known Bugs		:	
Testing	notes	:	
Future Features	:	Add a switch to disable the .csv file
Version History	:	2015-09-23 - v1.0 - Enhanced the .csv file, verified functionality. Initial release.
					2010-05-24 - v0.8 - Basic functionality in place
					2010-05-20 - v0.1 - Basing off of ping script
****------------- End Script Information -------------****
#>

#----Variable Declaration and cleanup ---
$Script:ComputerNameorIP = $null

[int]$Script:RunCountTotal = 0
[int]$Script:RunCountSuccess = 0
[int]$Script:RunCountFailure = 0
#-----------------------------------------

$timestamp = (Get-Date).ToString('yyyy') + "-" + (Get-Date).ToString('MM') + "-" + (Get-Date).ToString('dd') + "@" + (Get-Date).ToString('HHmmss')
$reverselookuplogfile = New-Item -ItemType file RevereseLookupResultsLog--$timestamp.csv
$StopWatch = New-Object system.Diagnostics.Stopwatch
$StopWatch.Start()
$now = Get-Date

[char]13
Write-Host "Beginning Reverse Lookup..."
Add-Content $reverselookuplogfile "Reverse Lookup List of addresses in ReverseLookupListToSearch.txt"
Add-Content $reverselookuplogfile "Start time:,$now"
Add-Content $reverselookuplogfile ""
Add-Content $reverselookuplogfile "Name or IP,Result,Extended Error"
[char]13

$Script:ErrorMessage = $null

Function ReverseLookup ([string]$FcnComputerNameorIP)
{
	PROCESS
	{
		$Script:RunCountTotal++
		$char1and2 = $null
		$char3 = $null
		$Script:ErrorMessage = $null

		#trap [System.Management.Automation.MethodInvocationException] #Only traps this type
		trap
		{
			$Script:ErrorMessage = $_
			$Script:ErrorMessage = $Script:ErrorMessage -replace(",","")
			Write-Host "$Script:ComputerNameorIP :: $Script:ErrorMessage" -Foregroundcolor Red
			Add-Content $reverselookuplogfile "$Script:ComputerNameorIP,Error,$Script:ErrorMessage"
			$Script:RunCountFailure++
			Continue
		}
		
		[reflection.assembly]::LoadWithPartialName("'Microsoft.VisualBasic") | Out-Null
		$char1and2 = $Script:ComputerNameorIP.substring(0,2) #(x,y) x is first char y is how many
		$char3 = $Script:ComputerNameorIP.substring(2,1)
		
		If ([Microsoft.VisualBasic.Information]::isnumeric($char1and2))
		{
			If ([Microsoft.VisualBasic.Information]::isnumeric($char3) -or $char3 -eq ".")
			{			
				$result = [System.Net.Dns]::GetHostbyAddress("$Script:ComputerNameorIP")
				If ($Script:ErrorMessage -eq $null -or $Script:ErrorMessage -eq "")
				{
					$ResultHostName = $result.HostName
					Write-Host "$Script:ComputerNameorIP :: $ResultHostName"
					Add-Content $reverselookuplogfile "$Script:ComputerNameorIP,$ResultHostName"
					$Script:RunCountSuccess++
				}
			} else {
				Write-Host "$Script:ComputerNameorIP :: Unknown IP Value" -Foregroundcolor Red
				Add-Content $reverselookuplogfile "$Script:ComputerNameorIP,Unknown IP Type"
				$Script:RunCountFailure++
			}	
		} else {
			$ResultIP = [System.Net.Dns]::GetHostAddresses("$Script:ComputerNameorIP")
			If ($Script:ErrorMessage -eq $null -or $Script:ErrorMessage -eq "")
			{
				Write-Host "$Script:ComputerNameorIP :: $ResultIP"
				Add-Content $reverselookuplogfile "$Script:ComputerNameorIP,$ResultIP"		
				$Script:RunCountSuccess++
			} else {
				Write-Host "$Script:ComputerNameorIP :: Unknown Hostname Value" -Foregroundcolor Red
				Add-Content $reverselookuplogfile "$Script:ComputerNameorIP,Unknown Hostname Value"
				$Script:RunCountFailure++				
			}
		}
	}
}


#Process the text file one line at a time
get-content ReverseLookupListToSearch.txt | foreach {
	$Script:ComputerNameorIP = $_
	ReverseLookup $Script:ComputerNameorIP
}

[char]13
$StopWatch.Stop()
$ts = $StopWatch.Elapsed
$ElapsedTime = [system.String]::Format("{0:00}:{1:00}:{2:00}.{3:00}", $ts.Hours, $ts.Minutes, $ts.Seconds, $ts.Milliseconds / 10)
Add-Content $reverselookuplogfile ""
Add-Content $reverselookuplogfile "Total Computers Processed:,$Script:RunCountTotal"
Add-Content $reverselookuplogfile "Computers Up:,$Script:RunCountSuccess"
Add-Content $reverselookuplogfile "Computers Down:,$Script:RunCountFailure"
$now = Get-Date
Add-Content $reverselookuplogfile "End time:,$now"
Add-Content $reverselookuplogfile "Total time to run:,$ElapsedTime"
$TimePerRun = ($ts.TotalSeconds / $Script:RunCountTotal)
$TimePerRun = [Math]::Round($TimePerRun,3)
Add-Content $reverselookuplogfile "Average seconds per computer:,$TimePerRun"
[char]13
Write-Host "Processing Complete! Ran $Script:RunCountTotal times with $Script:RunCountFailure failure(s)."
Write-Host "Took $ElapsedTime to complete."
Write-Host "Averaged $TimePerRun seconds per computer."
Write-Host "Log file saved as: $reverselookuplogfile"
[char]13
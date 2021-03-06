<#
****------------- Script Information -------------****
Brief			:	Ping a list of computers
Function		:	Ping a list of "computers" from a text file. Write the results to the screen and a .csv file.
Author  		:	Mike Yurick
Website			:	www.mikeyurick.com
Twitter			:	@mikeyurick
Version			:	v1.0
Last Updated	:	09/23/2015
Prerequisites	:	Create a text file called "PingListToSearch.txt"
Options			:	None
Usage			:	Populate the .txt file with Hostnames, IPs, FQDN's, and/or Domain Names with one on each line and run the script.
License 		:	Free for personal use and shareable if you keep this Script information section and commenting in tact.
Warranty		:	No warranties expressed or implied.
Warnings		:	Use at your own risk. Understand the code before running.
Known Bugs		:	
Testing	notes	:	
Future Features	:	Add a switch to disable the .csv file
Version History	:	2015-09-23 - v1.0 - Enhanced the .csv file, verified functionality. Initial release.
					2010-05-19 - v0.9 - adding time stamp, timer, and counters - added timed out state
					2010-05-17 - v0.8 - basic functionality in place
****------------- End Script Information -------------****
#>

#----Variable Declaration and cleanup ---
$Script:ComputerName = $null

[int]$Script:RunCountTotal = 0
[int]$Script:RunCountSuccess = 0
[int]$Script:RunCountFailure = 0
#-----------------------------------------

$timestamp = (Get-Date).ToString('yyyy') + "-" + (Get-Date).ToString('MM') + "-" + (Get-Date).ToString('dd') + "@" + (Get-Date).ToString('HHmmss')
$pinglogfile = New-Item -ItemType file PingResultsLog--$timestamp.csv
$StopWatch = New-Object system.Diagnostics.Stopwatch
$StopWatch.Start()
$now = Get-Date

[char]13
Write-Host "Beginning Ping Check..."
Add-Content $pinglogfile "Ping List of Addresses in PingListToSearch.txt"
Add-Content $pinglogfile "Start time:,$now"
Add-Content $pinglogfile ""
Add-Content $pinglogfile "Hostname,Ping Status"
[char]13


Function Ping-Host ([string]$FcnComputerName)
{
	PROCESS
	{
		$Script:RunCountTotal++
		$errorActionPreference="SilentlyContinue"
		$wmi = get-wmiobject -query “SELECT * FROM Win32_PingStatus WHERE Address = '$Script:ComputerName'"
		$PingStatus = $wmi.StatusCode
		if ($PingStatus -eq 0)
		{
			Write-Host "$Script:ComputerName	:	Online"
			Add-Content $pinglogfile "$Script:ComputerName,Online"
			$Script:RunCountSuccess++
		} elseif ($PingStatus -eq 11003) {
			Write-Host "$Script:ComputerName	:	Offline"
			Add-Content $pinglogfile "$Script:ComputerName,Offline"
			$Script:RunCountFailure++
		} elseif ($PingStatus -eq 11010) {
			Write-Host "$Script:ComputerName	:	Timed Out"
			Add-Content $pinglogfile "$Script:ComputerName,Timed Out"
			$Script:RunCountFailure++
		} elseif ($PingStatus -eq "" -or $PingStatus -eq $null) {
			Write-Host "$Script:ComputerName	:	FAILED"
			Add-Content $pinglogfile "$Script:ComputerName,FAILED"
			$Script:RunCountFailure++
		} else {
			Write-Host "$Script:ComputerName	:	In unknown state: $PingStatus"
			Add-Content $pinglogfile "$Script:ComputerName,$PingStatus"
			$Script:RunCountFailure++
		}
	}
}

#Process the text file one line at a time
get-content PingListToSearch.txt | foreach {
	$Script:ComputerName = $_
	Ping-Host $Script:ComputerName
}

$StopWatch.Stop()
$ts = $StopWatch.Elapsed
$ElapsedTime = [system.String]::Format("{0:00}:{1:00}:{2:00}.{3:00}", $ts.Hours, $ts.Minutes, $ts.Seconds, $ts.Milliseconds / 10)
Add-Content $pinglogfile ""
Add-Content $pinglogfile "Total Computers Processed:,$Script:RunCountTotal"
Add-Content $pinglogfile "Computers Up:,$Script:RunCountSuccess"
Add-Content $pinglogfile "Computers Down:,$Script:RunCountFailure"
$now = Get-Date
Add-Content $pinglogfile "End time:,$now"
Add-Content $pinglogfile "Total time to run:,$ElapsedTime"
$TimePerRun = ($ts.TotalSeconds / $Script:RunCountTotal)
$TimePerRun = [Math]::Round($TimePerRun,3)
Add-Content $pinglogfile "Average seconds per Computer:,$TimePerRun"
[char]13
Write-Host "Processing Complete! Ran $Script:RunCountTotal times with $Script:RunCountFailure failure(s)."
Write-Host "Took $ElapsedTime to complete."
Write-Host "Averaged $TimePerRun seconds per computer."
Write-Host "Log file saved as: $pinglogfile"
[char]13
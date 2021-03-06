<#
****------------- Script Information -------------****
Brief			:	Ping and Reverse Lookup a list of computers
Function		:	Ping and Reverse lookup a list of "computers" in a text file. Write the results to the screen and an Excel file.
Author  		:	Mike Yurick
Website			:	www.mikeyurick.com
Twitter			:	@mikeyurick
Version			:	v1.0
Last Updated	:	09/23/2015
Prerequisites	:	Create a text file called "PingAndReverseLookupListToSearch.txt"
Options			:	None
Usage			:	Populate the .txt file with Hostnames, IPs, FQDN's, and/or Domain Names with one on each line and run the script.
License 		:	Free for personal use and shareable if you keep this Script information section and commenting in tact.
Warranty		:	No warranties expressed or implied.
Warnings		:	Use at your own risk. Understand the code before running.
Known Bugs		:	
Testing	notes	:	
Future Features	:	Add switches to toggle the Excel file and the closing of Excel
Version History	:	2015-09-23 - v1.0	- Initial release. Fixed some issues with the Excel output. Disabled closing Excel by default.
					2010-07-22 - v0.9	- Adding Excel Capabilities
					2010-07-21 - v0.8	- Combining Ping and Reverse Lookup scripts basic functionality in place
****------------- End Script Information -------------****
#>

#------USER VARIABLES-------------

$path = "C:\Log Directory\" #Modify this line as needed
#Future - Toggle Excel Options

#----End User Vars------------------

#----Variable Declaration and Cleanup ---
$Script:ComputerNameorIP = $null

[int]$Script:RunCountTotal = 0
[int]$Script:RunCountSuccess = 0
[int]$Script:RunCountFailure = 0
#-----------------------------------------

[char]13
#The Excel closing feature is disabled by defualt. Re-enable this warning if you kill the Excel process at the end!
#Write-Host "|xXx----------------------------------------------------------------xXx|"
#Write-Host "|       WARNING: THIS SCRIPT KILLS ITS EXCEL PROCESS WHEN DONE         |"
#Write-Host "|xXx----------------------------------------------------------------xXx|"

$timestamp = (Get-Date).ToString('yyyy') + "-" + (Get-Date).ToString('MM') + "-" + (Get-Date).ToString('dd') + "@" + (Get-Date).ToString('HHmmss')
$filename = "PingAndReverseLookupResultsLog--" + $timestamp +".xls"
$pathandfile = $path + $filename

$before = @(Get-Process [e]xcel | %{$_.Id})
$XL = New-Object -comobject Excel.Application
$ExcelId = Get-Process excel | %{$_.Id} | ?{$before -notcontains $_}
#$XL.Visible = $false #If you don't want to see Excel open, uncomment this line
$XL.Visible = $true #If you want Excel to be opened and visible, uncomment this line

$wrkbk = $XL.Workbooks.Add()
$wrksht1 = $XL.Worksheets.Item(1)

$intRow = 1

$now = Get-Date
$wrksht1.Cells.Item($intRow,2) = "Ping and Resolve items in PingAndReverseLookupListToSearch.txt"
$wrksht1.Range("B1:D1").MergeCells = $true
$wrksht1.Range("B1:D1").Font.Bold = $true
$intRow++
$wrksht1.Cells.Item($intRow,2) = "Start time:"
$wrksht1.Cells.Item($intRow,3) = "$now"
$intRow++
$intRow++

$wrksht1.Cells.Item($intRow,1) = "#"
$wrksht1.Cells.Item($intRow,2) = "Input Name/IP"
$wrksht1.Cells.Item($intRow,3) = "Ping Status"
$wrksht1.Cells.Item($intRow,4) = "Resolved To"
$intRow++

$TableHeader = $wrksht1.Range("A4:D4")
$TableHeader.Interior.ColorIndex = 23
$TableHeader.Font.ColorIndex = 2
$TableHeader.Font.Bold = $True
$TableHeader.Font.Size = 12
$TableHeader.HorizontalAlignment = -4108 #-4108 = centered

#[Void]$TableHeader.EntireColumn.AutoFit()

$StopWatch = New-Object system.Diagnostics.Stopwatch
$StopWatch.Start()

[char]13
Write-Host "Beginning Ping and Reverse Lookup..."
[char]13

Function Ping-Host ([string]$FcnComputerName)
{
	PROCESS
	{
		$errorActionPreference="SilentlyContinue"
		$wmi = get-wmiobject -query “SELECT * FROM Win32_PingStatus WHERE Address = '$Script:ComputerNameorIP'"
		$PingStatus = $wmi.StatusCode
		if ($PingStatus -eq 0)
		{
			Write-Host "$Script:ComputerNameorIP	:	Online" -NoNewline
			$wrksht1.Cells.Item($intRow,3) = "Online"
			$Script:RunCountSuccess++
		} elseif ($PingStatus -eq 11003) {
			Write-Host "$Script:ComputerNameorIP	:	Offline" -NoNewline
			$wrksht1.Cells.Item($intRow,3) = "Offline"
			$Script:RunCountFailure++
		} elseif ($PingStatus -eq 11010) {
			Write-Host "$Script:ComputerNameorIP	:	Timed Out" -NoNewline
			$wrksht1.Cells.Item($intRow,3) = "Timed Out"
			$Script:RunCountFailure++
		} elseif ($PingStatus -eq "" -or $PingStatus -eq $null) {
			Write-Host "$Script:ComputerNameorIP	:	FAILED" -NoNewline
			$wrksht1.Cells.Item($intRow,3) = "FAILED"
			$Script:RunCountFailure++
		} else {
			Write-Host "$Script:ComputerNameorIP	:	In unknown state: $PingStatus" -NoNewline
			$wrksht1.Cells.Item($intRow,3) = "$PingStatus"
			$Script:RunCountFailure++
		}
	}
}

Function ReverseLookup ([string]$FcnComputerNameorIP)
{
	PROCESS
	{
		$char1and2 = $null
		$char3 = $null
		$Script:ErrorMessage = $null

		#trap [System.Management.Automation.MethodInvocationException] #Only traps this type
		trap
		{
			$Script:ErrorMessage = $_
			$Script:ErrorMessage = $Script:ErrorMessage -replace(",","")
			Write-Host " :: $Script:ErrorMessage" -Foregroundcolor Red
			$wrksht1.Cells.Item($intRow,4) = "$Script:ErrorMessage"
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
					Write-Host " :: $ResultHostName"
					$wrksht1.Cells.Item($intRow,4) = "$ResultHostName"
				}
			} else {
				Write-Host " :: Unknown IP Value" -Foregroundcolor Red
				$wrksht1.Cells.Item($intRow,4) = "Unknown IP Type"
			}	
		} else {
			$ResultIP = [System.Net.Dns]::GetHostAddresses("$Script:ComputerNameorIP")
			If ($Script:ErrorMessage -eq $null -or $Script:ErrorMessage -eq "")
			{
				Write-Host " :: $ResultIP"
				$wrksht1.Cells.Item($intRow,4) = "$ResultIP"
			} else {
				Write-Host " :: Unknown Hostname Value" -Foregroundcolor Red
				$wrksht1.Cells.Item($intRow,4) = "Unknown Hostname Value"
			}
		}
	}
}

get-content PingAndReverseLookupListToSearch.txt | foreach {
	$Script:ComputerNameorIP = $_
	$Script:RunCountTotal++
	$wrksht1.Cells.Item($intRow,1) = "$RunCountTotal"
	$wrksht1.Cells.Item($intRow,2) = "$Script:ComputerNameorIP"
	Ping-Host $Script:ComputerNameorIP
	ReverseLookup $Script:ComputerNameorIP
	If (($RunCountTotal % 2) -eq 0) {
		$hlrange = "A$intRow" + ":" + "D$intRow"
		$hilite = $wrksht1.Range($hlrange)
		$hilite.Interior.ColorIndex = 15
	}
	$intRow++
}

$intRow++

$StopWatch.Stop()
$ts = $StopWatch.Elapsed
$ElapsedTime = [system.String]::Format("{0:00}:{1:00}:{2:00}.{3:00}", $ts.Hours, $ts.Minutes, $ts.Seconds, $ts.Milliseconds / 10)
$wrksht1.Cells.Item($intRow,2) = "Total computers:"
$wrksht1.Cells.Item($intRow,3) = "$Script:RunCountTotal"
$intRow++
$wrksht1.Cells.Item($intRow,2) = "Computers Up:"
$wrksht1.Cells.Item($intRow,3) = "$Script:RunCountSuccess"
$intRow++
$wrksht1.Cells.Item($intRow,2) = "Computers Down:"
$wrksht1.Cells.Item($intRow,3) = "$Script:RunCountFailure"
$intRow++
$varPercentageUp = ($Script:RunCountSuccess / $Script:RunCountTotal)
$wrksht1.Cells.Item($intRow,2) = "Percentage Up:"
$wrksht1.Cells.Item($intRow,3) = "$varPercentageUp"
$wrksht1.Cells.Item($intRow,3).NumberFormat = "0.0%"

$intRow++
$now = Get-Date
$wrksht1.Cells.Item($intRow,2) = "End time:"
$wrksht1.Cells.Item($intRow,3) = "$now"
$intRow++
$wrksht1.Cells.Item($intRow,2) = "Total time to run:"
$wrksht1.Cells.Item($intRow,3) = "$ElapsedTime"
$intRow++
$TimePerRun = ($ts.TotalSeconds / $Script:RunCountTotal)
$TimePerRun = [Math]::Round($TimePerRun,3)
$wrksht1.Cells.Item($intRow,2) = "Avg seconds per computer:"
$wrksht1.Cells.Item($intRow,3) = "$TimePerRun"

$wrksht1.Range("A1:D1").EntireColumn.AutoFit()

[CHAR]13
Write-Host "Processing Complete! Ran $Script:RunCountTotal times with $Script:RunCountFailure failure(s)."
Write-Host "Took $ElapsedTime to complete."
Write-Host "Averaged $TimePerRun seconds per computers."	

#Save the Excelworkbook
$wrkbk.SaveAs($pathandfile, 56)
Write-Host "Log file saved as: $pathandfile"

#The Excel closing features are disabled by defualt. Uncomment the lines below to re-enable it.
#$wrkbk.Close()
#$wrkbk = $null
#try to close Excel nicely
#$XL.Quit()
#[Void][System.Runtime.Interopservices.Marshal]::ReleaseComObject($XL)
#remove-variable XL
#[gc]::collect()
#Re-enable the warning above if you use the following lines to kill excel!
#force associated processes to close
#Stop-Process -Id $ExcelId -Force -ErrorAction SilentlyContinue

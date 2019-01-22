$IoTEdgeArmReleaseFolder = Join-Path $PSScriptRoot "iotedge\edgelet\target\thumbv7a-pc-windows-msvc\release"
$IoTEdgePackageFilePaths = @(
	(Join-Path $IoTEdgeArmReleaseFolder "iotedge.exe"), 
	(Join-Path $IoTEdgeArmReleaseFolder "iotedge.pdb"),
	(Join-Path $IoTEdgeArmReleaseFolder "iotedged.exe"),
	(Join-Path $IoTEdgeArmReleaseFolder "iotedged.pdb"),
	(Join-Path $IoTEdgeArmReleaseFolder "iotedged_eventlog_messages.dll"))

$IoTEdgePackageFilePaths | foreach {
	if (!(Test-Path -Path $_ -PathType leaf)) {
		throw "Can't find $_"
	}
}

$otherPackageFolders = New-Object 'system.collections.generic.dictionary[[string],[object[]]]'
$IoTEdgeContribFolder = Join-Path $PSScriptRoot "iotedge\edgelet\contrib"
$otherPackageFolders.Add((Join-Path $IoTEdgeContribFolder "docs"), @("LICENSE", $true))
$otherPackageFolders.Add((Join-Path $IoTEdgeContribFolder "config\windows"), @("", $false))

foreach ($kvp in $otherPackageFolders.GetEnumerator()) {
	if (!(Test-Path -Path $kvp.Key -PathType container)) {
		throw "Can't find $kvp.Key"
	}
}

$hsmSysFolder = Get-ChildItem (Join-Path $IoTEdgeArmReleaseFolder "build") | Where-Object {$_.PSIsContainer -eq $true -and $_.Name.StartsWith("hsm-sys-") }
if ($hsmSysFolder.GetType().FullName -ne "System.IO.DirectoryInfo")
{
	throw "Can't find hsm-sys folder"
}

$HsmFilePaths = @(
	(Join-Path $hsmSysFolder.FullName "\out\build\Release\iothsm.dll"),
	(Join-Path $hsmSysFolder.FullName "\out\build\Release\LIBEAY32.dll"))

$HsmFilePaths | foreach {
	if (!(Test-Path -Path $_ -PathType leaf)) {
		throw "Can't find $_"
	}
}

try
{
	$packageZipFilename = "iotedged-windows"
	$outputFolder = "iotedged-windows"
	Remove-Item $outputFolder -Recurse -ErrorAction Ignore
	New-Item -ItemType directory -Force -Path $outputFolder > $null

	$IoTEdgePackageFilePaths | foreach {
		Copy-Item $_ $outputFolder
	}

	foreach ($kvp in $otherPackageFolders.GetEnumerator()) {
		$destinationFolder = (Join-Path $outputFolder $kvp.Value[0])
		#Write-Host "key=$kvp.Key, value0=$kvp.Value[0], value1=$kvp.Value[1]"
		if ($kvp.Value[1]) {
			# Copy origin folder to destination folder
			Copy-Item $kvp.Key $destinationFolder -Recurse
		}
		else
		{
			Get-ChildItem $kvp.Key | foreach {
				Copy-Item $_.FullName $destinationFolder -Recurse
			}
		}
	}
	
	$HsmFilePaths | foreach {
		Copy-Item $_ $outputFolder
	}

	Compress-Archive -Path $outputFolder -CompressionLevel Optimal -DestinationPath $packageZipFilename -Force
}
finally
{
	Remove-Item $outputFolder -Recurse -ErrorAction Ignore
}
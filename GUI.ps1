Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
function SetColors($form){
	$isLightMode = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme"
	$form.BackColor = if (-Not $isLightMode) {[System.Drawing.Color]::FromArgb(33, 33, 33)} else {[System.Drawing.SystemColors]::Control}
	$form.ForeColor = if (-Not $isLightMode) {[System.Drawing.SystemColors]::Control} else {[System.Drawing.SystemColors]::WindowText}
}

function Add-Tooltip {
	param (
		[Parameter(Mandatory=$true)]
		[System.Windows.Forms.Control]$Control,

		[Parameter(Mandatory=$true)]
		[string]$Text,
		
		[int]$InitialDelay = 500,
		[int]$PopupDelay = 5000,
		[int]$AutoPopDelay = 10000
	)

	$tooltip = New-Object System.Windows.Forms.ToolTip

	$tooltip.InitialDelay = $InitialDelay
	$tooltip.AutoPopDelay = $AutoPopDelay
	$tooltip.ShowAlways = $true

	$tooltip.SetToolTip($Control, $Text)
}

function Test-IsEmptyFolder {
	param (
		[string]$FolderPath
	)
	
	$items = Get-ChildItem -Path $FolderPath
	
	if ($items.Count -eq 0) {
		return $true
	}
	else {
		return $false
	}
}
function AcceptBox {
	param (
		[string]$MessageText
	)
	
	$result = [System.Windows.Forms.MessageBox]::Show($MessageText, "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
	
	if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
		return $true
	} else {
		return $false
	}
}


$form = New-Object System.Windows.Forms.Form
$form.Text = 'Love2d Packaging Tool'
$form.Size = New-Object System.Drawing.Size(100,100)
$form.StartPosition = 'CenterScreen'
SetColors($form)
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.AutoSize = $true
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle


$iconPath = "icon.ico"
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)








$labelPassword = New-Object System.Windows.Forms.Label
$labelPassword.Location = New-Object System.Drawing.Point(10,680)
$labelPassword.Size = New-Object System.Drawing.Size(280,20)
$labelPassword.Text = 'Enter a password (optional, cabinet file only):'
$form.Controls.Add($labelPassword)

$textBoxPassword = New-Object System.Windows.Forms.TextBox
$textBoxPassword.Location = New-Object System.Drawing.Point(10,700)
$textBoxPassword.Size = New-Object System.Drawing.Size(300,20)
$textBoxPassword.Enabled = $False
Add-Tooltip -Control $textBoxPassword -Text "Create password for your executable and encrypt the files."

$form.Controls.Add($textBoxPassword)




$WinCab_checkbox = New-Object System.Windows.Forms.checkbox
$WinCab_checkbox.Location = New-Object System.Drawing.Point(10,720)
$WinCab_checkbox.Size = New-Object System.Drawing.Size(150,20)
$WinCab_checkbox.Text = "Cabinet file executable"
$WinCab_checkbox.Add_Click({
	$textBoxPassword.Enabled = $WinCab_checkbox.checked
	$HideConsole_checkbox.Enabled = $WinCab_checkbox.checked
})

$form.Controls.Add($WinCab_checkbox)

Add-Tooltip -Control $WinCab_checkbox -Text "Create cabinet file executable with the dll files packed inside.`nThis will make a single exe file that can be run standalone.`nWARNING: Windows defender may flag these occasionally because it counts as an unsigned installer.`nTIP: Uploading to Microsoft store inside an MSIX does not require signing the executable"

$HideConsole_checkbox = New-Object System.Windows.Forms.checkbox
$HideConsole_checkbox.Location = New-Object System.Drawing.Point(10,740)
$HideConsole_checkbox.Size = New-Object System.Drawing.Size(150,20)
$HideConsole_checkbox.Text = "Hide Love Console"
$HideConsole_checkbox.Enabled = $False
$form.Controls.Add($HideConsole_checkbox)

Add-Tooltip -Control $HideConsole_checkbox -Text "Hide the love console when launching the game."

$appDataDir = "$env:APPDATA\love2d-packaging-tool"
$jsonFileName = "love_versions.json"
$localBackupPath = $jsonFileName
$jsonFilePath = Join-Path -Path $appDataDir -ChildPath $jsonFileName

$githubUrl = "https://raw.githubusercontent.com/PhytoEpidemic/love2d-packaging-tool/main/love_versions.json" # Replace with your GitHub URL

if (-not (Test-Path -Path $appDataDir)) {
    New-Item -ItemType Directory -Path $appDataDir | Out-Null
}

function Download-JsonFile {
    $tempFilePath = [System.IO.Path]::GetTempFileName()
	try {
        Invoke-WebRequest -Uri $githubUrl -OutFile $tempFilePath -ErrorAction Stop

        $tempJsonContent = Get-Content -Raw -Path $tempFilePath
        $tempJsonParsed = $tempJsonContent | ConvertFrom-Json

        Copy-Item -Path $tempFilePath -Destination $jsonFilePath -Force
    } catch {
        Write-Host "Failed to download or verify JSON file. Using local backup."
    } finally {
        if (Test-Path -Path $tempFilePath) {
            Remove-Item -Path $tempFilePath -Force
        }
    }
}

Download-JsonFile

if (Test-Path -Path $jsonFilePath) {
    $jsonFileToUse = $jsonFilePath
} elseif (Test-Path -Path $localBackupPath) {
    $jsonFileToUse = $localBackupPath
}

$jsonContent = Get-Content -Raw -Path $jsonFileToUse
$loveVersions = $jsonContent | ConvertFrom-Json



$labelVersionDropdown = New-Object System.Windows.Forms.Label
$labelVersionDropdown.Location = New-Object System.Drawing.Point(200, 745)
$labelVersionDropdown.Size = New-Object System.Drawing.Size(80, 20)
$labelVersionDropdown.Text = 'Version:'
$form.Controls.Add($labelVersionDropdown)

$versionDropDown = New-Object System.Windows.Forms.ComboBox
$versionDropDown.Location = New-Object System.Drawing.Point(200, 770)
$versionDropDown.Size = New-Object System.Drawing.Size(100, 20)
$versionDropDown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

foreach ($version in $loveVersions.versions) {
    $versionDropDown.Items.Add($version.version)
}

$versionDropDown.SelectedIndex = 0
$form.Controls.Add($versionDropDown)

$labelArchitecture = New-Object System.Windows.Forms.Label
$labelArchitecture.Location = New-Object System.Drawing.Point(300, 745)
$labelArchitecture.Size = New-Object System.Drawing.Size(80, 20)
$labelArchitecture.Text = 'Architecture:'
$form.Controls.Add($labelArchitecture)

$archDropDown = New-Object System.Windows.Forms.ComboBox
$archDropDown.Location = New-Object System.Drawing.Point(300, 770)
$archDropDown.Size = New-Object System.Drawing.Size(100, 20)
$archDropDown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($archDropDown)

function Update-ArchitectureDropdown {
    $selectedVersion = $versionDropDown.SelectedItem
    
	$prev_selection = $archDropDown.SelectedIndex
	if ($archDropDown.Items.Count -eq 0) {
		$prev_selection = 0
	}
	$archDropDown.Items.Clear()
    $versionInfo = $loveVersions.versions | Where-Object { $_.version -eq $selectedVersion }
    if ($versionInfo -ne $null) {
        if ($versionInfo.download_links.windows.'64bit' -ne $null) {
            $archDropDown.Items.Add('64bit')
        }
		if ($versionInfo.download_links.windows.'32bit' -ne $null) {
            $archDropDown.Items.Add('32bit')
        }
        
    }

    
    if ($archDropDown.Items.Count -gt $prev_selection) {
        $archDropDown.SelectedIndex = $prev_selection
	} else {
        $archDropDown.SelectedIndex = 0
    }
}

$versionDropDown.add_SelectedIndexChanged({ Update-ArchitectureDropdown })

Update-ArchitectureDropdown

$labelFolderTextBox = New-Object System.Windows.Forms.Label
$labelFolderTextBox.Location = New-Object System.Drawing.Point(10,20)
$labelFolderTextBox.Size = New-Object System.Drawing.Size(280,40)
$labelFolderTextBox.Text = 'Choose the folder containing your game (where main.lua is located) You can drag and drop the folder into the text box.'
$form.Controls.Add($labelFolderTextBox)

$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$selectFolderBtn = New-Object System.Windows.Forms.Button
$selectFolderBtn.Location = New-Object System.Drawing.Point(280,70)
$selectFolderBtn.Size = New-Object System.Drawing.Size(170,23)
$selectFolderBtn.Text = 'Browse'

$form.Controls.Add($selectFolderBtn)

$folderPathTextBox = New-Object System.Windows.Forms.TextBox
$folderPathTextBox.Location = New-Object System.Drawing.Point(10,70)
$folderPathTextBox.Size = New-Object System.Drawing.Size(260,20)
$form.Controls.Add($folderPathTextBox)

$selectFolderBtn.Add_Click({
	if ($folderBrowser.ShowDialog() -eq 'OK') {
		$folderPathTextBox.Text = $folderBrowser.SelectedPath
	}
})

$folderPathTextBox.AllowDrop = $true
$folderPathTextBox.Add_DragEnter({
	if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
		$_.Effect = [Windows.Forms.DragDropEffects]::Link
	} else {
		$_.Effect = [Windows.Forms.DragDropEffects]::None
	}
})

$folderPathTextBox.Add_DragDrop({
	$files = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
	if (Test-Path -Path $files[0] -PathType Container) {
		$folderPathTextBox.Text = $files[0]
	}
})

$create_package_button = New-Object System.Windows.Forms.Button
$create_package_button.Location = New-Object System.Drawing.Point(10,770)
$create_package_button.Size = New-Object System.Drawing.Size(170,23)
$create_package_button.Text = 'Create Package'
$create_package_button.Add_Click({
	$saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
	$saveFileDialog.Filter = 'Executable files (*.exe)|*.exe'
	$selectedFolder = $folderPathTextBox.Text
	if ($selectedFolder -and (Test-Path -Path $selectedFolder) -and $selectedFolder -notmatch '^[a-zA-Z]:\\?$') {
		if ((Test-Path -Path (Join-Path -Path $selectedFolder -ChildPath "main.lua"))) {
			$saveFileDialog.ShowDialog() | Out-Null
		} else {
			[System.Windows.Forms.MessageBox]::Show("Please select a valid folder that contains a main.lua file.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
			
		}
	} else {
		[System.Windows.Forms.MessageBox]::Show("Please select a valid folder that is not the root of a drive.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
	}
	
	
	
	if ($saveFileDialog.FileName -ne '') {
		
		$version = $versionDropDown.SelectedItem
		$arch = $archDropDown.SelectedItem

		$versionInfo = $loveVersions.versions | Where-Object { $_.version -eq $version }
		
        if ($arch -eq '32bit') {
            $url = $versionInfo.download_links.windows.'32bit'
        } elseif ($arch -eq '64bit') {
            $url = $versionInfo.download_links.windows.'64bit'
        }
	
		$extractPath = "$env:APPDATA\love2d-packaging-tool\love-$version"
		
		$needs_dowwnload = $False
		
		if ((Test-Path $extractPath)) {
			$loveDir = Get-ChildItem -Path $extractPath | Where-Object { $_.PSIsContainer } | Select-Object -First 1
			$loveExePath = Join-Path -Path $loveDir.FullName -ChildPath "love.exe"
			if (-not (Test-Path $loveExePath)) {
				Remove-Item -Path $extractPath -Force -Recurse
				$needs_dowwnload = $True
			}
		} else {
			$needs_dowwnload = $True
		}
		
		if ($needs_dowwnload) {
			$outputPath = "$env:TEMP\love-$version.zip"
			Invoke-WebRequest -Uri $url -OutFile $outputPath
			
			Expand-Archive -Path $outputPath -DestinationPath $extractPath -Force
			
			Remove-Item -Path $outputPath -Force
		}
		
		$loveDir = Get-ChildItem -Path $extractPath | Where-Object { $_.PSIsContainer } | Select-Object -First 1
		$loveExePath = Join-Path -Path $loveDir.FullName -ChildPath "love.exe"
	
		$zipPath = "$env:TEMP\thelovegame.zip"
		
		$zipArguments = "a -tzip `"$zipPath`" `"$selectedFolder\*`""
		Start-Process 7za.exe -ArgumentList $zipArguments -NoNewWindow -Wait
		
		$outputFolderPath = Split-Path -Path $saveFileDialog.FileName -Parent
		$finalOutputPath = $saveFileDialog.FileName
		$tempBuildPath = "$env:TEMP\love-packager-temp"
		$tempBuildEXEPath = (Join-Path -Path $tempBuildPath -ChildPath (Split-Path -Path $finalOutputPath -Leaf))
		if (-not (Test-Path -Path $tempBuildPath)) {
			New-Item -ItemType Directory -Path $tempBuildPath | Out-Null
		} else {
			Remove-Item -Path $tempBuildPath -Force -Recurse
			New-Item -ItemType Directory -Path $tempBuildPath | Out-Null
			
		}

		cmd /c copy /b "$loveExePath+$zipPath" "$tempBuildEXEPath"
		replace_icon_and_version_info -exePath $tempBuildEXEPath -iconIndex "1"
		
		if ($WinCab_checkbox.checked) {
			Get-ChildItem -Path $loveDir.FullName -Filter "*.dll" | ForEach-Object {
				Copy-Item -Path $_.FullName -Destination $tempBuildPath
			}
			$password = $textBoxPassword.Text
	
			$luaScriptPath = "WinCabPack.lua"
			$luaExePath = ".\lua.exe"
	
			$arguments = ""
			$arguments += "`"$tempBuildEXEPath`" "
			$arguments += "`"$password`" "
			$arguments += "`"$finalOutputPath`" "
			$HideConsole = "0"
			if ($HideConsole_checkbox.checked) {
				$HideConsole = "1"
			}
			$arguments += "`"$HideConsole`""
			Start-Process -FilePath $luaExePath -ArgumentList "$luaScriptPath $arguments" -NoNewWindow -Wait -PassThru
			replace_icon_and_version_info -exePath $finalOutputPath -iconIndex "3000"
		} else {
			$copy_over_dlls = $False
			
			
			if (Test-IsEmptyFolder -FolderPath $outputFolderPath) {
				$copy_over_dlls = $True
			} else {
				$copy_over_dlls = AcceptBox -MessageText ($outputFolderPath + "`nThis folder is not empty.`nAre you sure you want to place the dll files in this folder?")
			}
			if ($copy_over_dlls) {
				Get-ChildItem -Path $loveDir.FullName -Filter "*.dll" | ForEach-Object {
					Copy-Item -Path $_.FullName -Destination $outputFolderPath
				}
			}
			Copy-Item -Path $tempBuildEXEPath -Destination $outputFolderPath
		}
		
		
		Remove-Item -Path $tempBuildPath -Force -Recurse
		Remove-Item -Path $zipPath -Force
		
		if (Test-Path -Path $finalOutputPath) {
			[System.Windows.Forms.MessageBox]::Show("Packaging in done! Output at: $finalOutputPath", "Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)			
		} else {
			[System.Windows.Forms.MessageBox]::Show("Failed!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
		}
	}
	
})


$form.Controls.Add($create_package_button)

function LoadVersionInfo {
	$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$openFileDialog.Filter = 'Executable Files (*.exe)|*.exe|Resource Files (*.rc)|*.rc'
	if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
		$filePath = $openFileDialog.FileName
		$fileExtension = [System.IO.Path]::GetExtension($filePath)

		if ($fileExtension -eq ".exe") {
			$tempRCPath = [System.IO.Path]::GetTempFileName() + ".rc"
			$cmdArgsExtract = "-open `"$filePath`" -save `"$tempRCPath`" -action extract -mask VERSIONINFO,1,"
			$RHPath = "$env:APPDATA\love2d-packaging-tool\RH\ResourceHacker.exe"
			Start-Process -FilePath $RHPath -ArgumentList $cmdArgsExtract -NoNewWindow -Wait
			$filePath = $tempRCPath
		}
		
		$versionInfo = Get-Content -Path $filePath
		foreach ($line in $versionInfo) {
			if ($line -match 'VALUE "([^"]+)", "([^"]+)"') {
				switch ($matches[1]) {
					"CompanyName" { $textBoxCompanyName.Text = $matches[2] }
					"FileDescription" { $textBoxFileDescription.Text = $matches[2] }
					"FileVersion" { $textBoxFileVersion.Text = $matches[2] }
					"InternalName" { $textBoxInternalName.Text = $matches[2] }
					"LegalCopyright" { $textBoxLegalCopyright.Text = $matches[2] }
					"OriginalFilename" { $textBoxOriginalFilename.Text = $matches[2] }
					"ProductName" { $textBoxProductName.Text = $matches[2] }
					"ProductVersion" { $textBoxProductVersion.Text = $matches[2]; $textBoxProductVersion.Text = $matches[2].Replace(" ", "") -replace "\.", "," }
				}
			}
		}

		if ($fileExtension -eq ".exe") {
			Remove-Item -Path $filePath
		}
	}
}






function TruncateAfterThirdComma {
	param(
		[string]$inputString
	)

	$commaCount = 0
	$truncateIndex = 0

	for ($i = 0; $i -lt $inputString.Length; $i++) {	
		if ($inputString[$i] -eq ',') {
			$commaCount++
			if ($commaCount -eq 3) {
				$truncateIndex = $i + 1
				while ($truncateIndex -lt $inputString.Length -and $inputString[$truncateIndex] -match '\d') {
					$truncateIndex++
				}
				break
			}
		}
	}

	if ($truncateIndex -gt 0) {
		return $inputString.Substring(0, $truncateIndex)
	} else {
		return $inputString
	}
}
#Truncate the string at the first character that is not a digit or comma 
function TruncateAtFirstInvalidCharacter {
	param(
		[string]$inputString
	)

	$validChars = '0123456789,'
	$truncateIndex = 0

	for ($i = 0; $i -lt $inputString.Length; $i++) {
		if ($validChars.IndexOf($inputString[$i]) -eq -1) {
			$truncateIndex = $i
			break
		}
	}

	if ($truncateIndex -gt 0) { 
		return $inputString.Substring(0, $truncateIndex)
	} else {
		return $inputString
	}
}


#Ensure #,#,#,# pattern
function EnsurePattern {
	param(
		[string]$inputString
	)
	
	$endsWithComma = $inputString.EndsWith(',')
	
	if ($endsWithComma) {
		$inputString = $inputString.Substring(0, ($inputString.Length - 1))
	}
	
	$parts = $inputString -split ','
	$missingParts = 4 - $parts.Count
	
	for ($i = 0; $i -lt $missingParts; $i++) {
		$parts += "0"
	}
	
	$outputString = $parts -join ','

	return $outputString
}




function addResourceHackerComponent($form) {

$labelIcon = New-Object System.Windows.Forms.Label
$labelIcon.Location = New-Object System.Drawing.Point(10,130)
$labelIcon.Size = New-Object System.Drawing.Size(280,20)
$labelIcon.Text = 'Icon Path:'
$form.Controls.Add($labelIcon)

$Global:textboxIcon = New-Object System.Windows.Forms.TextBox
$textboxIcon.Location = New-Object System.Drawing.Point(10,150)
$textboxIcon.Size = New-Object System.Drawing.Size(260,20)
$form.Controls.Add($textboxIcon)

$buttonBrowseIcon = New-Object System.Windows.Forms.Button
$buttonBrowseIcon.Location = New-Object System.Drawing.Point(280,150)
$buttonBrowseIcon.Size = New-Object System.Drawing.Size(100,20)
$buttonBrowseIcon.Text = 'Browse'
$buttonBrowseIcon.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = 'Icon Files (*.ico)|*.ico|Resource Files (*.exe)|*.exe'
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textboxIcon.Text = $openFileDialog.FileName
    }
})
$form.Controls.Add($buttonBrowseIcon)


function CreateVersionInfoInput($form, $labelText, $position) {
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10, $position)
    $label.Size = New-Object System.Drawing.Size(280, 20)
    $label.Text = $labelText
    $form.Controls.Add($label)
    
    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(10, ($position + 20))
    $textbox.Size = New-Object System.Drawing.Size(370, 20)
    $form.Controls.Add($textbox)
    
    return $textbox
}

$position = 180
$Global:textBoxFileVersion = CreateVersionInfoInput $form 'FILEVERSION (e.g., 1.0.0.1):' $position
$position += 50
$Global:textBoxProductVersion = CreateVersionInfoInput $form 'PRODUCTVERSION (e.g., 1,0,0,1):' $position
$position += 50
$Global:textBoxCompanyName = CreateVersionInfoInput $form 'CompanyName:' $position
$position += 50
$Global:textBoxFileDescription = CreateVersionInfoInput $form 'FileDescription:' $position
$position += 50
$Global:textBoxInternalName = CreateVersionInfoInput $form 'InternalName:' $position
$position += 50
$Global:textBoxLegalCopyright = CreateVersionInfoInput $form 'LegalCopyright:' $position
$position += 50
$Global:textBoxOriginalFilename = CreateVersionInfoInput $form 'OriginalFilename:' $position
$position += 50
$Global:textBoxProductName = CreateVersionInfoInput $form 'ProductName:' $position
$position += 50

$buttonLoadFromFile = New-Object System.Windows.Forms.Button
$buttonLoadFromFile.Location = New-Object System.Drawing.Point(10, $position)
$buttonLoadFromFile.Size = New-Object System.Drawing.Size(370, 30)
$buttonLoadFromFile.Text = 'Load from file'
$buttonLoadFromFile.Add_Click({ LoadVersionInfo })
$form.Controls.Add($buttonLoadFromFile)
$form.Size = New-Object System.Drawing.Size(400, ($position + 150))
}

function replace_icon_and_version_info {
    param (
		[string]$exePath,
		[string]$iconIndex
	)
    $iconPath = $textboxIcon.Text
    $resourceHackerPath = "$env:APPDATA\love2d-packaging-tool\RH\ResourceHacker.exe"
	if (-Not (Test-Path -Path $resourceHackerPath)) {
		return $False
	}
    $SuccessIcon = $False
	$exeTempPath = ($exePath + ".tmp")
	if ($textboxIcon.Text -ne "") {
		
		$fileExtension = [System.IO.Path]::GetExtension($textboxIcon.Text)
		$tempRCPath = $False
        if ($fileExtension -eq ".exe") {
            $tempRCPath = [System.IO.Path]::GetTempFileName() + ".res"
            $cmdArgsExtract = "-open `"$iconPath`" -save `"$tempRCPath`" -action extract -mask ICONGROUP,"
            Start-Process $resourceHackerPath -ArgumentList $cmdArgsExtract -NoNewWindow -Wait
            $iconPath = $tempRCPath
        }
		

		$cmdArgsReplaceIcon = "-open `"$exePath`" -save `"$exeTempPath`" -action addoverwrite -res `"$iconPath`" -mask ICONGROUP"
		if (-Not $tempRCPath) {
			$cmdArgsReplaceIcon = $cmdArgsReplaceIcon + "," + $iconIndex
		}
		Start-Process $resourceHackerPath -ArgumentList $cmdArgsReplaceIcon -NoNewWindow -Wait
		if ($tempRCPath) {
			Remove-Item -Path ($tempRCPath)
		}
		if ((Test-Path -Path $exeTempPath)) {
			
			Remove-Item -Path ($exePath)
			Rename-Item -Path $exeTempPath -NewName $exePath
			if ((Test-Path -Path $exePath)) {
				$SuccessIcon = $True
			}
		}
	}
    
	$versionInfoRCPath = [System.IO.Path]::GetTempFileName() + ".rc"
	$textBoxFileVersionComma = $textBoxFileVersion.Text
	$textBoxFileVersionComma = EnsurePattern -inputString (TruncateAtFirstInvalidCharacter -inputString (TruncateAfterThirdComma -inputString ($textBoxFileVersionComma -replace "\.", ",")))
	$textBoxProductVersionComma = $textBoxProductVersion.Text
	$textBoxProductVersionComma = EnsurePattern -inputString (TruncateAtFirstInvalidCharacter -inputString (TruncateAfterThirdComma -inputString ($textBoxProductVersionComma -replace "\.", ",")))
    $versionInfoContent = @"
1 VERSIONINFO
FILEVERSION $($textBoxFileVersionComma)
PRODUCTVERSION $($textBoxProductVersionComma)
FILEOS 0x40004
FILETYPE 0x1
{
BLOCK "StringFileInfo"
{
    BLOCK "040904B0"
    {
        VALUE "CompanyName", "$($textBoxCompanyName.Text)"
        VALUE "FileDescription", "$($textBoxFileDescription.Text)"
        VALUE "FileVersion", "$($textBoxFileVersion.Text)"
        VALUE "InternalName", "$($textBoxInternalName.Text)"
        VALUE "LegalCopyright", "$($textBoxLegalCopyright.Text)"
        VALUE "OriginalFilename", "$($textBoxOriginalFilename.Text)"
        VALUE "ProductName", "$($textBoxProductName.Text)"
        VALUE "ProductVersion", "$($textBoxProductVersion.Text)"
    }
}

BLOCK "VarFileInfo"
{
	VALUE "Translation", 0x0409 0x04B0  
}
}
"@

    $versionInfoContent | Out-File -FilePath $versionInfoRCPath -Encoding ASCII

    $versionInfoResPath = $versionInfoRCPath.Replace('.rc', '.res')
    $cmdArgsCompile = "-open `"$versionInfoRCPath`" -save `"$versionInfoResPath`" -action compile -log NUL"
    Start-Process $resourceHackerPath -ArgumentList $cmdArgsCompile -NoNewWindow -Wait
    
    $cmdArgsReplaceVersionInfo = "-open `"$exePath`" -save `"$exeTempPath`" -action addoverwrite -res `"$versionInfoResPath`" -mask VERSIONINFO,1,"
    Start-Process $resourceHackerPath -ArgumentList $cmdArgsReplaceVersionInfo -NoNewWindow -Wait
    $Success_Version_Info = $False
	if ((Test-Path -Path $exeTempPath)) {
		Remove-Item -Path ($exePath)
		Rename-Item -Path $exeTempPath -NewName $exePath
		if ((Test-Path -Path $exePath)) {
			$Success_Version_Info = $True
		}
    }
    
	Remove-Item -Path $versionInfoRCPath
    Remove-Item -Path $versionInfoResPath

    
}






function Show-LicenseAgreement {
    param (
        [string]$WindowTitle,
        [string]$Header,
        [string]$LicenseText
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $WindowTitle
    $form.Size = New-Object System.Drawing.Size(500, 400)
    $form.StartPosition = "CenterScreen"
	$form.MaximizeBox = $false
	$form.MinimizeBox = $false
	$form.AutoSize = $true
	$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    
	$headerLabel = New-Object System.Windows.Forms.Label
    $headerLabel.Text = $Header
    $headerLabel.Size = New-Object System.Drawing.Size(480, 20)
    $headerLabel.Location = New-Object System.Drawing.Point(10, 10)
    $form.Controls.Add($headerLabel)

    $licenseTextBox = New-Object System.Windows.Forms.TextBox
    $licenseTextBox.Multiline = $true
    $licenseTextBox.ScrollBars = "Vertical"
    $licenseTextBox.Text = $LicenseText
    $licenseTextBox.Size = New-Object System.Drawing.Size(480, 260)
    $licenseTextBox.Location = New-Object System.Drawing.Point(10, 40)
    $licenseTextBox.ReadOnly = $true
    $form.Controls.Add($licenseTextBox)

    $acceptButton = New-Object System.Windows.Forms.Button
    $acceptButton.Text = "Accept"
    $acceptButton.Size = New-Object System.Drawing.Size(75, 23)
    $acceptButton.Location = New-Object System.Drawing.Point(250, 310)
    $acceptButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($acceptButton)

    $declineButton = New-Object System.Windows.Forms.Button
    $declineButton.Text = "Decline"
    $declineButton.Size = New-Object System.Drawing.Size(75, 23)
    $declineButton.Location = New-Object System.Drawing.Point(350, 310)
    $declineButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($declineButton)

    $result = $form.ShowDialog()

    return $result
}


function DownloadRH($form, $DLButton) {
	$windowTitle = "License Agreement"
	$header = "Please read the following license agreement carefully."
	$licenseText = @"
You are downloading Resource HackerTM from https://www.angusj.com/resourcehacker/

This Resource HackerTM software is released as freeware provided that you agree to the following terms and conditions:

This software is not to be distributed via any website domain or any other media without the prior written approval of the copyright owner.

This software is not to be used in any way to illegally modify software.

DISCLAIMER: A user of this Resource HackerTM software acknowledges that he or she is receiving this software on an "as is" basis and the user is not relying on the accuracy or functionality of the software for any purpose. The user further acknowledges that any use of this software will be at the user's own risk and the copyright owner accepts no responsibility whatsoever arising from the use or application of the software.

"@

	$result = Show-LicenseAgreement -WindowTitle $windowTitle -Header $header -LicenseText $licenseText
	
	if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
		$filePath = "$env:APPDATA\love2d-packaging-tool\RH\ResourceHacker.exe"
		$zipUrl = "https://www.angusj.com/resourcehacker/resource_hacker.zip"
		$destinationFolder = "$env:APPDATA\love2d-packaging-tool\RH"
		$zipFilePath = "$env:TEMP\resource_hacker.zip"
		Invoke-WebRequest -Uri $zipUrl -OutFile $zipFilePath
	
		if (-Not (Test-Path -Path $destinationFolder)) {
			New-Item -ItemType Directory -Path $destinationFolder | Out-Null
		}
	
		Add-Type -AssemblyName System.IO.Compression.FileSystem
		[System.IO.Compression.ZipFile]::ExtractToDirectory($zipFilePath, $destinationFolder)
	
		Remove-Item -Path $zipFilePath
	
		$form.Controls.Remove($DLButton)
		addResourceHackerComponent $form
	}
	
	
}



$filePath = "$env:APPDATA\love2d-packaging-tool\RH\ResourceHacker.exe"

if (-Not (Test-Path -Path $filePath)) {
	$addRHGUIoptions = New-Object System.Windows.Forms.Button
	$addRHGUIoptions.Location = New-Object System.Drawing.Point(10, 180)
	$addRHGUIoptions.Size = New-Object System.Drawing.Size(370, 30)
	$addRHGUIoptions.Text = 'Download ResourceHacker'
	$addRHGUIoptions.Add_Click({ DownloadRH $form $addRHGUIoptions })
	$form.Controls.Add($addRHGUIoptions)
	
} else {
    Write-Host "ResourceHacker.exe already exists."
	addResourceHackerComponent $form
}




$form.ShowDialog()



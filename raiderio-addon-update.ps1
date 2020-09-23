$rio_gh_url = "https://github.com/RaiderIO/raiderio-addon/archive/master.zip"
$rio_gh_api_url = "https://api.github.com/repos/RaiderIO/raiderio-addon/commits"

$ErrorActionPreference = "Stop"
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function ExitScript() {
    Read-Host -Prompt "Press <enter> to exit or close this window"
    exit
}

function Update_RaiderIO() {
    Write-Output "Performing Addon update now to hash: $last_sha"

    $temp_dir = New-Item -Force -Path $env:TEMP -Name "raiderio-db-update" -ItemType "directory"
    $db_zip_file_path = Join-Path -Path $temp_dir.FullName -ChildPath "raiderio-addon-master.zip"

    if ($temp_dir.GetFiles() -or $temp_dir.GetDirectories()) {
        Write-Output "Removing and re-creating existing temp directory: $temp_dir"
        $temp_dir.Delete($True)
        $temp_dir = New-Item -Force -Path $env:TEMP -Name "raiderio-db-update" -ItemType "directory"
    }

    Write-Output "Downloading new database to: $db_zip_file_path"
    try {
        Invoke-WebRequest -uri $rio_gh_url -outfile $db_zip_file_path
    } catch {
        Write-Output "Error downloading source from GitHub: $rio_gh_url"
        $temp_dir.Delete($True)
        return
    }

    Write-Output "Extracting database to temp directory: $temp_dir"
    Expand-Archive -literalpath $db_zip_file_path -destinationpath $temp_dir.FullName

    Write-Output "Building new Addon locally in folder: $temp_dir"
    Set-Location -Path $temp_dir
    Remove-Item -Force $db_zip_file_path
    Rename-Item -Path "raiderio-addon-master" -NewName "RaiderIO"
    Move-Item -Path "RaiderIO\db\RaiderIO_DB_*" -Destination ".\"
    Remove-Item "RaiderIO\*" -Include *.* -Exclude *.lua, *.toc, *.xml
    if (Test-Path "RaiderIO\tools") { Remove-Item -Recurse -Force "RaiderIO\tools" }
    if (Test-Path "RaiderIO\LICENSE") { Remove-Item "RaiderIO\LICENSE" }

    $rio_ad_dir = Join-Path -Path $addons_dir -ChildPath "RaiderIO"
    if (Test-Path $rio_ad_dir) {
        Write-Output "Removing Live AddOn from WoW AddOns directory: $addons_dir"
        Get-ChildItem "$addons_dir\RaiderIO*"
        Remove-Item -Recurse -Force "$addons_dir\RaiderIO*"
    }

    Write-Output "Moving new Addon to AddOns directory: $addons_dir"
    Move-Item -Path "$temp_dir\*" -Destination $addons_dir

    Write-Output "Cleaning up temp directory: $temp_dir"
    $temp_dir.Delete($True)
    Write-Output "`nSuccess! Updated RaiderIO AddOn and Database to hash: $last_sha`n"
}

function Get_Latest_Sha() {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Accept", "application/vnd.github.v3+json")
    try {
        $response = Invoke-RestMethod $rio_gh_api_url -Method 'GET' -Headers $headers
        return $response[0].sha
    } catch {
        return $null
    }
}

Write-Output "`nStarting the RaiderIO AddOn Update on $(Get-Date)`n"

$wow_dir_path = Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "World of Warcraft"
if (Test-Path $wow_dir_path) {
    $wow_dir = Get-Item $wow_dir_path
    Write-Output "Found WoW installation directory: $wow_dir"
} else {
    $wow_folder = New-Object System.Windows.Forms.FolderBrowserDialog
    $wow_folder.Description = "Select your World of Warcraft installation directory..."
    $wow_folder.rootfolder = "MyComputer"

    if ($wow_folder.ShowDialog() -eq "OK") {
        $wow_folder_path += $wow_folder.SelectedPath
    } else {
        Write-Output "No WoW directory selected, please try again."
        ExitScript
    }

    $wow_dir = Get-Item $wow_folder_path
    Write-Output "User selected WoW installation directory: $wow_dir"
}

$addons_dir = Join-Path -Path $wow_dir -ChildPath "_retail_\Interface\AddOns"
if (Test-Path $addons_dir) {
    Write-Output "Found WoW AddOns directory: $addons_dir"
} else {
    Write-Output "Error, WoW AddOns directory not found: $addons_dir"
    ExitScript
}

$last_sha_check = Get_Latest_Sha
if ($last_sha_check -ne $null) {
    $last_sha = $last_sha_check
} else {
    Write-Output "Error checking GitHub API for latest version information."
    Write-Output "Please try re-running the script again at a later time."
    ExitScript
}

Update_RaiderIO

Write-Output "Will check for new updates every 30 minutes. You can leave this running..."

while ($True) {
    Start-Sleep -Seconds 1800
    Write-Host -NoNewline "$(Get-Date) - Checking for update... "
    $new_sha_check = Get_Latest_Sha
    if ($new_sha_check -ne $null) {
        $new_sha = $new_sha_check
    } else {
        Write-Output "Error checking for update, will try again in 30 minutes."
    }
    if ($new_sha -ne $last_sha) {
        $last_sha = $new_sha
        Write-Output "Yes update found: $last_sha"
        Update_RaiderIO
    } else {
        Write-Output "No update found: $last_sha"
    }
}

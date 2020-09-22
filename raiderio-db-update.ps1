$rio_gh_url = "https://github.com/RaiderIO/raiderio-addon/archive/master.zip"
$addons_dir = Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "World of Warcraft\_retail_\Interface\AddOns"

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function ExitScript() {
    Read-Host -Prompt "Press <enter> to exit or close this window"
    exit
}

Write-Output "`nUpdating the database to the latest version from GitHub...`n"
Write-Output "Using source URL: $rio_gh_url"

$rio_ad_dir = Join-Path -Path $addons_dir -ChildPath "RaiderIO"
$rio_db_dir = Join-Path -Path $rio_ad_dir -ChildPath "db"

if (!(Test-Path $rio_ad_dir)) {
    Write-Output "Error, RaiderIO Addon directory not found: $rio_ad_dir"
    ExitScript
}

$temp_dir = New-Item -Force -Path $env:TEMP -Name "raiderio-database-update" -ItemType "directory"
$db_zip_file_path = Join-Path -Path $temp_dir.FullName -ChildPath "raiderio-addon-master.zip"
$db_zip_dir_path = Join-Path -Path $temp_dir.FullName -ChildPath "raiderio-addon-master"
$new_db_path = Join-Path -Path $db_zip_dir_path -ChildPath "db"

if ($temp_dir.GetFiles() -or $temp_dir.GetDirectories()) {
    Write-Output "Removing and re-creating existing temp directory: $temp_dir"
    $temp_dir.Delete($true)
    $temp_dir = New-Item -Force -Path $env:TEMP -Name "raiderio-database-update" -ItemType "directory"
}

Write-Output "Downloading new database to: $db_zip_file_path"
$response = Invoke-WebRequest -uri $rio_gh_url -outfile $db_zip_file_path

Write-Output "Extracting database to temp directory: $temp_dir"
Expand-Archive -literalpath $db_zip_file_path -destinationpath $temp_dir.FullName

Write-Output "Removing destination db directory: $rio_db_dir"
Remove-Item -Recurse -Force $rio_db_dir

Write-Output "Moving new database directory from: $new_db_path"
Move-Item -Force -Path $new_db_path -Destination $rio_db_dir

Write-Output "Cleaning up temp directory: $temp_dir"
$temp_dir.Delete($true)

Write-Output "`nSuccess! Done updating RaiderIO DB...`n"
Read-Host -Prompt "Press <enter> to exit or close this window"

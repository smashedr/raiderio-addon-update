$source_file_name = "raiderio-addon-update.ps1"
$output_file_name = "RaiderIO-AddOn-Update.exe"
$application_name = "RaiderIO AddOn Update"
$author_name = "Shane"

$ErrorActionPreference = "Stop"

if (-Not $args[0]) {
    Write-Output "Specify version number in format x.x.x.x for argument one."
    exit
}
$version = $args[0]

if (Test-Path $output_file_name) {
    Remove-Item -Force $output_file_name
}

.\ps2exe.ps1 `
    -inputFile "..\$source_file_name" `
    -outputFile ".\$output_file_name" `
    -iconFile ".\icon.ico" `
    -title $application_name `
    -description $application_name `
    -product $application_name `
    -company $author_name `
    -copyright $author_name `
    -version $version

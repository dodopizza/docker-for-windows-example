$ipAdress = (Get-NetIPConfiguration).IPv4Address.IPAddress
Write-Host "hello world, I am $($ipAdress)"

$webClient = New-Object System.Net.WebClient

$artifactInfo = $webClient.DownloadString("https://tc.example.com/get-data-url?with-arguments")
Write-Host "I have got artifact info: "
Write-Host $artifactInfo
Write-Host ""

Write-Host "And I gonna download artifact itself"
$artifactInfoXML = [xml]$artifactInfo
Write-Host $artifactInfoXML.build.webUrl
New-Item -ItemType directory -Path "C:\artifacts\"
$webClient.DownloadFile($artifactInfoXML.build.webUrl, "C:\artifacts\artifact.zip")

Write-Host(Get-ChildItem -Path "C:\artifacts")

Expand-Archive "C:\artifacts\artifact.zip" -DestinationPath "C:\unpacked"
Write-Host "There is something inside archive:"
Write-Host(Get-ChildItem -Path "C:\unpacked")

Write-Host "Deployed!"
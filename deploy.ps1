param (
    $UserName,
    $Password,
    $AuthenticationType = "Default",
    $BastionPassword,
    $BastionServer,
    $SiteServers
)

#it is not production-ready ssh tunnel solution. You shoud write your own.
function Start-Plink {
    param(
        $bastionServer,
        $bastionPassword,
        $sshLocalPort,
        $remoteServerIp
    )
    
    [ScriptBlock] $plinkCommand =
    {
        param($bastionPassword_, $sshLocalPort_, $remoteServerIp_, $bastionServer_)
        Write-Output "yes" | plink.exe -v -N -P 22 -pw "${bastionPassword_}" -L 127.0.0.1:${sshLocalPort_}:${remoteServerIp_}:5985 ${bastionServer_} 2>&1 | % { $_.ToString() } > "plink_${remoteIp_}.log"
    }

    Write-Host "SSH tunnel to $($remoteServerIp)"
    $plinkJob = Start-Job -ScriptBlock $plinkCommand -ArgumentList $bastionPassword, $sshLocalPort, $remoteServerIp, $bastionServer
    Start-Sleep -Seconds 5
    return $plinkJob
}

$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$credentials = New-Object -Typename System.Management.Automation.PSCredential -ArgumentList $UserName, $securePassword

ForEach ($siteServer in $SiteServers) {
    Write-Host "-----------------------"
    $plinkJob = Start-Plink $BastionServer $BastionPassword 3366 $siteServer
    $serverSession = New-PSSession -ComputerName "127.0.0.1" -Port 3366 -Credential $credentials -Authentication $AuthenticationType -ErrorAction Stop
    
    Invoke-command -Session $serverSession -FilePath .\deploy_local.ps1
    
    $serverSession | Remove-PSSession
    
    $plinkJob | Remove-Job -Force
    Write-Host "SSH tunnel closed"
}

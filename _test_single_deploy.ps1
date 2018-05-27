$currentDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

docker stop iis_1; docker rm iis_1;
docker stop iis_2; docker rm iis_2;
docker stop bastion_1; docker rm bastion_1;
docker stop build_agent_1; docker rm build_agent_1;

docker run -d --platform windows --name iis_1 jmistx/aspnet-mock-example;
docker run -d --platform windows --name iis_2 jmistx/aspnet-mock-example;
docker run -d --platform windows --name build_agent_1  -v "${currentDirectory}:C:\Users\ContainerAdministrator\Documents\deploy" jmistx/aspnet-mock-example;
docker run -d --platform linux --name bastion_1 -e "SSH_USERPASS=qwerty123" fedora/ssh;

$iis_1_container_ip = docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress}}" iis_1
$iis_2_container_ip = docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress}}" iis_2
$bastion_container_ip = docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress}}" bastion_1

$serverSession = New-PSSession -ContainerId (get-container -Name build_agent_1).ID -RunAsAdministrator

Invoke-Command -Session $serverSession {
    cd deploy
   ./deploy.ps1 -UserName "deploy" -Password "clFjK0INYdAOndE47q" -AuthenticationType "Basic" -BastionPassword "qwerty123" -BastionServer "user@$($using:bastion_container_ip):22" -SiteServers @($using:iis_1_container_ip, $using:iis_2_container_ip)
}  -ErrorAction Stop
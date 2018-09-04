#***************************************************************************************
#
# Using other scripts, this script will initiaite the starting of DSC and build out of SharePoint farm with 
# following configurations:
#
#      - MultiServer farm SP2016
#
# -Run this script as a local server Administrator
# -Run this script from elevated prompt
# 
# Don't forget to: Set-ExecutionPolicy RemoteSigned
#
#
# Author: Krum Haesli
# Created: 21.08.2016
# Modified: 
# Comment:
#
#
#****************************************************************************************

param(
        [string][Parameter(Mandatory=$true)] $ConfigDataFile,
        [string][Parameter(Mandatory=$true)] $ConfigFile
)

New-Item "..\Logs" -ItemType directory -ErrorAction SilentlyContinue

Start-Transcript -Path "..\logs\DSC_SharePoint_Transaction.log" -Append -IncludeInvocationHeader

Get-Date

$ObjModule = Get-Module xPSDesiredStateConfiguration

if($ObjModule.count -le 0)
{
    Install-PackageProvider -Name Nuget -Force -RequiredVersion "2.8.5.201" -Confirm:$false
    Set-PSRepository -Name PSGallery -SourceLocation https://www.powershellgallery.com/api/v2/ -InstallationPolicy Trusted
    Install-Module xPSDesiredStateConfiguration
}

if(((Get-DSCConfiguration).ConfigurationName | Select-Object -First 1) -ne "DSC_PullServer_Config")
{
    Write-Host "Configure DSC Server..."
    .\DSC_Pullserver_Config.ps1 -ConfigDataFile $ConfigDataFile -ConfigFile $ConfigFile 
}Else
{
    Write-Host "DSC Server is already configured..."
}
Write-Host "Generating MOF files for SharePoint servers..."
.\DSC_Generate_MOFFiles.ps1 -ConfigDataFile $ConfigDataFile -ConfigFile $ConfigFile
Write-Host "Setup DSCLocalConfiguration manager on all nodes..."
.\DSC_Client_Config.ps1 -ConfigDataFile $ConfigDataFile -ConfigFile $ConfigFile
Write-Host "Sit back, drink your coffee and watch the SharePoint farm get built." -ForegroundColor Green

Get-Date

Stop-Transcript
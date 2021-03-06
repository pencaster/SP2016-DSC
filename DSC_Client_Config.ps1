#***************************************************************************************
#
# This script creates config and runs Set-DscLocalConfigurationManager on all nodes from $ConfigDataFile, as well if using Self signed cert it will deploy Root Chain to all nodes as well
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

param (
    [string][Parameter(Mandatory=$true)] $ConfigDataFile = 'DSCConfigData.psd1',
    [string][Parameter(Mandatory=$true)] $ConfigFile = 'DSCConfig.ps1'
)

[DSCLocalConfigurationManager()]
configuration PullClientConfigID
{
	param([string] $Server,[string]$url,[string]$path,[string]$RegistrationKey)

    Node $Server
    {
        Settings     
        {
            ConfigurationMode = 'ApplyAndAutocorrect'
            RefreshMode = 'Pull'
            RefreshFrequencyMins = 30              # How often we look for new config on pull server
            RebootNodeIfNeeded = $true
            ActionAfterReboot = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
            ConfigurationModeFrequencyMins = 15         #How often we check that server config is correct
        }
        ConfigurationRepositoryWeb PSDSCPullServer
        {
            ServerURL = $url
            RegistrationKey = $RegistrationKey
            ConfigurationNames = @($server)
            AllowUnsecureConnection = $true
        } 
        ReportServerWeb PSDSCPullServer          # https://msdn.microsoft.com/en-us/powershell/dsc/reportserver
        {
            ServerURL = $url
            RegistrationKey = $RegistrationKey
            AllowUnsecureConnection = $true
        }      
    }
}

. "$PSScriptRoot\$ConfigFile"

$ConfigData = "$PSScriptRoot\$ConfigDataFile"

$data = Invoke-Expression (Get-Content $ConfigData | out-string)
$OutputDir = $Data.NonNodeData.DSCConfig.DSCConfigPath + "\Configurations\Client"

Write-host "Will place Client MOF files in $OutputDir"

#Create OutputDir if it doesn't exist, if it does exist the cmdlet will continue without message
New-Item $OutputDir -ItemType directory -ErrorAction SilentlyContinue

$SetupAccount = Get-Credential -UserName $data.NonNodeData.SharePoint.ServiceAccounts.SetupAccount -Message "Setup Account"
$Pfx = $data.NonNodeData.DSCConfig.DSCConfigSharePath + "\Configurations\Cert\DSC.pfx"
$MachineDomain = $data.NonNodeData.DomainDetails.DomainName

if($data.NonNodeData.DSCConfig.DSCAcceptSelfSignedCertificates)
{
    $pwd = ConvertTo-SecureString -String "P@ssword1" -Force -AsPlainText
    Import-PfxCertificate -FilePath $Pfx -CertStoreLocation Cert:\LocalMachine\AuthRoot -Password $Pwd
}

$data.AllNodes | ?{$_.MinRole} | ForEach-Object {
    $node = $_.NodeName + "." + $MachineDomain
  
    if($data.NonNodeData.DSCConfig.DSCAcceptSelfSignedCertificates)
    {
        Enable-WSManCredSSP -DelegateComputer $node -Role Client -Force
        Connect-WSMan $node
        Set-Item "WSMan:\$node\Service\Auth\CredSSP" -Value $True
        $Command = {Import-PfxCertificate -FilePath $Pfx -CertStoreLocation Cert:\LocalMachine\AuthRoot -Password $Pwd}
        Invoke-Command -ComputerName $node -ScriptBlock {Import-PfxCertificate -FilePath $args[0] -CertStoreLocation Cert:\LocalMachine\AuthRoot -Password $args[1]} -ArgumentList $Pfx,$Pwd -Authentication Credssp -Credential $SetupAccount
    }
    
    Write-host "Creating MOF File for Node: $node"

    PullClientConfigID -server $_.Nodename -Url $Data.NonNodeData.DSCConfig.DSCConfigServiceEndPoint -Path $Data.NonNodeData.DSCConfig.DSCConfigModuleShare -RegistrationKey $Data.NonNodeData.DSCConfig.DSCConfigRegistryKey -OutputPath $OutputDir

    Write-Host "Pushing configuration to server: $node"
    Set-DscLocalConfigurationManager -ComputerName $_.NodeName -path $OutputDir -Verbose
}
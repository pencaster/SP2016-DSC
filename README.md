# SharePointDSCSimpleFarm
build out a SharePoint farm using minimum interaction 

These are the configuration that have been tested with:
1.	DSC Service on Windows 2016 with WMF 5.1, Windows 2012 R2 with WMF 5.0 and WMF 5.1
2.	SharePoint 2016 on Windows 2012 R2 with WMF 5.0 and WMF 5.1
3.	Multiple SharePoint Server Farm
4.	Single Server SharePoint Farm


Build out the following servers with just the Operating System and Security Updates. As well add all servers to your domain.
DSC Service
SharePoint
SQL

NOTE: These scripts assume your servers have internet connectivity.  If you don’t you will need to download and install DSC modules to DSC Server and download SharePoint prerequisites to a network share on your own then modify the appropriate settings in the DSCConfigData_SP2016.psd1 file.

You will need to install the SQL server and configure it as per this article
Create the following service accounts, they must be AD DS accounts. See this article for more information about SharePoint service accounts in SharePoint 2016.
Setup Account – Will be used to install and configure SharePoint via DSC (This account is not a managed account)
Farm Admin Account– This is the farm account
Web App Pool Account - This is the identity account for all Web Applications App Pool
Service App Pool Account– This is the identity account for all Service Application App Pool
Content Access Account – Is the account that will be used for authentication during crawls (Also known as Crawl Account)
Create the following folders to store DSC files and SharePoint/Windows executables C:\_DSCConfig, C:\_DSCShare (If you change the path please edit the Configdata.psd1 file your using)

Share out both folders providing ‘Everyone’ with Read permissions (All accounts in DSC need access)
In _DSCShare folder create a folder structure similar to this screen capture.

Then copy the SharePoint 2016 install files into that folder, it should be similar to this screen shot

NOTE: This script defaults to online install if doing offline install see this article for prerequisite files
In _DSCConfig folder create a script folder and copy all the script files into it

Insure network connectivity by pinging all nodes and SQL server from DSC servers using Netbios and FQDN.
On DSC Server and each SharePoint server perform the following steps:
Add Setup Account to the local administrator group

Update to the latest version of WMF (Min WMF5.1), I know you that WMF 4.0 has DSC in it but I use features only found in WMF5.1
 
Next you need to configure the ConfigData file with all necessary information for your environment, open the file DSCConfigData_SP2016.psd1 and setup the file with the correct values. For more information see this article to better understand the files DSCConfig_SimpleFarm.ps1 and DSCConfigData.psd1
From the DSC server open a PowerShell window using Run As Admin then run the command:

.\Build_SharePoint_Farm.ps1 -ConfigDataFile DSCConfigData_SP2016.psd1 -ConfigFile DSCConfig_SimpleFarm.ps1


Sit back and watch your farm get built
NOTE: If you hit any errors you need to correct them
Just so you know, the script 'Build_SharePoint_Farm.ps1' will perform the following steps:


Start and Stop Transcript
Install Nuget and xPSDesiredConfiguration to the DSC server
If DSC service is not configured via these scripts it will configure it using the script DSC_Pullserver_Config.ps1

Then it will configure the nodes (SharePoint Servers) using this script DSC_Client_Config.ps1

Then it will create the MOF file for each node and place in the appropriate folder using the script DSC_Generate_MOFFiles.ps1
Depending on many factors it could take several hours to build your farm.


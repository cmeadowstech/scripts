Credit to David Conners for the idea: https://www.ravenswoodtechnology.com/authentication-options-for-automated-azure-powershell-scripts-part-1/ 

# Prerequisites 

PowerShell Module AzureAD 

    https://docs.microsoft.com/en-us/powershell/module/azuread/?view=azureadps-2.0 

    Install-Module AzureAD 

PowerShell Module Microsoft.Graph 

    https://docs.microsoft.com/en-us/graph/powershell/installation 

    Install-Module Microsoft.Graph 

Azure AD Premium licensing - Necessary for the Graph API permissions to work 

    https://docs.microsoft.com/en-us/azure/active-directory/reports-monitoring/howto-configure-prerequisites-for-reporting-api#license-requirements 

 
 
# Methodology  

Microsoft is starting to cut down on how PowerShell can be automated with O365 services due to security concerns. In the past you used to be able to store credentials as a variable, but that doesn't work very will anymore with Modern Authentication. If you do it that way you potentially have to manually sign in each time a script is run.  

But it's for a valid reason, storing credentials locally is not the best option. Microsoft is moving towards tokens and certificates for authentication where they can't be reused when accessing other resources or on other machines.  

For this, we are going to use an App Registration and certificates to authenticate. This also lets us control exactly what permissions the automated script has as well, meaning it can be read only so if the device is compromised it can't actually make any changes. 

The main downside is the graph API needed to read sign-in events is dependent on Azure AD Premium licensing. 


# Process
 
AppRegistration.ps1 automates the process of creating the Azure App registration. What it does: 

    Connects to the AzureAD PowerShell module 

    Creates an Azure application named "Automated SignIn Report" 

    Creates a locally signed certificate named "Automated SignIn Report Registration" 

    Imports this certificate into the previously created Azure App 

    Assigns the Graph permissions AuditLog.Read.All and Directory.Read.All to the Azure App 

    Will open the Azure App in the Azure AD Admin center so a Global Admin can grant authorization to the assigned permissions 

    Will output a ClientId and a TenantId, which you will need when connecting to the Graph SDK via your PowerShell script 


# Creating the script 

For this we use the Microsoft.Graph PowerShell module. It has many cmdlets similar to the AzureAD module, but lets you use App registrations for authentication and the granular Graph permissions for authorization.  

To connect you will need: 

    The ClientId 

    The TenantId 

    The thumbprint of the locally signed certificate 

Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -CertificateThumbprint $Thumbprint 

However, if you created the certificate via my script the thumbprint won't display in the Azure AD Admin center. Instead, you can use this to get it from the locally installed certificate: 

$Thumbprint = (Get-ChildItem -Path Cert:\CurrentUser\My | where { $_.subject -eq "CN=Automated SignIn Report Registration" }).Thumbprint  

GraphLogins.ps1 is an example of how this can be utilized with the Microsoft.Graph module.

 
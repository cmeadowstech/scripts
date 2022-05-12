# This is designed to automatically create an Azure App registration along with a locally signed certificate. Please read the readme for more info.

Write-Host "Please connect to Azure AD" -ForegroundColor Cyan

Start-Sleep -Seconds 5

Connect-AzureAD # Connects to AzureAD to run the AzureAD cmdlets

# Creating the application

Write-Host "Creating application..." -ForegroundColor Cyan

$appName = "Automated SignIn Report"
if(!($myApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'" -ErrorAction SilentlyContinue))
{
    $myApp = New-AzureADApplication -DisplayName $appName
}

$objectId = (Get-AzureADApplication -Filter "DisplayName eq '$($appName)'").ObjectId
$appId = (Get-AzureADApplication -Filter "DisplayName eq '$($appName)'").AppId
$tenantId = (Get-AzureADTenantDetail).ObjectId

# Creates the local certificate

Write-Host "Creating certificate..." -ForegroundColor Cyan

New-SelfSignedCertificate -Subject "Automated SignIn Report Registration" -CertStoreLocation Cert:\CurrentUser\My
$Thumbprint = (Get-ChildItem -Path Cert:\CurrentUser\My | where { $_.subject -eq "CN=Automated SignIn Report" }).Thumbprint

Export-Certificate -Cert Cert:\CurrentUser\My\$($Thumbprint) -Type Cert -FilePath C:\AppReg.cer

# Converts and imports certificate

Write-Host "Uploading certificate..." -ForegroundColor Cyan

$cer = New-Object System.Security.Cryptography.X509Certificates.X509Certificate 
$cer.Import("C:\AppReg.cer")
$bin = $cer.GetRawCertData()
$base64Value = [System.Convert]::ToBase64String($bin)
$bin = $cer.GetCertHash()
$base64Thumbprint = [System.Convert]::ToBase64String($bin)
New-AzureADApplicationKeyCredential -ObjectId $objectId -CustomKeyIdentifier $base64Thumbprint -Type AsymmetricX509Cert -Usage Verify -Value $base64Value -StartDate $cer.GetEffectiveDateString() -EndDate $cer.GetExpirationDateString()

Remove-Item C:\AppReg.cer

# Assigns permissions

Write-Host "Assigning permissions..." -ForegroundColor Cyan

$svcprincipalGraph = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -eq "Microsoft Graph" }

$Graph = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$Graph.ResourceAppId = $svcprincipalGraph.AppId

$AppPermission1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "e4c9e354-4dc5-45b8-9e7c-e1393b0b1a20","Scope" # AuditLog.Read.All
$AppPermission2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "06da0dbc-49e2-44d2-8312-53f166ab848a","Scope" # Directory.Read.All 

$Graph.ResourceAccess = $AppPermission1, $AppPermission2

$ADApplication = Get-AzureADApplication -All $true | ? { $_.AppId -match $appId }

Set-AzureADApplication -ObjectId $objectId -RequiredResourceAccess $Graph

# Confirm consent to permissions

Write-Host "Please login with a Global Admin to grant permissions." -ForegroundColor Cyan

$consentURL = "https://aad.portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/$($appid)/isMSAApp/"
Start-Sleep -Seconds 5
Start-Process $consentURL

Write-Host "Disonnecting from Azure..." -ForegroundColor Cyan

Disconnect-AzureAD

Write-Host "App creation has been completed. Please double-check that certificiate has been uploaded and permissions are assigned and granted." -ForegroundColor Cyan
Write-Host "You will also need to copy the following information to input into the SignIn Report script. It will be saved to a TXT file as well." -ForegroundColor Cyan

Write-Host "Client Id: $($appId)" -ForegroundColor Yellow
Write-Output "Client Id: $($appId)" | Out-File AppInformation.txt

Write-Host "Tenant Id: $($tenantId)" -ForegroundColor Yellow | Out-File AppInformation.txt -Append
Write-Output "Tenant Id: $($tenantId)" | Out-File AppInformation.txt -Append

Write-Host "Closing in 60 seconds..." -ForegroundColor Cyan 

Start-Sleep -Seconds 60
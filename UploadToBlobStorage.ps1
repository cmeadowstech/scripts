# This only works for a single folder with no sub-folders, which suits my purpose of uploading to my static web page just fine. 

Connect-AzAccount		# If you have multiple directories you will need to specify with -Tenant

# Set container and context below

$localfolder = "C:\your path here"
$storageAccount = Get-AzStorageAccount -ResourceGroupName "Your Resource Group" -Name "Name of storage account"
$Context = $storageAccount.context
$ContainerName = '$web'
$Storage = Get-AzStorageBlob -Context $Context -Container '$web'
$files = Get-ChildItem $localfolder

# Replace files if they exist, and upload them if they don't

foreach ($file in $files) {
    $name = $file.name
    $path = "$($localfolder)\$($name)"
    $blob = Get-AzStorageBlob -Container $ContainerName -Context $Context -Blob $name -ErrorAction:SilentlyContinue
    if ($blob -eq $null) {
        Set-AzStorageBlobContent -Container $ContainerName -Context $Context -File $path -Blob $name -Properties @{"ContentType" = [System.Web.MimeMapping]::GetMimeMapping($path)}    # If the file does not currently exist on the container
    } else {
        $blob | Set-AzStorageBlobContent -File $path -Properties @{"ContentType" = [System.Web.MimeMapping]::GetMimeMapping($path)} -Force    # If the file does currently exist on the container
    }
}

# Purge CDN Endpoint
Get-AzCdnProfile | Get-AzCdnEndpoint | Unpublish-AzCdnEndpointContent -PurgeContent "/*"		# This is not thoroughly tested in subscriptions that might have multiple CDNs

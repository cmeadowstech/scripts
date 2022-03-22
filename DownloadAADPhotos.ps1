<#

This is used to download all of your users profile pictures from Azure Active Directory.
Can be useful in cases where you sync users with Azure AD Connect before they have mailboxes.
Due to how profile pictures sync across workloads, Azure will only sync them to Exchange
during the initial sync. Meaning mailboxes provisioned after the fact will not have them.

This does use a third-party module ResizeImageModule to resize them to dimensions
that work better with uploading to Exchange Online. Un-comment Install-module below
to install it for the current session.

#>

# Install-module ResizeImageModule -scope currentuser

$path = read-host "Please set a directory for user photos to be downloaded to"
New-Item -Path $path -Name Original -Type Directory | Out-Null
New-Item -Path $path -Name Resized -Type Directory | Out-Null
$users = Get-AzureADUser -All $true
foreach ($user in $users) {
	$UPN = $user.UserPrincipalName
	try {
		$UserPhoto = Get-AzureADUserThumbnailPhoto -objectid $User.Objectid
		if ($UserPhoto -ne $null) {
			Get-AzureADUserThumbnailPhoto -objectid $User.Objectid -FilePath $path\Original -FileName $UPN
			Resize-Image -InputFile $path\Original\$upn.jpeg -OutputFile $path\Resized\$upn`.jpeg -Height 100 -Width 100
			Write-Host "Saved to $UPN`.jpeg"
		}
	} catch {
		write-host "$($UPN) has no Azure AD Thumbnail Photo" -fore red
	}
}

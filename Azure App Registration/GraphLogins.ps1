$ClientId = 
$TenantId = 
$Thumbprint = (Get-ChildItem -Path Cert:\CurrentUser\My | where { $_.subject -eq "CN=Automated SignIn Report Registration" }).Thumbprint
Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -CertificateThumbprint $Thumbprint
$logs = Get-MgAuditLogSignIn
$logs | Select `
    UserPrincipalName,
    AppDisplayName,
	ClientAppUsed,
	ConditionalAccessStatus,
	CreatedDateTime,
	@{n="DeviceDetail";e={$_.DeviceDetail.browser}},
	IPAddress,
	@{n="Location";e={"$($_.Location.City), $($_.Location.State)"}},
	ResourceDisplayName,
	RiskDetail,
	RiskLevelAggregated,
	RiskLevelDuringSignIn,
	RiskState,
    @{n='Status';e={if ($_.Status.ErrorCode -eq 0) {"Success"} Else {"Failure: $($_.Status.FailureReason)"}}} |
        Export-Csv $home\downloads\test_graph.csv -NoTypeInformation
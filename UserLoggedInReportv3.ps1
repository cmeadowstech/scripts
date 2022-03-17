<#

Dependencies: ExchangeOnlineManagement and ImportExcel modules

Please run Connect-ExchangeOnline before running.

To use, simply call the script followed by the users you want to
generate the report for separated by commas.

Example:

./UserLoggedInReportv3.ps1 user1@domain.com,user2@domain.com

#>

param($UserIds)
if ($UserIds -eq $null) {
    $UserIds = Read-Host "Please input UPN here"
}

$Days = 30                                       # How many days back you want the report to go                      
$Start = (Get-Date).AddDays(-($Days))
$End = Get-Date

$TotalItems = $UserIds.Count
$CurrentItem = 1
$PercentComplete = 0

foreach ($UserId in $UserIds) {
$name = ($UserId).ToString() -replace "@.*"
Write-Progress -Activity "Running search for $($name)..." -Status "User $($CurrentItem) of $($TotalItems)" -PercentComplete $PercentComplete
$CurrentItem++
$PercentComplete = [int]((($CurrentItem -1) / $TotalItems) * 100)

$Audit = Search-UnifiedAuditLog -StartDate $Start -EndDate $End -UserIds $UserId -Operation UserLoggedIn -ResultSize 5000
$ConvertAudit = $Audit | Select -ExpandProperty AuditData | ConvertFrom-Json        # Converts audit log AuditData from json to something more readable by PowerShell
$PartialSignInReport = $ConvertAudit | Select `
    CreationTime,
    UserId,
    ActorIpAddress,
    ResultStatus,
    Workload,
    @{n="Device Info";e={($_.ExtendedProperties | where {$_.Name -eq 'UserAgent'}).Value }}

$SignInReport += $PartialSignInReport

while ($PartialSignInReport.count -eq 5000) {
    $LastDate = ($PartialSignInReport | select -last 1).CreationTime
    $Audit = Search-UnifiedAuditLog -StartDate $Start -EndDate $LastDate -Operation UserLoggedIn -ResultSize 5000
    $ConvertAudit = $Audit | Select -ExpandProperty AuditData | ConvertFrom-Json        # Converts audit log AuditData from json to something more readable by PowerShell
    $PartialSignInReport = $ConvertAudit | Select `
        CreationTime,
        UserId,
        ActorIpAddress,
        ResultStatus,
        Workload,
        @{n="Device Info";e={($_.ExtendedProperties | where {$_.Name -eq 'UserAgent'}).Value }}
    $SignInReport += $PartialSignInReport
}

$SignInReport = $SignInReport | Select CreationTime,UserId,ActorIpAddress,ResultStatus,Workload,"Device Info" -Unique

$signIns1Day = $SignInReport | Where CreationTime -gt (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
$signIns7Days = $SignInReport | Where CreationTime -gt (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
$signIns30Days = $SignInReport | Where CreationTime -gt (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")

$ipCount1Day = $signIns1Day | Group-Object -Property ActorIpAddress -NoElement | Sort-Object -Property Count -Descending | Select `
    @{n="IpAddressOneDay";e={($_.Name)}},
    @{n="OneDayCount";e={($_.Count)}}

 $ipCount7Days = $signIns7Days | Group-Object -Property ActorIpAddress -NoElement | Sort-Object -Property Count -Descending | Select `
    @{n="IpAddressSevenDays";e={($_.Name)}},
    @{n="SevenDayCount";e={($_.Count)}}

$ipCount30Days = $signIns30Days | Group-Object -Property ActorIpAddress -NoElement | Sort-Object -Property Count -Descending | Select `
    @{n="IpAddressThirtyDays";e={($_.Name)}},
    @{n="ThirtyDayCount";e={($_.Count)}}

$1daySpacing = (($ipCount1Day."IpAddressOneDay").count)
$7daySpacing = (($ipCount7Days."IpAddressSevenDays").count) + $1daySpacing
$30daySpacing = (($ipCount30Days."IpAddressThirtyDays").count) + $7daySpacing

$signInXLSX = $SignInReport | Export-Excel $home\Downloads\$($name)-sign-ins.xlsx -WorksheetName "Sign-ins" -BoldTopRow -AutoSize -FreezeTopRow -ClearSheet -PassThru
$chartDef = $(
    New-ExcelChartDefinition -Title '1 Day Sign-in Distribution' -ChartType Pie -XRange IpAddressOneDay -YRange OneDayCount -Width 400 -Height 300 -Row ($1daySpacing + 1) -ShowPercent
    New-ExcelChartDefinition -Title '7 Day Sign-in Distribution' -ChartType Pie -XRange IpAddressSevenDays -YRange SevenDayCount -Width 400 -Height 300 -Row ($7daySpacing + 20) -ShowPercent
    New-ExcelChartDefinition -Title '30 Day Sign-in Distribution' -ChartType Pie -XRange IpAddressThirtyDays -YRange ThirtyDayCount -Width 400 -Height 300 -Row ($30daySpacing + 40) -ShowPercent
)

$signInXLSX  = $ipCount1Day | Export-Excel -ExcelPackage $signInXLSX -WorksheetName "Sign-ins" -StartColumn 8 -AutoSize -AutoNameRange -PassThru -BoldTopRow
$signInXLSX  = $ipCount7Days | Export-Excel -ExcelPackage $signInXLSX -WorksheetName "Sign-ins" -StartColumn 8 -StartRow ($1daySpacing  + 19) -AutoSize -AutoNameRange -PassThru
$ipCount30Days | Export-Excel -ExcelPackage $signInXLSX -WorksheetName "Sign-ins" -StartColumn 8 -StartRow ($7daySpacing  + 38) -AutoSize -AutoNameRange -ExcelChartDefinition $chartDef
}

Write-Host "Reports have been exported to your Downloads folder." -ForegroundColor Cyan
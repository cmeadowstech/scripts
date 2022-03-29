<#

Used to fix the Organization Management role, which seems to be a common issue for us nowadays.
This can prevent common administrative tasks like adding aliases or configuring forwarding.
The roles listed below are from an E5 tenant and may have a couple additional roles that Business
tenants may lack. 

ApplicationImpersonation is included. Leave that out if you don't want that permission.

#>

$roles = "ApplicationImpersonation",
"Audit Logs",
"Compliance Admin",
"Data Loss Prevention",
"Distribution Groups",
"E-Mail Address Policies",
"Federated Sharing",
"Information Rights Management",
"Journaling",
"Legal Hold",
"Mail Enabled Public Folders",
"Mail Recipient Creation",
"Mail Recipients",
"Mail Tips",
"Message Tracking",
"Migration",
"Move Mailboxes",
"Org Custom Apps",
"Org Marketplace Apps",
"Organization Client Access",
"Organization Configuration",
"Organization Transport Settings",
"Public Folders",
"Recipient Policies",
"Remote and Accepted Domains",
"Reset Password",
"Retention Management",
"Role Management",
"Security Admin",
"Security Group Creation and Membership",
"Security Reader",
"Team Mailboxes",
"TenantPlacesManagement",
"Transport Hygiene",
"Transport Rules",
"UM Mailboxes",
"UM Prompts",
"Unified Messaging",
"User Options",
"View-Only Audit Logs",
"View-Only Configuration",
"View-Only Recipients"

$report = @()

foreach ($role in $roles) {

$currentPermissions = (Get-RoleGroup "Organization Management").RoleAssignments | where {$_ -notlike "*Deleg*"} # Used to determine currently assigned permissions. Is slightly broad in scope due to truncating, but shouldn't cause issues.
$error.clear()
    if ("$($currentPermissions)" -like "*$($role)*") {
        Write-Host "$($role) is currently assigned" -ForegroundColor Green
        $report += New-Object psobject -property @{Role = $role; Status = "Already exists"; Error = $error[0]}
        } else {
        write-host "$($role) is not currently assigned, and will be added" -ForegroundColor Magenta
        $status = "Added"
        try {
            New-ManagementRoleAssignment -Role $role -SecurityGroup "Organization Management" -ErrorAction:stop | Out-Null
        
        } catch {
            $status = "Error"
            write-host "There was an error adding this permission. See report for details." -ForegroundColor Red
        }
        $report += New-Object psobject -property @{Role = $role; Status = $status; Error = $error[0]}
    }
}

$report | Export-Csv $home\downloads\org_mgmt_permission_report.csv -NoTypeInformation

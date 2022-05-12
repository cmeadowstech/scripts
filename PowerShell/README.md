# PowerShell
Some of the PowerShell scripts that I have put together thus far. 

Not scripts, but I'll share some helpful cmdlets I use in my day-to-day below as well.

------------------------------------------------------------------

## View mailbox/folder permissions 

*To view who has permissions on a specific mailbox:*

`Get-MailboxPermission mailbox@domain.com`

*To view a specific user's permissions to a specific mailbox:*

`Get-MailboxPermission mailbox@domain.com -User user@domain.com `

https://docs.microsoft.com/en-us/powershell/module/exchange/get-mailboxpermission?view=exchange-ps 

*To view who has permissions to a specific mailbox folder (In this case the calendar):*

`Get-MailboxFolderPermission mailbox@domain.com:\calendar `

*To view a specific user's permissions to a specific mailbox folder (In this case the calendar):*

`Get-MailboxFolderPermission mailbox@domain.com:\calendar -User mailbox@domain.com `

https://docs.microsoft.com/en-us/powershell/module/exchange/get-mailboxfolderstatistics?view=exchange-ps 

------------------------------------------------------------------

## View mailbox/folder size 

*To view size of a mailbox:*

`Get-MailboxStatistics -Identity user@domain.com | Select DisplayName,ItemCount,TotalItemSize `

*To view the size of an archive mailbox, add a -Archive switch:*

`Get-MailboxStatistics -Identity user@domain.com  -Archive | Select DisplayName,ItemCount,TotalItemSize `

https://docs.microsoft.com/en-us/powershell/module/exchange/get-mailboxstatistics?view=exchange-ps 

*To view size of all folders:*

`Get-MailboxFolderStatistics -Identity user@domain.com | Select FolderPath,ItemsInFolder,FolderSize `

  Note: You can use the -Archive switch for Get-MailboxFolderStatistics as well 

*To view size of all folders and sort by number of items:*

`Get-MailboxFolderStatistics -Identity user@domain.com | Select FolderPath,ItemsInFolder,FolderSize | Sort ItemsInFolder -Descending `

*To view size of specific folder scopes (Deleted items, contacts, calendars):*

`Get-MailboxFolderStatistics user@domain.com -FolderScope RecoverableItems | Select FolderPath,ItemsInFolder,FolderSize `

*Options for -FolderScope*

    All 
    Archive: Exchange 2016 or later. 
    Calendar 
    Contacts 
    ConversationHistory 
    DeletedItems 
    Drafts 
    Inbox 
    JunkEmail 
    Journal 
    LegacyArchiveJournals: Exchange 2013 or later. 
    ManagedCustomFolder: Returns output for all managed custom folders. 
    NonIpmRoot: Exchange 2013 or later. 
    Notes 
    Outbox 
    Personal 
    RecoverableItems: Returns output for the Recoverable Items folder and the Deletions, DiscoveryHolds, Purges, and Versions subfolders. 
    RssSubscriptions 
    SentItems 
    SyncIssues 
    Tasks 
    
------------------------------------------------------------------

## Searching Exchange mailbox audit logs

*To search a mailbox audit log for a specific user:*

`Search-MailboxAuditLog -Identity user@domain.com -ShowDetails -StartDate 09/15/2021 -EndDate (Get-Date) | export-csv $home\downloads\user_mailbox_audit.csv -NoTypeInformation `

*To find a specific user's activities in a shared mailbox:*

`Search-MailboxAuditLog -Identity mailbox@domain.com -ShowDetails -StartDate 09/15/2021 -EndDate (Get-Date) | where LogonUserDisplayName -like "Display Name" | export-csv $home\downloads\mailbox_mailbox_audit.csv -NoTypeInformation `

https://docs.microsoft.com/en-us/powershell/module/exchange/search-mailboxauditlog?view=exchange-ps 

*Note: By default not all actions are audited. Refer to this for a list of default actions - https://docs.microsoft.com/en-us/exchange/policy-and-compliance/mailbox-audit-logging/mailbox-audit-logging?view=exchserver-2019#mailbox-actions-logged-by-mailbox-audit-logging*

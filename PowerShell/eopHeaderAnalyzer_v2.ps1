<#

Just run the script and paste the value of x-forefront-antispam-report when prompted. This does not interpret
country or language, only any pairs like CAT:AMP that were found in the following documentation:

https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/anti-spam-message-headers?view=o365-worldwide

Please manually review SCL and SPF/DKIM/DMARC in addition to this interpretation.

#>

$input = Read-Host "Please paste the value of x-forefront-antispam-report here" 
$headers = $input -split ";"
$cipIP = Select-String -InputObject $headers -Pattern "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" -AllMatches | Foreach {$_.matches.value}

$eopHeaders = @{
    "CAT:BULK" = "[CAT:BULK] This email was flagged as Bulk."
    "CAT:DIMP" = "[CAT:DIMP] This email was flagged as Domain Impersonation."
    "CAT:GIMP" = "[CAT:GIMP] This email was flagged as Mailbox intelligence based impersonation."
    "CAT:HPHSH" = "[CAT:HPHSH] This email was flagged as High confidence phishing."
    "CAT:HPHISH" = "[CAT:HPHISH] This email was flagged as High confidence phishing.."
    "CAT:HSPM" = "[CAT:HSPM] This email was flagged as High confidence spam."
    "CAT:MALW" = "[CAT:MALW] This email was flagged as Malware."
    "CAT:PHSH" = "[CAT:PHSH] This email was flagged as Phishing."
    "CAT:SPM" = "[CAT:SPM] This email was flagged as Spam."
    "CAT:SPOOF" = "[CAT:SPOOF] This email was flagged as Spoofing."
    "CAT:UIMP" = "[CAT:UIMP] This email was flagged as User Impersonation."
    "CAT:AMP" = "[CAT:AMP] This email was flagged as Anti-malware."
    "CAT:SAP" = "[CAT:SAP] This email was flagged as Safe attachments."
    "CAT:OSPM" = "[CAT:OSPM] This email was flagged as Outbound spam."
    "IPV:CAL" = "[IPV:CAL] The message skipped spam filtering because the source IP address was in the IP Allow List."
    "IPV:NLI" = "[IPV:NLI] The IP address was not found on any IP reputation list."
    "SFV:BLK" = "[SFV:BLK] Filtering was skipped and the message was blocked because it was sent from an address in a user's Blocked Senders list."
    "SFV:NSPM" = "[SFV:NSPM] Spam filtering marked the message as non-spam and the message was sent to the intended recipients."
    "SFV:SFE" = "[SFV:SFE] Filtering was skipped and the message was allowed because it was sent from an address in a user's Safe Senders list."
    "SFV:SKA" = "[SFV:SKA] The message skipped spam filtering and was delivered to the Inbox because the sender was in the allowed senders list or allowed domains list in an anti-spam policy."
    "SFV:SKB" = "[SFV:SKB] The message was marked as spam because it matched a sender in the blocked senders list or blocked domains list in an anti-spam policy."
    "SFV:SKI" = "[SFV:SKI] The message skipped spam filtering for another reason (for example, an intra-organizational email within a tenant)."
    "SFV:SKN" = "[SFV:SKN] The message was marked as non-spam prior to being processed by spam filtering. For example, the message was marked as SCL -1 or Bypass spam filtering by a mail flow rule."
    "SFV:SKQ" = "[SFV:SKQ] The message was released from the quarantine and was sent to the intended recipients."
    "SFV:SKS" = "[SFV:SKS] The message was marked as spam prior to being processed by spam filtering. For example, the message was marked as SCL 5 to 9 by a mail flow rule."
    "SFV:SPM" = "[SFV:SPM] The message was marked as spam by spam filtering."
    "SRV:BULK" = "[SRV:BULK] The message was identified as bulk email by spam filtering and the bulk complaint level (BCL) threshold. When the MarkAsSpamBulkMail parameter is On (it's on by default), a bulk email message is marked as spam (SCL 6)."
}

Write-Host "The connecting address is $($cipIP)" -ForegroundColor Yellow

foreach ($header in $headers) {
    if ($eopHeaders["$($header)"] -eq $null) {
    } else {
    Write-Host $eopHeaders["$($header)"] -ForegroundColor Cyan
    }
}

Write-Host "Please manually review SCL and SPF/DKIM/DMARC in addition to this interpretation." -ForegroundColor Green

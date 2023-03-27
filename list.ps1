param(
    $daysLogon = 30
)
Import-Module AzureAD

function email_error() {
    param(
        $err1
    )
    # Default email variables
    $EmailFrom = ""
    $EmailTo = @("")
    $EmailSubject = ""
    $SMTPserver = ""
    $script_time = Get-Date
    $emailBody = "<html><body><br>
    <font color='FF0000'>Run at $script_time</font><br /><br />
    <table cellpadding='5' cellspacing='0' style='border: 1px solid black;'>
    <tr><th style='border: 1px solid black;'>App Name</th><th style='border: 1px solid black;'>Object Id</th><th style='border: 1px solid black;'>Type</th><th style='border: 1px solid black;'>Certificate Name</th><th style='border: 1px solid black;'>Days to Expiry</th></tr>
    $err1
    </table>"
    # Default sendmail parameters
    $sendMailParameters = @{
        From       = $EmailFrom
        To         = $EmailTo
        Subject    = $EmailSubject
        Body       = $emailBody
        SMTPServer = $SMTPserver
        BodyAsHTML = $True
    }
    # Send the email
    Send-MailMessage @sendMailParameters
}

# Expiring App Registration Certs and Certificates
$Applications = Get-AzureADApplication -all $true
$now = get-date

$tableRows = @()

foreach ($app in $Applications) {
    $AppName = $app.DisplayName
    $AppID = $app.objectid
    $ApplID = $app.AppId
    $AppCreds = Get-AzureADApplication -ObjectId $AppID | select PasswordCredentials, KeyCredentials
    $secret = $AppCreds.PasswordCredentials
    $cert = $AppCreds.KeyCredentials
    
    foreach ($s in $secret) {
        $StartDate = $s.StartDate
        $EndDate = $s.EndDate
        $Logs = $EndDate - $now
        if (($Logs.Days -lt $daysLogon) -and ($Logs.Days -gt 0))
        {
            $tableRows += "<tr><td style='border: 1px solid black;'>$AppName</td><td style='border: 1px solid black;'>$AppID</td><td style='border: 1px solid black;'>Secret</td><td style='border: 1px solid black;'></td><td style='border: 1px solid black; color:yellow'>$($Logs.Days) Days</td></tr>"
        }
    }
    foreach ($c in $cert) {
        $StartDate = $c.StartDate
        $EndDate = $c.EndDate
        $Logs = $EndDate - $now
        if (($Logs.Days -lt $daysLogon) -and ($Logs.Days -gt 0))
        {
            $tableRows += "<tr><td style='border: 1px solid black;'>$AppName</td><td style='border: 1px solid black;'>$AppID</td><td style='border: 1px solid black;'>Certificate</td><td style='border: 1px solid black;'>$($c.DisplayName)</td><td style='border: 1px solid black; color:red'>$($Logs.Days) Days</td></tr>"
        }
   

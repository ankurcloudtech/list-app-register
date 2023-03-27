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

    # Create HTML table
    $table = "<table><tr><th>App Name</th><th>Object Id</th><th>Credential Type</th><th>Credential Name</th><th>Expiring in (Days)</th></tr>"
    $table += $err1
    $table += "</table>"

    # Default sendmail parameters
    $sendMailParameters = @{
        From       = $EmailFrom
        To         = $EmailTo
        Subject    = $EmailSubject
        Body       = $table
        SMTPServer = $SMTPserver
        BodyAsHTML = $True
    }
    
    # Send the email
    Send-MailMessage @sendMailParameters
}

# Initialize output variable
$message = ""

# Expiring App Registration Certs and Certificates
$Applications = Get-AzureADApplication -all $true
$now = get-date

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
        
        if (($Logs.Days -lt $daysLogon) -and ($Logs.Days -gt 0)) {
            # Append output to message
            $message += "<tr><td>$AppName</td><td>$AppID</td><td>Secret</td><td>$($s.DisplayName)</td><td>$($Logs.Days)</td></tr>"
        }
    }

    foreach ($c in $cert) {
        $StartDate = $c.StartDate
        $EndDate = $c.EndDate
        $Logs = $EndDate - $now
        
        if (($Logs.Days -lt $daysLogon) -and ($Logs.Days -gt 0)) {
            # Append output to message
            $message += "<tr><td>$AppName</td><td>$AppID</td><td>Certificate</td><td>$($c.DisplayName)</td><td>$($Logs.Days)</td></tr>"
        }
    }
}

# Check if there are any results to send
if ($message -ne "") {
    # Call email_error function to send email
    email_error -err1 "$message"
}
else {
    Write-Host "No expiring App Registration Certs and Certificates found."
}

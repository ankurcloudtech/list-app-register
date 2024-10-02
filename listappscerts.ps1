param(
    $daysLogon = 30
)

Import-Module Az

# Connect to Azure using the Automation Account's Managed Identity
Connect-AzAccount -Identity

function email_error() {
    param(
        $err1
    )
    
    $EmailFrom = "noreply@domain.com"
    $EmailTo = @("ankurpatel51206@gmail.com", "ankur51206@gmail.com")
    $EmailSubject = "Expiring App Registrations"
    $SMTPserver = "email-smtp.us-east-1.amazonaws.com"
    $SMTPUser = "xxxxxxxxxxxxxxx"
    $SMTPPassword = "xxxxxxxxxxxxxxxxxxxxxxxxxxx"
    
    # Create HTML table
    $table = "<table><tr><th>App Name</th><th>Object Id</th><th>Credential Type</th><th>Credential Name</th><th>Expiring in (Days)</th></tr>"
    $table += $err1
    $table += "</table>"

    # Create SMTP client and set credentials
    $smtpClient = New-Object System.Net.Mail.SmtpClient($SMTPserver, 587)
    $smtpClient.EnableSsl = $true
    $smtpClient.Credentials = New-Object System.Net.NetworkCredential($SMTPUser, $SMTPPassword)

    # Send the email
    $message = New-Object System.Net.Mail.MailMessage
    $message.From = $EmailFrom
    $EmailTo | ForEach-Object { $message.To.Add($_) }
    $message.Subject = $EmailSubject
    $message.Body = $table
    $message.IsBodyHtml = $true

    $smtpClient.Send($message)
}

# Initialize output variable
$message = ""

# Expiring App Registration Certs and Certificates
$Applications = Get-AzADApplication
$now = Get-Date

foreach ($app in $Applications) {
    $AppName = $app.DisplayName
    $AppID = $app.Id
    $AppCreds = Get-AzADAppCredential -ObjectId $AppID
    $secret = $AppCreds | Where-Object { $_.Type -eq 'Password' }
    $cert = $AppCreds | Where-Object { $_.Type -eq 'AsymmetricX509Cert' }

    foreach ($s in $secret) {
        $EndDate = $s.EndDate
        $Logs = $EndDate - $now
        
        if (($Logs.Days -lt $daysLogon) -and ($Logs.Days -gt 0)) {
            # Append output to message
            $message += "<tr><td>$AppName</td><td>$AppID</td><td>Secret</td><td>$($s.DisplayName)</td><td>$($Logs.Days)</td></tr>"
        }
    }

    foreach ($c in $cert) {
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
    email_error -err1 "$message"
}
else {
    Write-Host "No expiring App Registration Certs and Certificates found."
}

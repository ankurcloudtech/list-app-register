param(
    [int]$DaysToExpiration = 30 # Set how many days to check for expiration
)

$currentDate = Get-Date

# Get the applications from Azure AD
$applications = Get-AzureADApplication

# Initialize an array to hold applications with expiring secrets or certificates
$expiringApplications = @()

foreach ($app in $applications) {
    # Check if the application has any password credentials
    if ($app.PasswordCredentials) {
        foreach ($secret in $app.PasswordCredentials) {
            $expirationDate = [datetime]$secret.EndDate
            # Check if the secret is expiring within the specified number of days
            if (($expirationDate - $currentDate).Days -le $DaysToExpiration) {
                $expiringApplications += [PSCustomObject]@{
                    AppName        = $app.DisplayName
                    AppId          = $app.AppId
                    SecretName     = $secret.DisplayName
                    ExpirationDate = $expirationDate
                }
            }
        }
    }

    # Check if the application has any key credentials (certificates)
    if ($app.KeyCredentials) {
        foreach ($cert in $app.KeyCredentials) {
            $expirationDate = [datetime]$cert.EndDate
            # Check if the certificate is expiring within the specified number of days
            if (($expirationDate - $currentDate).Days -le $DaysToExpiration) {
                $expiringApplications += [PSCustomObject]@{
                    AppName        = $app.DisplayName
                    AppId          = $app.AppId
                    CertName       = $cert.DisplayName
                    ExpirationDate = $expirationDate
                }
            }
        }
    }
}

# Capture output in a variable
if ($expiringApplications.Count -gt 0) {
    $output = $expiringApplications | Format-Table -AutoSize | Out-String
} else {
    $output = "No applications with expiring secrets or certificates found within the next $DaysToExpiration days."
}

# Create a credential object for SMTP authentication
$SMTPUser = "xxxxxxxxxxxxxxxxx"
$SMTPPassword = ConvertTo-SecureString "xxxxxxxxxxxxxxxxxxxxxxxxxxxx" -AsPlainText -Force
$SMTPCredential = New-Object System.Management.Automation.PSCredential ($SMTPUser, $SMTPPassword)

# Send email with the results
$subject = "Azure AD Application Secret/Certificate Expiration Report"
$body = $output
$to = "ankur51206@gmail.com"
$from = "noreply@domain.com"
$smtpServer = "email-smtp.us-east-1.amazonaws.com"
$smtpPort = 587

Send-MailMessage -To $to -From $from -Subject $subject -Body $body -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential $SMTPCredential

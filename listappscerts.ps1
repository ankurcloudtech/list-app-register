# Authenticate to Azure using Managed Identity
Connect-AzAccount -Identity

# Set the threshold in days for nearly expiring secrets/certificates
$daysThreshold = 30

# Get the current date and the date for comparison (nearly expiring)
$currentDate = Get-Date
$nearExpiryDate = $currentDate.AddDays($daysThreshold)

# Get all app registrations in the Azure AD tenant
$appRegistrations = Get-AzADApplication

# Create an empty array to store results
$results = @()

# Loop through each app registration to check for expiring secrets and certificates
if ($appRegistrations) {
    foreach ($app in $appRegistrations) {
        # Get the app's service principal
        $servicePrincipal = Get-AzADServicePrincipal -ApplicationId $app.AppId

        # Continue only if service principal is not null
        if ($servicePrincipal) {
            # Get the app's credentials (both secrets and certificates)
            $credentials = Get-AzADServicePrincipalCredential -ObjectId $servicePrincipal.Id

            # Ensure credentials are not null
            if ($credentials) {
                foreach ($credential in $credentials) {
                    # Determine if the credential is a secret or a certificate based on the 'Type'
                    $type = if ($credential.Type -eq "AsymmetricX509Cert") { "Certificate" } else { "Secret" }

                    # Determine the status of the credential
                    if ($credential.EndDate -lt $currentDate) {
                        $status = "Expired"
                    } elseif ($credential.EndDate -lt $nearExpiryDate) {
                        $status = "Expiring Soon"
                    } else {
                        $status = "Valid"
                    }

                    # Add to results array
                    $results += [pscustomobject]@{
                        "AppName"    = $app.DisplayName
                        "Type"       = $type
                        "ExpiryDate" = $credential.EndDate
                        "Status"     = $status
                    }
                }
            }
        }
    }
}

# Create HTML table format for the results
$htmlBody = @"
<html>
<head>
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        table, th, td {
            border: 1px solid black;
        }
        th, td {
            padding: 10px;
            text-align: left;
        }
    </style>
</head>
<body>
    <h2>Expiring Secrets and Certificates Report</h2>
    <table>
        <tr>
            <th>App Name</th>
            <th>Type</th>
            <th>Expiry Date</th>
            <th>Status</th>
        </tr>
"@

# Append rows to the HTML table for each result
$results | ForEach-Object {
    $htmlBody += "<tr><td>$($_.AppName)</td><td>$($_.Type)</td><td>$($_.ExpiryDate)</td><td>$($_.Status)</td></tr>"
}

$htmlBody += @"
    </table>
</body>
</html>
"@

# Sending the email using System.Net.Mail
try {
    # Create the email message
    $emailMessage = New-Object system.net.mail.mailmessage
    $emailMessage.From = "email@viitorcloud.co"
    $emailMessage.To.Add("ankur51206@gmail.com")
    $emailMessage.Subject = "Expiring Secrets/Certificates Report"
    $emailMessage.Body = $htmlBody
    $emailMessage.IsBodyHtml = $true

    # Setup SMTP client
    $smtpClient = New-Object system.net.mail.smtpclient("email-smtp.us-east-1.amazonaws.com", 587)
    $smtpClient.EnableSsl = $true
    $smtpClient.Credentials = New-Object System.Net.NetworkCredential("AKIAT54DL5XT5MIQXWVP", "BBtqqWomtpGpWjf+HJThss18ui8AlWDnymnfFZcTKdqi")

    # Send the email
    $smtpClient.Send($emailMessage)

    Write-Host "Email sent successfully!"
} catch {
    Write-Host "Failed to send email: $_"
}

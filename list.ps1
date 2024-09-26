# Connect to Azure
Install-Module AzureAD
Connect-AzAccount

# Set the number of days to check for upcoming expiration (e.g., 30 days)
$daysToExpire = 30
$expiryDate = (Get-Date).AddDays($daysToExpire)

# Create an empty array to store the results
$results = @()

# Get all Azure AD applications
$applications = Get-AzureADApplication

foreach ($app in $applications) {
    # Get all key credentials (certificates) for the application
    $keyCredentials = Get-AzureADApplicationKeyCredential -ObjectId $app.ObjectId
    # Get all password credentials for the application
    $passwordCredentials = Get-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId

    # Check for expired or about-to-expire certificates
    foreach ($key in $keyCredentials) {
        if ($key.EndDate -lt (Get-Date)) {
            $results += [pscustomobject]@{
                Name            = $app.DisplayName
                'Already Expired' = $key.EndDate
                'Getting Expired' = ""
                CredentialType  = "Certificate"
            }
        } elseif ($key.EndDate -lt $expiryDate) {
            $results += [pscustomobject]@{
                Name            = $app.DisplayName
                'Already Expired' = ""
                'Getting Expired' = $key.EndDate
                CredentialType  = "Certificate"
            }
        }
    }

    # Check for expired or about-to-expire passwords
    foreach ($password in $passwordCredentials) {
        if ($password.EndDate -lt (Get-Date)) {
            $results += [pscustomobject]@{
                Name            = $app.DisplayName
                'Already Expired' = $password.EndDate
                'Getting Expired' = ""
                CredentialType  = "Password"
            }
        } elseif ($password.EndDate -lt $expiryDate) {
            $results += [pscustomobject]@{
                Name            = $app.DisplayName
                'Already Expired' = ""
                'Getting Expired' = $password.EndDate
                CredentialType  = "Password"
            }
        }
    }
}

# Output the result in a table format
$results | Format-Table -AutoSize -Property Name, 'Already Expired', 'Getting Expired', CredentialType

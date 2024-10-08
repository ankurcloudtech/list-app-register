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
foreach ($app in $appRegistrations) {
    # Get the app's service principal
    $servicePrincipal = Get-AzADServicePrincipal -ApplicationId $app.AppId

    # Continue only if service principal is not null
    if ($servicePrincipal) {
        # Get the app's credentials (both secrets and certificates)
        $credentials = Get-AzADServicePrincipalCredential -ObjectId $servicePrincipal.Id

        # Check each credential
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

# Display the results in a table format
$results | Sort-Object ExpiryDate | Format-Table -Property AppName, Type, ExpiryDate, Status -AutoSize

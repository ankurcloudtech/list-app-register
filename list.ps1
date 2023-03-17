# Connect to Azure
Connect-AzAccount

# Get a list of subscriptions
$subList = Get-AzSubscription

# Loop through each subscription
foreach ($subscription in $subList) {
    Write-Host "Subscription Name: $($subscription.Name)"
    Write-Host "Subscription ID: $($subscription.Id)"

    # Select the current subscription context
    Set-AzContext -Subscription $subscription.Id

    # Get a list of app registrations in the current subscription
    $appList = Get-AzADApplication

    # Loop through each app registration
    foreach ($appRegistration in $appList) {
        Write-Host "App Name: $($appRegistration.DisplayName)"
        Write-Host "App ID: $($appRegistration.ApplicationId)"

        # Check if the ObjectId or ApplicationId is empty
        if (!$appRegistration.Id -or !$appRegistration.ApplicationId) {
            Write-Host "ObjectId or ApplicationId is empty, skipping app registration"
            Write-Host ""
            continue
        }

        # Check if there are any expiring ClientSecrets
        $expiringSecrets = $appRegistration.PasswordCredentials | Where-Object {$_.EndDate -gt (Get-Date).AddDays(30)}

        # Check if there are any expiring Certificates
        $expiringCertificates = $appRegistration.KeyCredentials | Where-Object {$_.EndDate -gt (Get-Date).AddDays(30)}

        # Output the credential information if there are any expiring secrets or certificates
        if ($expiringSecrets.Count -gt 0 -or $expiringCertificates.Count -gt 0) {
            Write-Host "Expiring ClientSecrets:"
            foreach ($secret in $expiringSecrets) {
                $expiry_diff = ($secret.EndDate - (Get-Date)).Days
                Write-Host "- Secret: $($secret.KeyId), Expires: $($secret.EndDate), Days Remaining: $expiry_diff"
            }
            Write-Host ""

            Write-Host "Expiring Certificates:"
            foreach ($certificate in $expiringCertificates) {
                $expiry_diff = ($certificate.EndDate - (Get-Date)).Days
                Write-Host "- Certificate: $($certificate.KeyId), Expires: $($certificate.EndDate), Days Remaining: $expiry_diff"
            }
            Write-Host ""
        }
    }
}

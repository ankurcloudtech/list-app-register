Connect-AzureAD
$Applications = Get-AzureADApplication -all $true
$Logs = @()
Write-host "Applications with the Secrets and Certificates that expire in the next 30 days" -ForegroundColor Green

foreach ($app in $Applications) {
    $AppName = $app.DisplayName
    $AppID = $app.objectid
    $ApplID = $app.AppId
    $AppCreds = Get-AzureADApplication -ObjectId $AppID | select PasswordCredentials
    $secret = $AppCreds.PasswordCredentials

    foreach ($s in $secret) {
        $StartDate = $s.StartDate
        $EndDate = $s.EndDate
        $operation = $EndDate - (Get-Date)
        $ODays = $operation.Days

        if ($ODays -le 30 -and $ODays -ge 0) {
            $Log = [PSCustomObject]@{
                ApplicationName      = $AppName
                ApplicationID        = $ApplID
                SecretStartDate      = $StartDate
                SecretEndDate        = $EndDate
                CertificateStartDate = ""
                CertificateEndDate   = ""
                Owner                = ""
            }

            $Owner = Get-AzureADApplicationOwner -ObjectId $app.ObjectId
            if ($Owner.UserPrincipalName -eq $Null) {
                $Log.Owner = $Owner.DisplayName + " **<This is an Application>**"
            } else {
                $Log.Owner = $Owner.UserPrincipalName
            }

            $Logs += $Log
        }
    }
}

$Logs | Format-Table -AutoSize

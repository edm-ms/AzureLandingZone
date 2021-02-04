# // Start Azure Automation Login Using Service Principal
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

# // Set script variables
$storageAccountId = @{
    "eastus" = "storageAccountResourceID"
}
$workspaceId = "logWorkspaceResourceID"
$logWorkspace = Get-AzResource -ResourceId $workspaceId
$retentionDays = 14
$analyticsInterval = 10 # // processing interval for traffic analytics in minutes 10/60
$allSubs = Get-AzSubscription

# // Loop through all subscriptions
foreach ($sub in $allSubs) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null

    # // Find network watcher and NSG's in subscription
    $networkWatchers = Get-AzNetworkWatcher
    $nsgs = Get-AzNetworkSecurityGroup

    # // Loop through all NSGs
    foreach ($nsg in $nsgs) {
        # // Loop through all network watcher instances
        foreach ($nw in $networkWatchers) {
            # // If network watcher location and NSG location match continue
            if ($nw.Location -eq $nsg.Location) {
                # // If flow logs are not enabled for matched NSG enable them
                if ((Get-AzNetworkWatcherFlowLogStatus -NetworkWatcher $nw -TargetResourceId $nsg.id).Enabled -eq 0 ) {
                    Write-Host "Enabling flow logs for NSG:" $nsg.Name
                    Set-AzNetworkWatcherConfigFlowLog -NetworkWatcher $nw -TargetResourceId $nsg.Id `
                    -StorageAccountId $storageAccountId.($nsg.Location) -EnableFlowLog $true -RetentionInDays $retentionDays -FormatType Json -FormatVersion 2 `
                    -EnableTrafficAnalytics -TrafficAnalyticsInterval $analyticsInterval -WorkspaceResourceId $workspaceId `
                    -WorkspaceGUID $logWorkspace.Properties.customerId -WorkspaceLocation $logWorkspace.Location
                }
            }
        }
    }    

}
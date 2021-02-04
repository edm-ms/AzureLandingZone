$rgName = "NetworkWatcherRG"
$location = "eastus"
$allSubs = Get-AzSubscription
$tags = @{
    "Application Owner"="Network Ops";
    "Application Name"="Network Monitoring";
    "Contact Email"="netops@contoso.com";
    "Cost Center"="123456"
    "Criticality"="Tier2";
    "Data Classification"="Internal"
}

foreach ($sub in $allSubs) {
    Set-AzContext -SubscriptionId $sub.Id | Out-Null
    If (-not (Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue)) {
        Write-Host $sub.Name
        New-AzResourceGroup -Name $rgName -Location $location -Tags $tags 
    }
}
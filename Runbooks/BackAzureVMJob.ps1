workflow BackAzureVMJob
{
    Param
    (
    
    [parameter(Mandatory=$true)]
    [String]
    $ServiceName = 'lxlabvms',
     
    [parameter(Mandatory=$true)]
    [String]
    $VMName = 'lxlabvm02',
     
    [parameter(Mandatory=$true)]
    [String]
    $StorageAccountName = 'mvademo01',
     
    [parameter(Mandatory=$true)]
    [String]
    $backupContainerName = 'vmbackup'
    )
     
    # Get the credential from Asset
    $Cred = Get-AutomationPSCredential -Name 'xulei@xyjz.partner.onmschina.cn'
    
    # Connect to Azure
    # for mooncake: -Environment AzureChinaCloud
    Add-AzureAccount -Credential $Cred -Environment AzureChinaCloud
    
    # Select the subscription to work with 
    Select-AzureSubscription -SubscriptionName 'Microsoft Azure Enterprise 试用版'
    
    # Set CurrentStorageAccount for the Azure Subscription
    Set-AzureSubscription -Environment AzureChinaCloud -SubscriptionName 'Microsoft Azure Enterprise 试用版' -CurrentStorageAccount $StorageAccountName
  
    # Backup Azure VM
    Backup-AzureVM -serviceName $ServiceName -VMName $VMName -backupContainerName $backupContainerName -backupStorageAccountName $StorageAccountName –includeDataDisks

}
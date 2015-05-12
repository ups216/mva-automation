workflow Batch-Backup-AzureVMs
{
    # Get the credential from Asset
    $Cred = Get-AutomationPSCredential -Name 'xulei@xyjz.partner.onmschina.cn'
    
    # Connect to Azure
    # for mooncake: -Environment AzureChinaCloud
    Add-AzureAccount -Credential $Cred -Environment AzureChinaCloud
    
    # Select the subscription to work with 
    Select-AzureSubscription -SubscriptionName 'Microsoft Azure Enterprise 试用版'
    
    $Params = @{
        "ServiceName"          = "lxlabvms";
        "VMName"               = "lxlabvm01"; 
        "StorageAccountName"  = "mvademo01";
        "backupContainerName"  = "vmbackup"
        }
    Start-AzureAutomationRunbook -AutomationAccountName 'lxdemoaccount02' -Name 'backazurevmjob' -Parameters $Params
    
     $Params = @{
        "ServiceName"          = "lxlabvms";
        "VMName"               = "lxlabvm02"; 
        "StorageAccountName"  = "mvademo01";
        "backupContainerName"  = "vmbackup"
        }
    Start-AzureAutomationRunbook -AutomationAccountName 'lxdemoaccount02' -Name 'backazurevmjob' -Parameters $Params
    
     $Params = @{
        "ServiceName"          = "lxlabvms";
        "VMName"               = "lxlabvm03"; 
        "StorageAccountName"  = "mvademo01";
        "backupContainerName"  = "vmbackup"
        }
    Start-AzureAutomationRunbook -AutomationAccountName 'lxdemoaccount02' -Name 'backazurevmjob' -Parameters $Params
}
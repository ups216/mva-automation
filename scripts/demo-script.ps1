Add-AzureAccount -Environment AzureChinaCloud
Start-AzureAutomationRunbook -AutomationAccountName 'lxdemoaccount01' -Name 'MVADemo01-StartTrace'
Start-AzureAutomationRunbook -AutomationAccountName 'lxdemoaccount01' -Name 'MVADemo01-StopTrace'
Start-AzureAutomationRunbook -AutomationAccountName 'lxdemoaccount01' -Name 'MVADemo01-UploadLogToBlob'
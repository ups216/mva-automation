<#
.SYNOPSIS 
    This runbook calls a command inside of an Azure VM

.DESCRIPTION
    This runbook connects into an Azure virtual machine and runs the PowerShell command passed in.
    It has a dependency on the Connect-AzureVM runbook to set up the connection to the virtual machine
    before the command can be run.

.PARAMETER AzureSubscriptionName
    Name of the Azure subscription to connect to
    
.PARAMETER AzureOrgIdCredential
    A credential containing an Org Id username / password with access to this Azure subscription.

	If invoking this runbook inline from within another runbook, pass a PSCredential for this parameter.

	If starting this runbook using Start-AzureAutomationRunbook, or via the Azure portal UI, pass as a string the
	name of an Azure Automation PSCredential asset instead. Azure Automation will automatically grab the asset with
	that name and pass it into the runbook.
    
.PARAMETER ServiceName
    Name of the cloud service where the VM is located.

.PARAMETER VMName    
    Name of the virtual machine that you want to connect to  

.PARAMETER VMCredentialName
    Name of a PowerShell credential asset that is stored in the Automation service.
    This credential should have access to the virtual machine.
 
.PARAMETER PSCommand
    PowerShell command that you want to run inside the Azure virtual machine.

.EXAMPLE
    Invoke-PSCommandSample -AzureSubscriptionName "Visual Studio Ultimate with MSDN" -ServiceName "Finance" -VMName "WebServer01" -VMCredentialName "FinanceCredentials" -PSCommand "ipconfig /all" -AzureOrgIdCredential $cred

.NOTES
    AUTHOR: System Center Automation Team
    LASTEDIT: Aug 14, 2014 
#>
Workflow MVADemo01-StopTrace
{
    Param
    (
        [parameter(Mandatory=$false)]
        [String]
        $AzureSubscriptionName = 'Microsoft Azure Enterprise 试用版',

		[parameter(Mandatory=$false)]
        [String]
        $AzureOrgIdCredential = 'xulei@xyjz.partner.onmschina.cn',
        
        [parameter(Mandatory=$false)]
        [String]
        $ServiceName = 'mva-demo01',
        
        [parameter(Mandatory=$false)]
        [String]
        $VMName = 'mva-demo01',  
        
        [parameter(Mandatory=$false)]
        [String]
        $VMCredentialName = 'vm-credential-leixu',
        
        [parameter(Mandatory=$false)]
        [String]
        $PSCommand  ='c:\scripts\DefaultAppPool-StopTrace.ps1'
    )
    
    #set values
    $AzureSubscriptionName = 'Microsoft Azure Enterprise 试用版'
    $AzureOrgIdCredential = 'xulei@xyjz.partner.onmschina.cn'
    $ServiceName = 'mva-demo01'
    $VMName = 'mva-demo01' 
    $VMCredentialName = 'vm-credential-leixu'
    $PSCommand  ='c:\scripts\DefaultAppPool-StopTrace.ps1'
    
    # Get credentials to Azure VM
    $Credential = Get-AutomationPSCredential -Name $VMCredentialName    
	if ($Credential -eq $null)
    {
        throw "Could not retrieve '$VMCredentialName' credential asset. Check that you created this asset in the Automation service."
    }     
    
	# Set up Azure connection by calling the Connect-Azure runbook. You should call this runbook after
	# every CheckPoint-WorkFlow to ensure that the management certificate is available if this runbook
	# gets interrupted and starts from the last checkpoint
    $Uri = Connect-AzureVM -AzureSubscriptionName $AzureSubscriptionName -AzureOrgIdCredential $AzureOrgIdCredential -ServiceName $ServiceName -VMName $VMName 
    
	# Run a command on the Azure VM
    $PSCommandResult = InlineScript {        
        Invoke-command -ConnectionUri $Using:Uri -credential $Using:Credential -ScriptBlock {
            Invoke-Expression $Args[0]
        } -Args $Using:PSCommand

    }
	
	$PSCommandResult
}

function Copy-AzureBlob
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                        Position=0)]
        [string] $srcBlobName,
        # Param2 help description
        [Parameter(Mandatory=$true)]
        [string] $srcContainerName,
        # Param2 help description
        [Parameter(Mandatory=$true)]
        [object] $srcContext,
        [Parameter(Mandatory=$true)]
        [string] $dstBlobName,
        [Parameter(Mandatory=$true)]
        [string] $dstContainerName,
        [Parameter(Mandatory=$true)]
        [object] $dstContext
    )
    Try
    {
        $copyContext = Start-AzureStorageBlobCopy -SrcBlob $srcBlobName -SrcContainer $srcContainerName -DestContainer $dstContainerName -DestBlob $dstBlobName -Context $srcContext -DestContext $dstContext
        $status = Get-AzureStorageBlobCopyState -Blob $dstBlobName -Container $dstContainerName -Context $dstContext -WaitForComplete
        $srcBlob = get-azurestorageblob -Container $srcContainerName -Context $srcContext -Blob $srcBlobName
        $bckBlob = get-azurestorageblob -Container $dstContainerName -Context $dstContext -Blob $dstBlobName
        if ($srcBlob.Length -ne $bckBlob.Length -or $status.Status -ne 'Success')
        {
            write-error "Error copying $srcBlobName to $dstContainerName\$dstBlobName. Copy Status: $($status.Status)"
            return 1;
        }
        else
        {
            return 0;
        }
    }
    catch
    {
        write-error "Exception copying blob $($_.Exception.Message)"
        return 2;
    }
}

function Backup-AzureVMDisk
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   
                   Position=0)]
        $disk, #cannot type it since we have different types for SO and Data disks
        [string] $vmName,
        [string] $stamp,
        [Parameter(Mandatory=$true)]
        [object] $srcContext,
        [Parameter(Mandatory=$true)]
        [string] $backupContainerName,
        [Parameter(Mandatory=$true)]
        [object] $dstContext

    )

        $blobName = $disk.MediaLink.Segments[$disk.MediaLink.Segments.Count-1]
        $normalizedBlobName = $blobName.Replace('-','')
        $backupDiskName = "$vmName-$stamp-$normalizedBlobName"
        $srcContainerName = $disk.MediaLink.AbsolutePath.Replace("/$blobName",'').Substring(1)
        $copyResult = Copy-AzureBlob -srcBlobName $blobName -srcContainerName $srcContainerName -srcContext $srcContext -dstBlobName $backupDiskName -dstContainerName $backupContainerName -dstContext $dstContext
        return $copyResult;
}


<#
.Synopsis
   Creates a copy of the named virtual machines optionally including the data disks.
.DESCRIPTION
      Creates a copy of the named virtual machines optionally including the data disks. The backup disks will be time stamped following this schema
   <vm name>-<yyyyMMdd>-<HHmm>-<original blob name>. The detsination storage account name and container must be specified. The function works under the following assumptions:
   - the Azure module has been imported
   - the current subscription contains the VM to be backed up
   - the current subscription contains the target storage account  
.EXAMPLE
    Import-Module Azure
    Get-AzureAccount
    Select-AzureSubscription -SubscriptionName 'QND Subscription'
    Backup-AzureVM -serviceName 'QNDBackup' -vmName 'QNDTest1' -backupContainerName 'backup' -dstStorageAccountName 'qndvms' -includeDataDisks

    The sample creates a backup copy of the VM called QNDTest1 deployed in service QNDBackup and saves all the disks in the container named 'backup' 
    in the storage acocunt 'qndvms'

#>
function Backup-AzureVM
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true)]
        [string] $serviceName,
        [Parameter(Mandatory=$true)]
        [string] $vmName,
        [Parameter(Mandatory=$true)]
        [string] $backupContainerName,
        [Parameter(Mandatory=$true)]
        [string] $backupStorageAccountName,
        [switch] $includeDataDisks
    )

    try {

    $timeStamp = (get-date).ToString('yyyyMMdd-HHmm')
    $vm = get-Azurevm -name $vmName -ServiceName $serviceName
    if (! $vm)
    {
        write-error "Virtual machine $vmName not found in service $serviceName"
        return 1;
    }
    $osDisk = Get-AzureOSDisk -VM $vm
    $dataDisks = Get-AzureDataDisk -VM $vm
    $dstContext = new-azurestoragecontext -Environment 'AzureChinaCloud' -StorageAccountName $backupStorageAccountName -StorageAccountKey (Get-AzureStorageKey -StorageAccountName $backupStorageAccountName).Primary
    Write-Output "========================================================="
    Write-Output $dstContext

    $srcStgAccountName = $osdisk.MediaLink.Host -split "\." | select -First 1
    $srcContext = new-azurestoragecontext -Environment 'AzureChinaCloud' -StorageAccountName $srcStgAccountName -StorageAccountKey (Get-AzureStorageKey -StorageAccountName $srcStgAccountName).Primary
    Write-Output "========================================================="
    Write-Output $srcContext

    $bckContainer = Get-AzureStorageContainer -Name $backupContainerName -Context $dstContext -ErrorAction Stop

    }
    catch [Microsoft.WindowsAzure.Commands.Storage.Common.ResourceNotFoundException] {
        Write-Error "Resource doesn't exists. $($_.Exception.Message)"
        return 2; 
    }
    catch {
        write-error "Generic exception getting resources info $($_.Exception.Message)"
        return 1;
    }

    try {
        if ($vm.PowerState -eq 'Started')
        {
            $vmStarted = $true
            Write-Output "========================================================="
            Stop-AzureVM -VM $vm.VM -StayProvisioned -ServiceName $vm.ServiceName
        }
        else
        {
            $vmStarted = $false
        }

        #the backup disk name must be coded so we can have a link to the original disk
        #copy OS Disk
        $vmNormalizedName = $vm.InstanceName
        $copyResult = Backup-AzureVMDisk -disk $osDisk -vmName $vmNormalizedName -stamp $timeStamp -srcContext $srcContext -backupContainerName $backupContainerName -dstContext $dstContext
        if ($copyResult -eq 0)
        {
            Write-Output "========================================================="
            Write-Output "Successfully made OS disk backup copy $($osDisk.DiskName)"
        }
        else
        {
            throw [System.Exception] "error copying OS disk"
        }

        if ($includeDataDisks)
        {
            foreach($disk in $dataDisks)
            {
                $copyResult = Backup-AzureVMDisk -disk $disk -vmName $vmNormalizedName -stamp $timeStamp -srcContext $srcContext -backupContainerName $backupContainerName -dstContext $dstContext
                if ($copyResult -eq 0)
                {
                    Write-Output "========================================================="
                    Write-Output "Successfully made data disk backup copy $($disk.DiskName)"
                }
                else
                {
                    throw [System.Exception] "error copying Data disk $($disk.DiskName) "
                }                
            }
        }
        return 0;
    }
    catch {
        write-error "Generic exception making backup copy $($_.Exception.Message)"
        return 1;
    }
    finally {
        if ($vmStarted)
        {
            Write-Output "========================================================="
            Start-AzureVM -VM $vm.VM -ServiceName $vm.ServiceName
        }
        
    }
}

Export-ModuleMember -function Backup-AzureVM













# RUN AS ADMINISTRATOR
# https://nils.schimmelmann.us/post/153541254987/intel-smart-response-technology-vs-windows-10

# Tiers in the storage pool
$SSDTierName = "SSD Tier"
$HDDTierName = "HDD Tier"

# Virtual Disk Name made up of disks in both tiers
$TieredDiskName = "Data"

#Change to suit - drive later and the label name
$TieredDriveLetter = "M"
$TieredDriveLabel = "Data"

$StoragePoolName = "Main Pool"

# List all the disks that are available to pool
Get-PhysicalDisk -CanPool $True | ft FriendlyName, OperationalStatus, Size, MediaType

# Store that into a variable
$PhysicalDisks = (Get-PhysicalDisk -CanPool $True)

#Create a new Storage Pool using the disks in variable $PhysicalDisks with a name of My Storage Pool
New-StoragePool -PhysicalDisks $PhysicalDisks -StorageSubSystemFriendlyName "Windows Storage*" -FriendlyName $StoragePoolName -ResiliencySettingNameDefault Mirror -ProvisioningTypeDefault Thin

#Create two tiers in the Storage Pool created. One for SSD disks and one for HDD disks
# SSD interleave - testing with Filesystem Allocation Unit Size
$SSDTier = New-StorageTier -StoragePoolFriendlyName $StoragePoolName -FriendlyName $SSDTierName -MediaType SSD 
$HDDTier = New-StorageTier -StoragePoolFriendlyName $StoragePoolName -FriendlyName $HDDTierName -MediaType HDD

#Calculate tier sizes within this storage pool
$SSDTierSize = (Get-StorageTierSupportedSize -FriendlyName $SSDTierName).TierSizeMax
$HDDTierSize = (Get-StorageTierSupportedSize -FriendlyName $HDDTierName).TierSizeMax 

New-VirtualDisk -StoragePoolFriendlyName $StoragePoolName -FriendlyName $TieredDiskName -StorageTiers @($SSDTier, $HDDTier) -StorageTierSizes @($SSDTierSize, $HDDTierSize) -AutoNumberOfColumns

Get-VirtualDisk $TieredDiskName | Get-Disk | Initialize-Disk -PartitionStyle GPT
# This will be Partition 2.  Storage pool metadata is in Partition 1
Get-VirtualDisk $TieredDiskName | Get-Disk | New-Partition -DriveLetter $TieredDriveLetter -UseMaximumSize
Initialize-Volume -DriveLetter $TieredDriveLetter -FileSystem ReFS -NewFileSystemLabel $TieredDriveLabel
Get-Volume -DriveLetter $TieredDriveLetter

Write-Output "Operation complete"
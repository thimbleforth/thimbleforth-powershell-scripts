# To Unmount the EFI Partition afterward

# This is easier if you kept the same terminal open as Mount-SystemPartition.ps1 ...
# Just copy this code into the same terminal. It's late and I'm too unbothered to properly send information between the two files and/or rewrite to be smarter.
try {
  Remove-PartitionAccessPath -DiskNumber $efiPartition.DiskNumber -PartitionNumber $efiPartition.PartitionNumber -AccessPath $driveLetter
  Write-Host "EFI partition unmounted from $driveLetter"
} catch {
  Write-Error "Failed to remove the PartitionAccessPath. Start praying. `n $($error[0])"
}

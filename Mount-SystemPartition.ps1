# Here’s a safe (ergo, it will not actually change any files on its own) PowerShell method to mount the EFI System Partition (ESP) in Windows so you can view or edit its contents.
# ⚠ Warning: The EFI partition contains boot files. Editing or deleting them can make your system unbootable. Only proceed if you know what you’re doing.
# This method works on Windows 10 and 11 without third-party tools.

# Run PowerShell as Administrator to execute these commands:
# Keep the terminal open until you're done and you unmount the partition from the drive letter using the Unmount-SystemPartition.ps1 script.
# That just makes life easier for you.

# Get the EFI partition
try { 
  $efiPartition = Get-Partition -DiskNumber 0 | Where-Object { $_.GptType -eq '{C12A7328-F81F-11D2-BA4B-00A0C93EC93B}' }
} catch {
  Write-Error "Failed getting and setting `$efiPartition: `n $($error[0])"
}

# Assign a drive letter (example: Z:)
try {
  $driveLetter = "Z:"
  Add-PartitionAccessPath -DiskNumber $efiPartition.DiskNumber -PartitionNumber $efiPartition.PartitionNumber -AccessPath $driveLetter
  Write-Host "EFI partition mounted to $driveLetter"
} catch {
  Write-Error "Failed to mount drive letter $($driveletter) `n $($error[0]"
}


# Ta da! You now have Z: mounted and accessible via PowerShell or in Explorer.
# Which means you can `cd Z:\EFI` and go to town on those leftover boot files from that botched Linux dualboot you don't want to admit happened.

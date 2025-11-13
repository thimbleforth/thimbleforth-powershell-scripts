# thimbleforth-powershell-scripts
Some random Powershell scripts I've cooked up over the years.

## Table of Contents

| File | Purpose |
| --- | ---|
| Get-AllDcimImages.ps1 | Recursively walks over an iOS-formatted DCIM folder, grabs all of the media files, and copies them into another folder. Does hash checks over every single file and lets you choose to overwrite or not.|
| DailyTools.ps1 | Function bindings for other Windows tools with hardcoded syntax. Cuz I hate remembering all the different tools' flags and functionality. |
| Mount-SystemPartition.ps1 | Mounts the SYSTEM partition as Z:, allowing you to edit or delete EFI records. Useful for cleaning up botched Linux dualboots. |
| Dismount-SystemPartition.ps1 | Undoes what Mount-" does. |

---
## LLM usage
Some of these scripts have been built with assistance of LLM's. I'd be lying if I said I remembered which ones were which. No, I don't care, they're pretty good at it nowadays. Your mileage may vary. But if they're sitting in here, they're scripts I have actually used at one point in time to accomplish a task successfully. These scripts are usually small. Go read the source if you're curious about what it actually does. You shouldn't be running random scripts from GitHub anyway without -somebody- doing due diligence. 😝

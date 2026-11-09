# Disable Chrome Auto-Update Script

A Windows PowerShell script for disabling Google Chrome's automatic update mechanisms. It changes Google Update policy keys, disables matching update services and scheduled tasks when present, and adds write-deny permissions to existing Google Update directories.

> **This is a maintenance and compatibility workaround, not a security recommendation.** Chrome updates include security fixes. Keeping an outdated browser online can expose you to known vulnerabilities. Use this only for a specific, temporary reason, and plan how you will install updates manually or re-enable updating.

## Why disable Chrome updates?

Chrome updates are normally important: they deliver security patches, bug fixes, and compatibility improvements. There are, however, situations where an administrator or developer may need to hold a browser version temporarily, such as:

- testing a web application or managed environment against a fixed browser build;
- investigating a regression or compatibility issue before approving a newer release;
- maintaining a controlled test machine or kiosk with a documented update process.

This script applies machine-wide changes, so it is generally unsuitable for an ordinary daily-use computer. Prefer supported enterprise update policies or managed browser configuration when available. Do not treat update blocking as a way to avoid browser changes indefinitely.

## Manifest V2 (MV2) context

Some users have considered holding Chrome at an older version to keep Manifest V2 browser extensions working. Manifest V2 is an older Chrome extension platform; Chrome has been transitioning extensions toward Manifest V3. Extension platform changes can affect extension availability and behavior, so teams may need time to test replacements or migration plans.

Blocking browser updates is **not a reliable or safe long-term MV2 solution**. It also prevents security and stability fixes, and Chrome or extension behavior may change independently. Extension support can vary by Chrome release, policy, and distribution channel. Check current Chrome and extension documentation for the status that applies to your environment, and prefer migrating to a supported extension or using officially supported enterprise controls where applicable. This README does not promise that any particular Chrome version will continue to run MV2 extensions.

## What the script changes

When run with administrator privileges, `disablechrome.ps1` attempts to:

1. Write Google Update policy values under both 64-bit and 32-bit registry policy paths, including the Chrome application GUID setting.
2. Stop and disable the `gupdate` and `gupdatem` services if they are present.
3. Disable Google update-related scheduled tasks that it finds.
4. Add write-deny ACL entries to existing `Google\Update` directories under Program Files.
5. Print a verification summary.

The script does not guarantee that all update mechanisms are present, found, or successfully disabled. Output varies by Windows version and Chrome installation. Review the script before running it to understand the exact changes.

## Requirements

- Windows with PowerShell and the ScheduledTasks module available.
- An administrator account. The script makes machine-level registry, service, task, and filesystem permission changes.
- A specific reason to pause updates and a plan for restoring updates or manually installing security releases.

## Tutorial: run the script

1. Download `disablechrome.ps1` from this repository and save it in a known folder.
2. Open **Windows PowerShell** using **Run as administrator**.
3. In that PowerShell window, allow scripts for this process only:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass
   ```

   If prompted, enter `Y` to confirm. `-Scope Process` applies only to the current PowerShell process; closing the window ends the setting. It does not permanently change the machine or user execution policy. Only use this for a script you trust and have reviewed.
4. Change to the directory containing the script and run it. For example, if it is on your Desktop:

   ```powershell
   Set-Location "$HOME\Desktop"
   .\disablechrome.ps1
   ```
5. Wait for `===== 完成 =====` and read the verification output. The script's status messages are in Chinese; the notes below explain the key messages.

## Reading the output

- `[策略] 已写入` means policy values were written. The verification section may show `UpdateDefault=0` and `ChromeGUID=0`.
- `[服务] 未找到` means that service was not found on this machine; it does not necessarily mean the script failed.
- `[任务] 未找到 Google 计划任务` means no matching tasks were found by the script's query.
- `[权限] 目录不存在，跳过` means that update directory does not exist, so the script skipped it.
- `[权限] 已拒绝写入` means the script added deny-write permissions to that update directory. This may interfere with Google updater maintenance.

Treat the output as a best-effort report, not a guarantee that Chrome can no longer update. If something fails, do not respond by recursively taking ownership of the entire Google folder or denying access to `Everyone`.

## Re-enable updates and recovery

The script does not include an automatic undo operation. Before running it, record existing policy values, service startup types, scheduled task states, and ACLs. Existing settings may have been configured by an administrator or another application.

To restore normal updating, remove or restore only the settings changed by this script: the Google Update policy values, service startup states, scheduled task states, and the script-added deny-write ACL entries on the specific `Google\Update` directories. Restore your recorded original values rather than assuming every service or task should be enabled. If you cannot identify the exact ACL entries or policy values to restore, stop and ask a Windows administrator for help.

> Do not run broad recursive permission commands against `C:\Program Files (x86)\Google`. In particular, a recursive deny rule for `Everyone` can prevent applications and administrators from accessing files and may damage Chrome or other Google software.

## Disclaimer

Use at your own risk. This script changes machine-wide Windows configuration and may reduce browser security or interfere with Google software. Test only on systems you are authorized to administer, maintain a recovery plan, and re-enable updates as soon as the temporary need has ended.

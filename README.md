
# Disable Chrome Auto-Update Script

This repository contains a Windows PowerShell script that disables Chrome’s automatic update behavior by modifying Google Update policy entries, disabling related services and scheduled tasks, and applying deny-write permissions to the Google Update folders when they exist.

This is a practical workaround for controlled or testing environments, not something to use casually on a normal personal computer.

Why disable Chrome updates?

Chrome updates are important because they patch vulnerabilities, improve stability, and keep browser features compatible with modern web standards. In some cases, however, users or administrators may need to temporarily freeze Chrome at a specific version, such as:

- validating a web application against a fixed browser build
- investigating a compatibility regression before installing a newer release
- managing a kiosk, test machine, or locked-down environment with a controlled update policy

The downside is that disabling updates also disables the security and reliability fixes that Chrome regularly delivers. Use this only when there is a clear operational reason and a plan to re-enable updates later.

Manifest V2 (MV2) context

Some users also disable updates to keep Chrome on an older version because of Manifest V2 extension compatibility. Manifest V2 is the older Chrome extension model, while Manifest V3 is the newer system that Chrome has been transitioning toward.

This is one reason people may want to delay Chrome updates. However, blocking updates is not a safe or durable MV2 strategy. It leaves the browser exposed to known vulnerabilities, may break future compatibility, and does not guarantee that MV2 extensions will continue to work indefinitely. If you need MV2 support, it is better to review the current Chrome and extension documentation, test migration paths, and use supported enterprise or managed browser controls when available.

What the script does

When run as Administrator, the script attempts to:

1. Write Google Update policy values under both 32-bit and 64-bit registry locations.
2. Stop and disable the Google update services if present.
3. Disable Google-related scheduled tasks.
4. Add deny-write permissions to Google Update folders under Program Files.
5. Print a verification summary at the end.

This is a best-effort script. It may not find every Chrome installation, every service, or every scheduled task on every Windows system.

Requirements

- Windows
- PowerShell
- Administrator rights
- A clear reason to temporarily freeze Chrome updates

How to run

Open PowerShell as Administrator and allow scripts for the current session only:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Then run:

```powershell
Set-Location "$HOME\Desktop"
.\disablechrome.ps1
```

If prompted, confirm with Y.

What the output means

- “已写入” / “written” means the Google Update registry policy was created or updated.
- “未找到” / “not found” means the service or task was not detected on this machine.
- “目录不存在，跳过” / “directory does not exist, skipping” means the update folder was not present.
- “已拒绝写入” / “write denied” means the script added a deny rule to that Google Update directory.

Important warning

This script changes machine-wide Windows settings and affects browser update behavior. It may leave the system in a less secure state. Always back up or document the current registry, service, task, and ACL state before making such changes.

Recovery and re-enabling updates

There is no automatic undo in this script. To restore normal Chrome updating, you should revert the policy values, service startup settings, scheduled tasks, and ACL entries you changed. Do not operate broadly on the whole Google installation folder.

Do not run commands that recursively take ownership of the entire Google directory or deny access to Everyone. Such actions can interfere with Chrome or other Google software and may be difficult to reverse safely.

Disclaimer

Use this script only on systems you are authorized to manage. This repository provides a workaround, not a recommended permanent configuration. If you need long-term support or a stable enterprise browser deployment, prefer official Chrome management, enterprise policy controls, and a proper update process.


# 必须使用管理员权限运行
$ErrorActionPreference = "Continue"

Write-Host "===== 开始禁用 Chrome 更新 =====" -ForegroundColor Cyan

# 1. 写入禁更新策略（覆盖 64 位与 32 位 Chrome 路径）
$paths = @(
    "HKLM:\SOFTWARE\Policies\Google\Update",
    "HKLM:\SOFTWARE\Wow6432Node\Policies\Google\Update"
)
foreach ($p in $paths) {
    New-Item -Path $p -Force | Out-Null
    Set-ItemProperty $p -Name "UpdateDefault" -Value 0 -Type DWord
    Set-ItemProperty $p -Name "Update{8A69D345-D564-463C-AFF1-A69D9E530F96}" -Value 0 -Type DWord
    Set-ItemProperty $p -Name "AutoUpdateCheckPeriodMinutes" -Value 0 -Type DWord
    Set-ItemProperty $p -Name "DisableAutoUpdateChecksCheckboxValue" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "[策略] 已写入: $p" -ForegroundColor Green
}

# 2. 停用更新服务
foreach ($n in "gupdate","gupdatem") {
    Get-Service -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
        Stop-Service $_ -Force -ErrorAction SilentlyContinue
        Set-Service $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "[服务] 已停止并禁用: $($_.Name)" -ForegroundColor Green
    }
}

# 3. 禁用计划任务
Get-ScheduledTask -TaskPath "\Google\*" -ErrorAction SilentlyContinue | ForEach-Object {
    Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue | Out-Null
    Write-Host "[任务] 已禁用: $($_.TaskPath)$($_.TaskName)" -ForegroundColor Green
}
Get-ScheduledTask -TaskName "GoogleUpdate*","GoogleUpdater*" -ErrorAction SilentlyContinue | ForEach-Object {
    Disable-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath -ErrorAction SilentlyContinue | Out-Null
    Write-Host "[任务] 已禁用: $($_.TaskPath)$($_.TaskName)" -ForegroundColor Green
}

# 4. 拒绝写入 Google Update 目录
$updateDirs = @(
    "${env:ProgramFiles}\Google\Update",
    "${env:ProgramFiles(x86)}\Google\Update"
)
foreach ($dir in $updateDirs) {
    if (Test-Path $dir) {
        icacls $dir /deny "Users:(OI)(CI)(WD,AD,WEA,WA)" /T /C 2>$null | Out-Null
        icacls $dir /deny "Authenticated Users:(OI)(CI)(WD,AD,WEA,WA)" /T /C 2>$null | Out-Null
        Write-Host "[权限] 已拒绝写入: $dir" -ForegroundColor Green
    } else {
        Write-Host "[权限] 目录不存在，跳过: $dir" -ForegroundColor Yellow
    }
}

# ===== 执行结果汇总 =====
Write-Host "`n===== 执行结果验证 =====" -ForegroundColor Cyan

# 策略验证
foreach ($p in $paths) {
    if (Test-Path $p) {
        $v1 = (Get-ItemProperty $p -Name "UpdateDefault" -ErrorAction SilentlyContinue).UpdateDefault
        $v2 = (Get-ItemProperty $p -Name "Update{8A69D345-D564-463C-AFF1-A69D9E530F96}" -ErrorAction SilentlyContinue)."Update{8A69D345-D564-463C-AFF1-A69D9E530F96}"
        Write-Host "[策略] $p  UpdateDefault=$v1  ChromeGUID=$v2" -ForegroundColor White
    } else {
        Write-Host "[策略] 未找到: $p" -ForegroundColor Red
    }
}

# 服务验证
foreach ($n in "gupdate","gupdatem") {
    $svc = Get-Service -Name $n -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Host "[服务] $($svc.Name)  Status=$($svc.Status)  StartType=$($svc.StartType)" -ForegroundColor White
    } else {
        Write-Host "[服务] 未找到: $n" -ForegroundColor Yellow
    }
}

# 计划任务验证
$tasks = Get-ScheduledTask -TaskPath "\Google\*" -ErrorAction SilentlyContinue
if ($tasks) {
    foreach ($t in $tasks) {
        Write-Host "[任务] $($t.TaskPath)$($t.TaskName)  State=$($t.State)" -ForegroundColor White
    }
} else {
    Write-Host "[任务] 未找到 Google 计划任务" -ForegroundColor Yellow
}

# 目录权限验证
foreach ($dir in $updateDirs) {
    if (Test-Path $dir) {
        $acl = (icacls $dir 2>$null) -join " "
        if ($acl -match "DENY|拒绝") {
            Write-Host "[权限] $dir 已包含拒绝规则" -ForegroundColor White
        } else {
            Write-Host "[权限] $dir 未检测到拒绝规则" -ForegroundColor Red
        }
    }
}

Write-Host "`n===== 完成 =====" -ForegroundColor Cyan
Write-Host "按任意键退出..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
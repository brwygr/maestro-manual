<#
.SYNOPSIS
    跑 Maestro 用例的一键封装。

.DESCRIPTION
    把"选套件 / 选模块 / 出报告"这些参数固定下来，避免每次手敲长命令。
    不带参数 = 跑 p0 冒烟（约 40 秒）。

.EXAMPLE
    .\run.ps1
    跑冒烟套件（config-smoke.yaml，只含 p0）

.EXAMPLE
    .\run.ps1 -Suite all
    跑全量

.EXAMPLE
    .\run.ps1 -Flow flows\04_wallet_receive.yaml
    只跑一条

.EXAMPLE
    .\run.ps1 -Tags wallet
    只跑打了 wallet 标签的

.EXAMPLE
    .\run.ps1 -Suite smoke -Html
    跑完自动打开 HTML 报告
#>
param(
    [ValidateSet('smoke', 'regression', 'all')]
    [string]$Suite = 'smoke',

    [string]$Flow,

    [string[]]$Tags,

    [switch]$Html
)

$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot

# 关掉统计和更新检查，输出干净一些
$env:MAESTRO_CLI_NO_ANALYTICS = '1'
$env:MAESTRO_CLI_ANALYSIS_NOTIFICATION_DISABLED = '1'
$env:MAESTRO_DISABLE_UPDATE_CHECK = '1'

# 优先用装了 JDK17 的包装器；找不到就走 PATH
$maestro = 'E:\maestro\maestro.cmd'
if (-not (Test-Path $maestro)) { $maestro = 'maestro' }

# 注意：不能叫 $args，那是 PowerShell 保留变量
$cmdArgs = @('test')

if ($Flow) {
    $cmdArgs += (Join-Path $here $Flow)
}
else {
    $config = switch ($Suite) {
        'smoke' { 'config-smoke.yaml' }
        'regression' { 'config-regression.yaml' }
        default { 'config.yaml' }
    }
    $configPath = Join-Path $here $config
    if (-not (Test-Path $configPath)) {
        throw "找不到配置文件：$configPath"
    }
    $cmdArgs += @('--config', $configPath)
}

if ($Tags) { $cmdArgs += "--include-tags=$($Tags -join ',')" }

$reportPath = $null
if ($Html) {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $reportPath = Join-Path $here ".artifacts\report-$stamp.html"
    New-Item -ItemType Directory -Force -Path (Split-Path $reportPath) | Out-Null
    $cmdArgs += @('--format', 'HTML', '--output', $reportPath)
}

Write-Host ">>> $maestro $($cmdArgs -join ' ')" -ForegroundColor Cyan
& $maestro @cmdArgs
$code = $LASTEXITCODE

if ($Html -and $reportPath -and (Test-Path $reportPath)) {
    Start-Process $reportPath
}

if ($code -eq 0) { Write-Host ">>> 全部通过" -ForegroundColor Green }
else { Write-Host ">>> 有失败，看上面的输出和 .artifacts 目录" -ForegroundColor Yellow }

exit $code

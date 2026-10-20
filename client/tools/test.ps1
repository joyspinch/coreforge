# coreforge 逻辑套件（无头）：编译 tests/ 里的 logic.zan，跑 240 条断言。
#
# 断言全在 packages/Zan.Game.Factory（逻辑层）里，界面壳不参与——所以这套用例
# 与 GUI 无关，改逻辑层后随时可以跑。
param(
    [string]$Compiler = $env:ZANC,
    [string]$PackageProject = ''
)
$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$repo = Split-Path -Parent $project
$tests = Join-Path $project 'tests'
if (-not $Compiler) {
    $local = if ($env:ZAN_HOME) { Join-Path $env:ZAN_HOME 'build/zanc.exe' } else { '' }
    if ($local -and (Test-Path $local)) { $Compiler = $local } else { $Compiler = (Get-Command zanc -ErrorAction Stop).Source }
}
if (-not $PackageProject) { if ($env:ZAN_HOME) { $PackageProject = $env:ZAN_HOME } else { throw '需要 $env:ZAN_HOME 指向 zan-lang 仓库（公共包在它的 packages/ 下）' } }
& python (Join-Path $tests 'verify.py') --compiler $Compiler --package-project $PackageProject
if ($LASTEXITCODE -ne 0) { throw "coreforge logic suite failed ($LASTEXITCODE)" }

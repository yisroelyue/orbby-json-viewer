# 打包脚本：构建 Windows Release 版本并压缩到 dist/ 目录。
# 用法：.\package.ps1
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# 从 pubspec.yaml 读取版本号（忽略 +build 号）
$versionLine = Select-String -Path pubspec.yaml -Pattern '^version:\s*(\S+)' | Select-Object -First 1
if (-not $versionLine) { throw '无法从 pubspec.yaml 读取版本号' }
$appVersion = $versionLine.Matches[0].Groups[1].Value -split '\+' | Select-Object -First 1

$zipName = "orbby_json_viewer_v${appVersion}_windows_x64.zip"
$distDir = Join-Path $PSScriptRoot 'dist'
$zipPath = Join-Path $distDir $zipName

Write-Host '== flutter build windows --release ==' -ForegroundColor Cyan
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw '构建失败' }

$releaseDir = Join-Path $PSScriptRoot 'build\windows\x64\runner\Release'
if (-not (Test-Path (Join-Path $releaseDir 'orbby_json_viewer.exe'))) {
    throw "未找到构建产物: $releaseDir"
}

# 先复制到暂存目录，让压缩包内带一层版本号文件夹，解压后文件不会散落一地
$stageDir = Join-Path $env:TEMP "orbby_json_viewer_package_v${appVersion}"
$appDirName = "orbby_json_viewer_v${appVersion}"
if (Test-Path $stageDir) { Remove-Item -Recurse -Force $stageDir }
New-Item -ItemType Directory -Force $stageDir | Out-Null
Copy-Item -Recurse -Force -Path $releaseDir -Destination (Join-Path $stageDir $appDirName)

New-Item -ItemType Directory -Force $distDir | Out-Null
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
Compress-Archive -Path (Join-Path $stageDir $appDirName) -DestinationPath $zipPath
Remove-Item -Recurse -Force $stageDir

# 只保留最新版本压缩包，删掉 dist/ 里的旧版本
Get-ChildItem $distDir -Filter 'orbby_json_viewer_v*_windows_x64.zip' |
    Where-Object { $_.Name -ne $zipName } |
    Remove-Item -Force

# 同步 README 中的下载链接
$readmePath = Join-Path $PSScriptRoot 'README.md'
if (Test-Path $readmePath) {
    $readme = [IO.File]::ReadAllText($readmePath)
    $updated = [regex]::Replace($readme, 'dist/orbby_json_viewer_v[\d.]+_windows_x64\.zip', "dist/$zipName")
    if ($updated -ne $readme) {
        [IO.File]::WriteAllText($readmePath, $updated, (New-Object System.Text.UTF8Encoding $false))
        Write-Host "已更新 README 下载链接: dist/$zipName"
    }
}

$sizeMb = '{0:N1}' -f ((Get-Item $zipPath).Length / 1MB)
Write-Host ''
Write-Host "打包完成: dist\$zipName ($sizeMb MB)" -ForegroundColor Green

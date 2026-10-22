# ========================================================================
# Windows 开发机自动化部署脚本
# 内容：
#   - 自动安装 Chocolatey（如未安装）
#   - 安装 git、7zip、jdk8、nvm(1.1.12)、docker-desktop、wsl
#   - 启用 WSL & VirtualMachinePlatform
#   - 自动安装 Debian（WSL发行版）
# ========================================================================

#----------------------------
# 1. 需要管理员权限
#----------------------------
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Warning "⚠ 请以管理员权限运行 PowerShell！（右键 → 以管理员身份运行）"
    exit 1
}
Write-Host "✅ 管理员权限已确认"


#----------------------------
# 2. 安装 Chocolatey
#----------------------------
$chocoPath = "$env:ProgramData\chocolatey\bin\choco.exe"

if (-not (Test-Path $chocoPath)) {
    Write-Host "⏳ Chocolatey 未安装，正在安装..."

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = `
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

    iex ((New-Object System.Net.WebClient).DownloadString(`
        'https://community.chocolatey.org/install.ps1'))

    if (-not (Test-Path $chocoPath)) {
        Write-Error "❌ Chocolatey 安装失败，请检查网络或权限"
        exit 1
    }

    Write-Host "✅ Chocolatey 安装成功"
} else {
    Write-Host "✅ 已检测到 Chocolatey"
}


#----------------------------
# 3. 用 choco 安装/升级软件
#   ⚠ 此处 nvm 固定版本 1.1.12
#----------------------------
Write-Host "⏳ 正在安装/升级软件 ..."
choco upgrade git -y
choco upgrade 7zip -y
choco upgrade jdk8 -y
choco upgrade --force --version 1.1.12 nvm.install
Write-Host "安装 Node v14.17.4 ..." -ForegroundColor Cyan
nvm install 14.17.4
nvm use 14.17.4
choco upgrade wsl -y
choco upgrade docker-desktop -y

Write-Host "✅ 常用软件安装完成"


#----------------------------
# 4. 启用 WSL 和虚拟化平台
#----------------------------
Write-Host "⏳ 正在启用 WSL 必需组件..."

dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

Write-Host "✅ WSL 核心组件设置完成"


#----------------------------
# 5. 安装 Debian（WSL）
#----------------------------
Write-Host "⏳ 正在安装 Debian (WSL)..."

try {
    wsl --install -d Debian
    Write-Host "✅ Debian 安装指令已执行"
}
catch {
    Write-Warning "⚠ 无法用 wsl --install 安装 Debian，可能需要重启系统后再执行一次"
}

Write-Host ""
Write-Host "⚠ 如果这是首次启用 WSL 或首次安装发行版，必须重启后 Debian 才能初始化。"
Write-Host ""


#----------------------------
# 6. 刷新环境变量
#----------------------------
Write-Host "⏳ 正在刷新环境变量..."
refreshenv | Out-Null


#----------------------------
# 结束提示
#----------------------------
Write-Host ""
Write-Host "✅✅ Windows 开发机环境部署完成 ✅✅"
Write-Host "已安装：git / jdk8 / 7zip / nvm(1.1.12) / docker-desktop / wsl / Debian"
Write-Host ""
Write-Host "验证命令："
Write-Host "   git --version"
Write-Host "   java -version"
Write-Host "   nvm version"
Write-Host "   docker --version  (或启动桌面版)"
Write-Host "   wsl -l -v"
Write-Host ""
Write-Host "🚀 建议重启后运行 Debian 初始化"
Write-Host ""

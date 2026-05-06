<#
.SYNOPSIS
    Bootstrap installer cho zoxide-windows-setup.

.DESCRIPTION
    Script này tải file setup-zoxide.ps1 từ GitHub và chạy nó.
    Cho phép cài đặt bằng 1 lệnh duy nhất:

    irm https://raw.githubusercontent.com/laocoi/zoxide-windows-setup/main/install.ps1 | iex
#>

[CmdletBinding()]
param(
    [string]$Branch = "main",
    [string]$Repo = "laocoi/zoxide-windows-setup"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " zoxide-windows-setup installer" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Download script chính
$scriptUrl = "https://raw.githubusercontent.com/$Repo/$Branch/setup-zoxide.ps1"

Write-Host "Đang tải setup script từ:" -ForegroundColor Yellow
Write-Host "  $scriptUrl" -ForegroundColor Gray
Write-Host ""

try {
    $scriptContent = (Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing).Content
    Write-Host "✓ Tải xong" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "✗ Lỗi tải script: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Có thể do:" -ForegroundColor Yellow
    Write-Host "  - Sai username trong URL (cần update trong install.ps1)"
    Write-Host "  - Repo chưa public"
    Write-Host "  - Mất kết nối mạng"
    exit 1
}

# Chạy script qua Invoke-Expression để tránh ExecutionPolicy chặn file .ps1 trên đĩa
Invoke-Expression $scriptContent

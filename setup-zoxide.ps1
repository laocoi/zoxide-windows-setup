<#
.SYNOPSIS
    Setup zoxide với phím tắt 'j' cho cả PowerShell và cmd (qua Clink).

.DESCRIPTION
    Script này sẽ:
    1. Cài zoxide qua winget (nếu chưa có)
    2. Cài Clink qua winget (nếu chưa có) - cần thiết cho cmd
    3. Setup PowerShell profile để dùng 'j'
    4. Tạo j.cmd cho cmd
    5. Tạo Clink hook tự động học thư mục khi cd
    6. Tạo alias để 'cd' tự đổi drive (cd /d)
    7. (Tùy chọn) Import data từ autojump nếu có

.NOTES
    Chạy script này với PowerShell (không cần admin).
    Sau khi chạy xong, đóng terminal và mở mới để test.
#>

[CmdletBinding()]
param(
    [string]$AutojumpDataPath = "$env:APPDATA\autojump\autojump.txt"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "    ✓ $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    ! $Message" -ForegroundColor Yellow
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# ============================================================================
# 1. Kiểm tra và cài zoxide
# ============================================================================
Write-Step "Kiểm tra zoxide"

if (Test-CommandExists "zoxide") {
    $version = (zoxide --version) 2>&1
    Write-Success "Zoxide đã cài: $version"
} else {
    Write-Warn "Zoxide chưa cài. Đang cài qua winget..."
    winget install ajeetdsouza.zoxide --accept-source-agreements --accept-package-agreements
    
    # Refresh PATH cho session hiện tại
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
    
    if (Test-CommandExists "zoxide") {
        Write-Success "Đã cài zoxide thành công"
    } else {
        Write-Warn "Cài zoxide xong nhưng chưa nhận diện được. Bạn cần đóng và mở lại PowerShell, rồi chạy lại script này."
        exit 1
    }
}

# ============================================================================
# 2. Kiểm tra Clink (cho cmd)
# ============================================================================
Write-Step "Kiểm tra Clink (cho cmd)"

$clinkExists = Test-CommandExists "clink"
if ($clinkExists) {
    Write-Success "Clink đã cài"
} else {
    Write-Warn "Clink chưa cài. Đang cài qua winget..."
    try {
        winget install chrisant996.Clink --accept-source-agreements --accept-package-agreements
        Write-Success "Đã cài Clink. Lưu ý: cần mở cmd mới để Clink tự động inject."
    } catch {
        Write-Warn "Không cài được Clink tự động. Bạn có thể cài thủ công sau từ https://github.com/chrisant996/clink"
        Write-Warn "Phần setup cmd sẽ bị bỏ qua."
    }
}

# ============================================================================
# 3. Setup PowerShell profile
# ============================================================================
Write-Step "Setup PowerShell profile"

# Tạo profile nếu chưa có
if (!(Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -Type File -Force | Out-Null
    Write-Success "Đã tạo profile: $PROFILE"
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if (-not $profileContent) { $profileContent = "" }

$zoxideInitLine = 'Invoke-Expression (& { (zoxide init powershell --cmd j) -join "`n" })'

if ($profileContent -match "zoxide init powershell") {
    Write-Success "Profile đã có config zoxide"
} else {
    Add-Content -Path $PROFILE -Value "`n# Zoxide - smart cd with 'j' command`n$zoxideInitLine`n"
    Write-Success "Đã thêm zoxide vào profile"
}

# ============================================================================
# 4. Tạo j.cmd cho cmd
# ============================================================================
Write-Step "Tạo j.cmd cho cmd"

$binDir = "$env:USERPROFILE\bin"
if (!(Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    Write-Success "Đã tạo thư mục: $binDir"
}

$jCmdContent = @'
@echo off
setlocal

if "%~1"=="" (
    cd /d "%USERPROFILE%"
    goto :eof
)

for /f "usebackq tokens=* delims=" %%i in (`zoxide query %* 2^>nul`) do (
    endlocal
    cd /d "%%i"
    zoxide add "%%i" >nul 2>&1
    goto :eof
)

echo zoxide: no match found
'@

$jCmdPath = "$binDir\j.cmd"
Set-Content -Path $jCmdPath -Value $jCmdContent -Encoding ASCII
Write-Success "Đã tạo: $jCmdPath"

# Thêm $binDir vào PATH (User) nếu chưa có
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$binDir*") {
    $newPath = $userPath.TrimEnd(';') + ";$binDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Success "Đã thêm $binDir vào PATH"
} else {
    Write-Success "$binDir đã có trong PATH"
}

# ============================================================================
# 5. Tạo Clink scripts (hook + alias)
# ============================================================================
if ($clinkExists -or (Test-CommandExists "clink")) {
    Write-Step "Tạo Clink scripts"
    
    $clinkProfileDir = "$env:LOCALAPPDATA\clink"
    if (!(Test-Path $clinkProfileDir)) {
        New-Item -ItemType Directory -Path $clinkProfileDir -Force | Out-Null
    }
    
    # Hook để tự động zoxide add khi cd
    $hookContent = @'
-- Auto-add current directory to zoxide database before each prompt
local last_dir = ""

local function zoxide_hook()
    local cwd = os.getcwd()
    if cwd ~= last_dir then
        last_dir = cwd
        os.execute('zoxide add "' .. cwd .. '" >nul 2>&1')
    end
end

clink.onbeginedit(zoxide_hook)
'@
    Set-Content -Path "$clinkProfileDir\zoxide_hook.lua" -Value $hookContent -Encoding UTF8
    Write-Success "Đã tạo: $clinkProfileDir\zoxide_hook.lua"
    
    # Alias để cd tự đổi drive
    $aliasContent = @'
-- Make cd always switch drive automatically (cd /d)
os.execute('doskey cd=cd /d $*')
'@
    Set-Content -Path "$clinkProfileDir\aliases.lua" -Value $aliasContent -Encoding UTF8
    Write-Success "Đã tạo: $clinkProfileDir\aliases.lua"
} else {
    Write-Warn "Bỏ qua setup Clink (chưa cài)"
}

# ============================================================================
# 6. Import autojump data (nếu có)
# ============================================================================
Write-Step "Import data từ autojump (nếu có)"

if (Test-Path $AutojumpDataPath) {
    Write-Host "    Tìm thấy autojump data tại: $AutojumpDataPath"
    try {
        zoxide import --from autojump --merge $AutojumpDataPath 2>&1 | Out-Null
        Write-Success "Đã import data từ autojump"
    } catch {
        try {
            zoxide import --from autojump $AutojumpDataPath 2>&1 | Out-Null
            Write-Success "Đã import data từ autojump"
        } catch {
            Write-Warn "Không import được. Có thể database zoxide đã có data."
        }
    }
} else {
    Write-Host "    Không có autojump data tại $AutojumpDataPath - bỏ qua"
}

# ============================================================================
# Hoàn thành
# ============================================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host " Setup hoàn tất!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Bước tiếp theo:" -ForegroundColor Yellow
Write-Host "  1. Đóng tất cả cửa sổ PowerShell và cmd hiện tại"
Write-Host "  2. Mở terminal mới"
Write-Host "  3. Test: gõ 'j <từ_khóa>' (vd: j Documents)"
Write-Host ""
Write-Host "Cách dùng:" -ForegroundColor Yellow
Write-Host "  j foo          - nhảy tới thư mục match 'foo'"
Write-Host "  j foo bar      - match nhiều từ khóa"
Write-Host "  j              - về home directory"
Write-Host "  cd <path>      - cũng đã tự đổi drive (không cần /d)"
Write-Host ""
Write-Host "Lưu ý: Zoxide học từ thư mục bạn cd vào, nên dùng càng nhiều càng thông minh." -ForegroundColor Gray

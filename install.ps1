<#
.SYNOPSIS
    [VI] Setup zoxide với phím tắt 'j' cho cả PowerShell và cmd (qua Clink).
    [EN] Set up zoxide with the 'j' shortcut for both PowerShell and cmd (via Clink).

.DESCRIPTION
    [VI] Script này sẽ:
    1. Cài zoxide qua winget (nếu chưa có)
    2. Cài Clink qua winget (nếu chưa có) - cần thiết cho cmd
    3. Setup PowerShell profile để dùng 'j'
    4. Tạo j.cmd cho cmd
    5. Tạo Clink hook tự động học thư mục khi cd
    6. Tạo alias để 'cd' tự đổi drive (cd /d)
    7. (Tùy chọn) Import data từ autojump nếu có

    [EN] This script will:
    1. Install zoxide via winget (if missing)
    2. Install Clink via winget (if missing) - needed for cmd
    3. Set up PowerShell profile to use 'j'
    4. Create j.cmd for cmd
    5. Create a Clink hook that auto-learns directories on cd
    6. Create an alias so 'cd' auto-switches drive (cd /d)
    7. (Optional) Import data from autojump if present

.PARAMETER Lang
    [VI] 'vi' hoặc 'en'. Bỏ trống để hỏi tương tác.
    [EN] 'vi' or 'en'. Leave empty to prompt interactively.

.PARAMETER AutojumpDataPath
    [VI] Đường dẫn tới file autojump.txt (mặc định: $env:APPDATA\autojump\autojump.txt).
    [EN] Path to autojump.txt (default: $env:APPDATA\autojump\autojump.txt).

.NOTES
    One-liner:
        irm https://raw.githubusercontent.com/laocoi/zoxide-windows-setup/main/install.ps1 | iex

    Local:
        .\install.ps1
        .\install.ps1 -Lang en
#>

[CmdletBinding()]
param(
    [string]$AutojumpDataPath = "$env:APPDATA\autojump\autojump.txt",
    [ValidateSet("vi", "en", "")]
    [string]$Lang = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " zoxide-windows-setup installer" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# Language selection / Chọn ngôn ngữ
# ============================================================================
if (-not $Lang) {
    Write-Host "Select language / Chọn ngôn ngữ:" -ForegroundColor Yellow
    Write-Host "  [1] Tiếng Việt"
    Write-Host "  [2] English"
    $choice = Read-Host "Choice / Lựa chọn [1]"
    if ($choice -eq "2" -or $choice -match "^(en|english|e)$") {
        $Lang = "en"
    } else {
        $Lang = "vi"
    }
}

# ============================================================================
# Translation table
# ============================================================================
$T = @{
    vi = @{
        StepCheckZoxide       = "Kiểm tra zoxide"
        ZoxideInstalled       = "Zoxide đã cài: {0}"
        ZoxideNotInstalled    = "Zoxide chưa cài. Đang cài qua winget..."
        ZoxideInstallSuccess  = "Đã cài zoxide thành công"
        ZoxideNotDetected     = "Cài zoxide xong nhưng chưa nhận diện được. Bạn cần đóng và mở lại PowerShell, rồi chạy lại script này."
        StepCheckClink        = "Kiểm tra Clink (cho cmd)"
        ClinkInstalled        = "Clink đã cài"
        ClinkNotInstalled     = "Clink chưa cài. Đang cài qua winget..."
        ClinkInstallSuccess   = "Đã cài Clink. Lưu ý: cần mở cmd mới để Clink tự động inject."
        ClinkPathNotRefreshed = "Đã cài Clink nhưng PATH chưa refresh được trong session này. Sẽ vẫn tạo Clink scripts (Clink sẽ load khi mở cmd mới)."
        ClinkInstallFail      = "Không cài được Clink tự động. Bạn có thể cài thủ công sau từ https://github.com/chrisant996/clink"
        ClinkSkipCmd          = "Phần setup cmd sẽ bị bỏ qua."
        StepSetupProfile      = "Setup PowerShell profile"
        ProfileCreated        = "Đã tạo profile: {0}"
        ProfileHasZoxide      = "Profile đã có config zoxide"
        ProfileAddedZoxide    = "Đã thêm zoxide vào profile"
        ExecPolicyWarn1       = "ExecutionPolicy đang Restricted/AllSigned — PowerShell profile sẽ không load."
        ExecPolicyWarn2       = "Để 'j' chạy được trong PowerShell, chạy 1 lần:"
        ExecPolicyCmd         = "  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
        StepCreateJCmd        = "Tạo j.cmd cho cmd"
        DirCreated            = "Đã tạo thư mục: {0}"
        FileCreated           = "Đã tạo: {0}"
        PathAdded             = "Đã thêm {0} vào PATH"
        PathExists            = "{0} đã có trong PATH"
        StepClinkScripts      = "Tạo Clink scripts"
        ClinkSkip             = "Bỏ qua setup Clink (chưa cài)"
        StepImportAutojump    = "Import data từ autojump (nếu có)"
        FoundAutojump         = "    Tìm thấy autojump data tại: {0}"
        ImportSuccess         = "Đã import data từ autojump"
        ImportFail            = "Không import được. Có thể database zoxide đã có data."
        NoAutojump            = "    Không có autojump data tại {0} - bỏ qua"
        SetupComplete         = " Setup hoàn tất!"
        NextSteps             = "Bước tiếp theo:"
        Step1                 = "  1. Đóng tất cả cửa sổ PowerShell và cmd hiện tại"
        Step2                 = "  2. Mở terminal mới"
        Step3                 = "  3. Test: gõ 'j <từ_khóa>' (vd: j Documents)"
        Usage                 = "Cách dùng:"
        UsageJ1               = "  j foo          - nhảy tới thư mục match 'foo'"
        UsageJ2               = "  j foo bar      - match nhiều từ khóa"
        UsageJ3               = "  j              - về home directory"
        UsageCd               = "  cd <path>      - cũng đã tự đổi drive trong cmd (không cần /d)"
        FinalNote             = "Lưu ý: Zoxide học từ thư mục bạn cd vào, nên dùng càng nhiều càng thông minh."
    }
    en = @{
        StepCheckZoxide       = "Checking zoxide"
        ZoxideInstalled       = "Zoxide already installed: {0}"
        ZoxideNotInstalled    = "Zoxide not installed. Installing via winget..."
        ZoxideInstallSuccess  = "Zoxide installed successfully"
        ZoxideNotDetected     = "Zoxide installed but not detected yet. Please close and reopen PowerShell, then run this script again."
        StepCheckClink        = "Checking Clink (for cmd)"
        ClinkInstalled        = "Clink already installed"
        ClinkNotInstalled     = "Clink not installed. Installing via winget..."
        ClinkInstallSuccess   = "Clink installed. Note: open a new cmd for Clink to auto-inject."
        ClinkPathNotRefreshed = "Clink installed but PATH not refreshed in this session. Clink scripts will still be created (Clink will load in new cmd windows)."
        ClinkInstallFail      = "Could not install Clink automatically. You can install it manually later from https://github.com/chrisant996/clink"
        ClinkSkipCmd          = "The cmd setup part will be skipped."
        StepSetupProfile      = "Setting up PowerShell profile"
        ProfileCreated        = "Profile created: {0}"
        ProfileHasZoxide      = "Profile already has zoxide config"
        ProfileAddedZoxide    = "Added zoxide to profile"
        ExecPolicyWarn1       = "ExecutionPolicy is Restricted/AllSigned — PowerShell profile won't load."
        ExecPolicyWarn2       = "To make 'j' work in PowerShell, run once:"
        ExecPolicyCmd         = "  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
        StepCreateJCmd        = "Creating j.cmd for cmd"
        DirCreated            = "Directory created: {0}"
        FileCreated           = "Created: {0}"
        PathAdded             = "Added {0} to PATH"
        PathExists            = "{0} already in PATH"
        StepClinkScripts      = "Creating Clink scripts"
        ClinkSkip             = "Skipping Clink setup (not installed)"
        StepImportAutojump    = "Importing data from autojump (if available)"
        FoundAutojump         = "    Found autojump data at: {0}"
        ImportSuccess         = "Imported data from autojump"
        ImportFail            = "Could not import. Zoxide database may already have data."
        NoAutojump            = "    No autojump data at {0} - skipping"
        SetupComplete         = " Setup complete!"
        NextSteps             = "Next steps:"
        Step1                 = "  1. Close all current PowerShell and cmd windows"
        Step2                 = "  2. Open a new terminal"
        Step3                 = "  3. Test: type 'j <keyword>' (e.g., j Documents)"
        Usage                 = "Usage:"
        UsageJ1               = "  j foo          - jump to a directory matching 'foo'"
        UsageJ2               = "  j foo bar      - match multiple keywords"
        UsageJ3               = "  j              - go to home directory"
        UsageCd               = "  cd <path>      - auto-switches drive in cmd (no /d needed)"
        FinalNote             = "Note: Zoxide learns from the directories you cd into - the more you use it, the smarter it gets."
    }
}

$L = $T[$Lang]

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
# 1. Check & install zoxide
# ============================================================================
Write-Step $L.StepCheckZoxide

if (Test-CommandExists "zoxide") {
    $version = (zoxide --version) 2>&1
    Write-Success ($L.ZoxideInstalled -f $version)
} else {
    Write-Warn $L.ZoxideNotInstalled
    winget install ajeetdsouza.zoxide --accept-source-agreements --accept-package-agreements

    # Refresh PATH for current session
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")

    if (Test-CommandExists "zoxide") {
        Write-Success $L.ZoxideInstallSuccess
    } else {
        Write-Warn $L.ZoxideNotDetected
        exit 1
    }
}

# ============================================================================
# 2. Check Clink (for cmd)
# ============================================================================
Write-Step $L.StepCheckClink

$clinkExists = Test-CommandExists "clink"
if ($clinkExists) {
    Write-Success $L.ClinkInstalled
} else {
    Write-Warn $L.ClinkNotInstalled
    try {
        winget install chrisant996.Clink --accept-source-agreements --accept-package-agreements
        $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
        $clinkExists = Test-CommandExists "clink"
        if ($clinkExists) {
            Write-Success $L.ClinkInstallSuccess
        } else {
            Write-Warn $L.ClinkPathNotRefreshed
            $clinkExists = $true
        }
    } catch {
        Write-Warn $L.ClinkInstallFail
        Write-Warn $L.ClinkSkipCmd
    }
}

# ============================================================================
# 3. Setup PowerShell profile
# ============================================================================
Write-Step $L.StepSetupProfile

if (!(Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -Type File -Force | Out-Null
    Write-Success ($L.ProfileCreated -f $PROFILE)
}

$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
if (-not $profileContent) { $profileContent = "" }

$zoxideInitLine = 'Invoke-Expression (& { (zoxide init powershell --cmd j) -join "`n" })'

if ($profileContent -match "zoxide init powershell") {
    Write-Success $L.ProfileHasZoxide
} else {
    Add-Content -Path $PROFILE -Value "`n# Zoxide - smart cd with 'j' command`n$zoxideInitLine`n"
    Write-Success $L.ProfileAddedZoxide
}

$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned" -or $currentPolicy -eq "Undefined") {
    $machinePolicy = Get-ExecutionPolicy -Scope LocalMachine
    if ($machinePolicy -eq "Restricted" -or $machinePolicy -eq "AllSigned" -or $machinePolicy -eq "Undefined") {
        Write-Warn $L.ExecPolicyWarn1
        Write-Warn $L.ExecPolicyWarn2
        Write-Warn $L.ExecPolicyCmd
    }
}

# ============================================================================
# 4. Create j.cmd for cmd
# ============================================================================
Write-Step $L.StepCreateJCmd

$binDir = "$env:USERPROFILE\bin"
if (!(Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    Write-Success ($L.DirCreated -f $binDir)
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
Write-Success ($L.FileCreated -f $jCmdPath)

# Add $binDir to user PATH if missing
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$binDir*") {
    $newPath = $userPath.TrimEnd(';') + ";$binDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Success ($L.PathAdded -f $binDir)
} else {
    Write-Success ($L.PathExists -f $binDir)
}

# ============================================================================
# 5. Clink scripts (hook + alias)
# ============================================================================
if ($clinkExists) {
    Write-Step $L.StepClinkScripts

    $clinkProfileDir = "$env:LOCALAPPDATA\clink"
    if (!(Test-Path $clinkProfileDir)) {
        New-Item -ItemType Directory -Path $clinkProfileDir -Force | Out-Null
    }

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
    Write-Success ($L.FileCreated -f "$clinkProfileDir\zoxide_hook.lua")

    $aliasContent = @'
-- Make cd always switch drive automatically (cd /d)
os.execute('doskey cd=cd /d $*')
'@
    Set-Content -Path "$clinkProfileDir\aliases.lua" -Value $aliasContent -Encoding UTF8
    Write-Success ($L.FileCreated -f "$clinkProfileDir\aliases.lua")
} else {
    Write-Warn $L.ClinkSkip
}

# ============================================================================
# 6. Import autojump data (if any)
# ============================================================================
Write-Step $L.StepImportAutojump

if (Test-Path $AutojumpDataPath) {
    Write-Host ($L.FoundAutojump -f $AutojumpDataPath)
    try {
        zoxide import --from autojump --merge $AutojumpDataPath 2>&1 | Out-Null
        Write-Success $L.ImportSuccess
    } catch {
        try {
            zoxide import --from autojump $AutojumpDataPath 2>&1 | Out-Null
            Write-Success $L.ImportSuccess
        } catch {
            Write-Warn $L.ImportFail
        }
    }
} else {
    Write-Host ($L.NoAutojump -f $AutojumpDataPath)
}

# ============================================================================
# Done
# ============================================================================
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host $L.SetupComplete -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host $L.NextSteps -ForegroundColor Yellow
Write-Host $L.Step1
Write-Host $L.Step2
Write-Host $L.Step3
Write-Host ""
Write-Host $L.Usage -ForegroundColor Yellow
Write-Host $L.UsageJ1
Write-Host $L.UsageJ2
Write-Host $L.UsageJ3
Write-Host $L.UsageCd
Write-Host ""
Write-Host $L.FinalNote -ForegroundColor Gray

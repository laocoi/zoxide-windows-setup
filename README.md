# zoxide-windows-setup

> 🇻🇳 Tiếng Việt · [🇬🇧 English](#english)

## Tiếng Việt

Setup [zoxide](https://github.com/ajeetdsouza/zoxide) trên Windows với phím tắt `j` cho cả **PowerShell** và **cmd** (qua [Clink](https://github.com/chrisant996/clink)) chỉ với 1 lệnh.

Hoàn hảo cho ai đang dùng `autojump` muốn chuyển sang zoxide mà giữ nguyên muscle memory `j <keyword>`.

### ✨ Tính năng

- ⚡ Cài zoxide tự động qua winget
- 🐚 Hỗ trợ **cả PowerShell và cmd** (qua Clink)
- ⌨️ Dùng phím tắt `j` thay cho `z` (giống autojump)
- 🌐 Trình cài đặt song ngữ Việt / Anh (chọn lúc chạy)
- 📥 Tự động import data từ autojump nếu phát hiện
- 🔄 Tự động học thư mục khi `cd` (kể cả trong cmd)
- 🚀 Bonus: `cd` trong cmd tự đổi drive (không cần `cd /d`)
- ✅ Idempotent: chạy nhiều lần không gây lỗi

### 📦 Yêu cầu

- Windows 10/11
- PowerShell 5.1+ (có sẵn trong Windows)
- [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) (có sẵn trên Windows 11, Win10 cài qua Microsoft Store)

### 🚀 Cài đặt nhanh (One-liner)

Mở **PowerShell** và chạy:

```powershell
irm https://raw.githubusercontent.com/laocoi/zoxide-windows-setup/main/install.ps1 | iex
```

Script sẽ hỏi chọn ngôn ngữ (Tiếng Việt / English) ngay đầu, sau đó toàn bộ thông báo sẽ hiển thị theo ngôn ngữ bạn chọn.

Lệnh này tải và chạy `install.ps1` trực tiếp trong memory (không ghi xuống đĩa, không bị ExecutionPolicy chặn).

### 📥 Cài đặt thủ công

```powershell
# 1. Clone repo
git clone https://github.com/laocoi/zoxide-windows-setup.git
cd zoxide-windows-setup

# 2. (Lần đầu) Cho phép chạy script
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Chạy setup (mặc định: hỏi ngôn ngữ)
.\install.ps1

# Hoặc chỉ định trước ngôn ngữ:
.\install.ps1 -Lang vi
.\install.ps1 -Lang en
```

Sau khi chạy xong, **đóng terminal và mở mới** để test.

> Nếu bạn không muốn đổi ExecutionPolicy, có thể chạy không cần file đĩa:
> ```powershell
> Get-Content .\install.ps1 -Raw | Invoke-Expression
> ```

### 🎯 Cách dùng

```powershell
j foo              # nhảy tới thư mục match 'foo'
j foo bar          # match nhiều từ khóa
j                  # về home directory
zi                 # interactive mode (cần cài fzf)
```

Zoxide học từ thư mục bạn `cd` vào — dùng càng nhiều càng thông minh.

### 📂 Import từ autojump

Script tự động phát hiện file `%APPDATA%\autojump\autojump.txt` và import. Nếu file ở chỗ khác:

```powershell
.\install.ps1 -AutojumpDataPath "D:\backup\autojump.txt"
```

### 🔧 Script làm gì?

1. Hỏi ngôn ngữ hiển thị (Việt / Anh)
2. Cài [zoxide](https://github.com/ajeetdsouza/zoxide) qua `winget` (nếu chưa có)
3. Cài [Clink](https://github.com/chrisant996/clink) qua `winget` (nếu chưa có)
4. Thêm config zoxide vào PowerShell `$PROFILE` với lệnh `j`
5. Tạo `j.cmd` tại `%USERPROFILE%\bin\` cho cmd
6. Thêm `%USERPROFILE%\bin\` vào PATH (User scope)
7. Tạo Clink hook tự động `zoxide add` khi đổi thư mục trong cmd
8. Tạo alias để `cd` trong cmd tự đổi drive
9. (Nếu có) Import data từ autojump

### 📁 Các file được tạo

| File | Mô đích |
|------|---------|
| `$PROFILE` (PowerShell) | Thêm dòng init zoxide với `--cmd j` |
| `%USERPROFILE%\bin\j.cmd` | Lệnh `j` cho cmd |
| `%LOCALAPPDATA%\clink\zoxide_hook.lua` | Hook auto-track CWD trong cmd |
| `%LOCALAPPDATA%\clink\aliases.lua` | Alias `cd` → `cd /d` |

### 🗑️ Gỡ cài đặt

Xóa các file tạo bởi script:

```powershell
# Xóa j.cmd
Remove-Item "$env:USERPROFILE\bin\j.cmd" -ErrorAction SilentlyContinue

# Xóa Clink scripts
Remove-Item "$env:LOCALAPPDATA\clink\zoxide_hook.lua" -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\clink\aliases.lua" -ErrorAction SilentlyContinue

# Xóa dòng zoxide trong PowerShell profile (mở $PROFILE và xóa thủ công)
notepad $PROFILE

# Gỡ zoxide
winget uninstall ajeetdsouza.zoxide
```

### 🤔 FAQ

**Q: `j --help` báo "no match found"?**
A: Đây là zoxide đang chạy đúng — nó hiểu `--help` là từ khóa tìm kiếm. Để xem help thật, dùng `zoxide --help`.

**Q: Tại sao cần Clink?**
A: cmd không có cơ chế profile như PowerShell. Clink cung cấp Lua scripting để inject hook tự động vào cmd, giúp zoxide học CWD mỗi khi prompt hiện ra.

**Q: PowerShell và cmd có dùng chung database không?**
A: Có. Database zoxide nằm ở `%LOCALAPPDATA%\zoxide\db.zo`, dùng chung cho mọi shell.

**Q: Có hoạt động với Windows Terminal / Cmder / Laragon không?**
A: Có, vì các terminal đó chỉ là wrapper cho PowerShell/cmd. Miễn shell bên trong là PowerShell hoặc cmd thì script chạy được.

### 📝 License

MIT — xem [LICENSE](LICENSE).

### 🙏 Credits

- [zoxide](https://github.com/ajeetdsouza/zoxide) by ajeetdsouza
- [Clink](https://github.com/chrisant996/clink) by chrisant996
- Inspired by [autojump](https://github.com/wting/autojump)

---

<a name="english"></a>

## English

Set up [zoxide](https://github.com/ajeetdsouza/zoxide) on Windows with the `j` shortcut for both **PowerShell** and **cmd** (via [Clink](https://github.com/chrisant996/clink)) in a single command.

Perfect for `autojump` users moving to zoxide who want to keep the `j <keyword>` muscle memory.

### ✨ Features

- ⚡ Auto-installs zoxide via winget
- 🐚 Works in **both PowerShell and cmd** (via Clink)
- ⌨️ Uses `j` instead of `z` (autojump-style)
- 🌐 Bilingual installer — pick Vietnamese or English at runtime
- 📥 Auto-imports autojump data when detected
- 🔄 Auto-learns directories when you `cd` (cmd included)
- 🚀 Bonus: `cd` in cmd auto-switches drive (no `cd /d` needed)
- ✅ Idempotent: safe to re-run

### 📦 Requirements

- Windows 10/11
- PowerShell 5.1+ (built into Windows)
- [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) (preinstalled on Windows 11; install from Microsoft Store on Win10)

### 🚀 Quick install (one-liner)

Open **PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/laocoi/zoxide-windows-setup/main/install.ps1 | iex
```

The script asks for your language (Vietnamese / English) at the very start, then displays all subsequent messages in the language you picked.

This downloads and runs `install.ps1` in memory (no file written, not blocked by ExecutionPolicy).

### 📥 Manual install

```powershell
# 1. Clone the repo
git clone https://github.com/laocoi/zoxide-windows-setup.git
cd zoxide-windows-setup

# 2. (First time) Allow scripts to run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Run setup (default: prompts for language)
.\install.ps1

# Or pick the language up front:
.\install.ps1 -Lang en
.\install.ps1 -Lang vi
```

When done, **close the terminal and open a new one** to test.

> If you don't want to change ExecutionPolicy, you can run without writing a script file:
> ```powershell
> Get-Content .\install.ps1 -Raw | Invoke-Expression
> ```

### 🎯 Usage

```powershell
j foo              # jump to a directory matching 'foo'
j foo bar          # match multiple keywords
j                  # back to home directory
zi                 # interactive mode (requires fzf)
```

Zoxide learns from the directories you `cd` into — the more you use it, the smarter it gets.

### 📂 Importing from autojump

The script auto-detects `%APPDATA%\autojump\autojump.txt` and imports it. If your file lives elsewhere:

```powershell
.\install.ps1 -AutojumpDataPath "D:\backup\autojump.txt"
```

### 🔧 What the script does

1. Asks which language to display (Vietnamese / English)
2. Installs [zoxide](https://github.com/ajeetdsouza/zoxide) via `winget` (if missing)
3. Installs [Clink](https://github.com/chrisant996/clink) via `winget` (if missing)
4. Adds the zoxide config to your PowerShell `$PROFILE` with the `j` command
5. Creates `j.cmd` at `%USERPROFILE%\bin\` for cmd
6. Adds `%USERPROFILE%\bin\` to PATH (User scope)
7. Creates a Clink hook that auto-runs `zoxide add` when you change directories in cmd
8. Creates an alias so `cd` in cmd auto-switches drive
9. Imports autojump data if available

### 📁 Files created

| File | Purpose |
|------|---------|
| `$PROFILE` (PowerShell) | Adds the zoxide init line with `--cmd j` |
| `%USERPROFILE%\bin\j.cmd` | The `j` command for cmd |
| `%LOCALAPPDATA%\clink\zoxide_hook.lua` | Auto-tracks CWD in cmd |
| `%LOCALAPPDATA%\clink\aliases.lua` | Alias `cd` → `cd /d` |

### 🗑️ Uninstall

Remove the files the script created:

```powershell
# Remove j.cmd
Remove-Item "$env:USERPROFILE\bin\j.cmd" -ErrorAction SilentlyContinue

# Remove Clink scripts
Remove-Item "$env:LOCALAPPDATA\clink\zoxide_hook.lua" -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\clink\aliases.lua" -ErrorAction SilentlyContinue

# Remove the zoxide line from your PowerShell profile (open $PROFILE and edit)
notepad $PROFILE

# Uninstall zoxide
winget uninstall ajeetdsouza.zoxide
```

### 🤔 FAQ

**Q: `j --help` says "no match found" — why?**
A: That's zoxide working correctly — it treats `--help` as a search keyword. To see the real help, run `zoxide --help`.

**Q: Why is Clink needed?**
A: Unlike PowerShell, cmd has no profile mechanism. Clink provides Lua scripting that injects a hook into cmd so zoxide can learn the CWD every time the prompt appears.

**Q: Do PowerShell and cmd share one zoxide database?**
A: Yes. The zoxide database lives at `%LOCALAPPDATA%\zoxide\db.zo` and is shared across all shells.

**Q: Does this work with Windows Terminal / Cmder / Laragon?**
A: Yes — those terminals are just wrappers around PowerShell/cmd. As long as the inner shell is PowerShell or cmd, the script works.

### 📝 License

MIT — see [LICENSE](LICENSE).

### 🙏 Credits

- [zoxide](https://github.com/ajeetdsouza/zoxide) by ajeetdsouza
- [Clink](https://github.com/chrisant996/clink) by chrisant996
- Inspired by [autojump](https://github.com/wting/autojump)

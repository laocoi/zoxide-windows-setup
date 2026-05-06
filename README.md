# zoxide-windows-setup

Setup [zoxide](https://github.com/ajeetdsouza/zoxide) trên Windows với phím tắt `j` cho cả **PowerShell** và **cmd** (qua [Clink](https://github.com/chrisant996/clink)) chỉ với 1 lệnh.

Hoàn hảo cho ai đang dùng `autojump` muốn chuyển sang zoxide mà giữ nguyên muscle memory `j <keyword>`.

## ✨ Features

- ⚡ Cài zoxide tự động qua winget
- 🐚 Hỗ trợ **cả PowerShell và cmd** (qua Clink)
- ⌨️ Dùng phím tắt `j` thay cho `z` (giống autojump)
- 📥 Tự động import data từ autojump nếu phát hiện
- 🔄 Tự động học thư mục khi `cd` (kể cả trong cmd)
- 🚀 Bonus: `cd` trong cmd tự đổi drive (không cần `cd /d`)
- ✅ Idempotent: chạy nhiều lần không gây lỗi

## 📦 Yêu cầu

- Windows 10/11
- PowerShell 5.1+ (có sẵn trong Windows)
- [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/) (có sẵn trên Windows 11, Win10 cài qua Microsoft Store)

## 🚀 Cài đặt nhanh (One-liner)

Mở **PowerShell** và chạy:

```powershell
irm https://raw.githubusercontent.com/laocoi/zoxide-windows-setup/main/install.ps1 | iex
```

Lệnh này tải và chạy script `install.ps1`, script này sẽ tự download và chạy `setup-zoxide.ps1`.

## 📥 Cài đặt thủ công

```powershell
# 1. Clone repo
git clone https://github.com/laocoi/zoxide-windows-setup.git
cd zoxide-windows-setup

# 2. (Lần đầu) Cho phép chạy script
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 3. Chạy setup
.\setup-zoxide.ps1
```

Sau khi chạy xong, **đóng terminal và mở mới** để test.

## 🎯 Cách dùng

```powershell
j foo              # nhảy tới thư mục match 'foo'
j foo bar          # match nhiều từ khóa
j                  # về home directory
zi                 # interactive mode (cần cài fzf)
```

Zoxide học từ thư mục bạn `cd` vào — dùng càng nhiều càng thông minh.

## 📂 Import từ autojump

Script tự động phát hiện file `%APPDATA%\autojump\autojump.txt` và import. Nếu file ở chỗ khác:

```powershell
.\setup-zoxide.ps1 -AutojumpDataPath "D:\backup\autojump.txt"
```

## 🔧 Script làm gì?

1. Cài [zoxide](https://github.com/ajeetdsouza/zoxide) qua `winget` (nếu chưa có)
2. Cài [Clink](https://github.com/chrisant996/clink) qua `winget` (nếu chưa có)
3. Thêm config zoxide vào PowerShell `$PROFILE` với lệnh `j`
4. Tạo `j.cmd` tại `%USERPROFILE%\bin\` cho cmd
5. Thêm `%USERPROFILE%\bin\` vào PATH (User scope)
6. Tạo Clink hook tự động `zoxide add` khi đổi thư mục trong cmd
7. Tạo alias để `cd` trong cmd tự đổi drive
8. (Nếu có) Import data từ autojump

## 📁 Các file được tạo

| File | Mô đích |
|------|---------|
| `$PROFILE` (PowerShell) | Thêm dòng init zoxide với `--cmd j` |
| `%USERPROFILE%\bin\j.cmd` | Lệnh `j` cho cmd |
| `%LOCALAPPDATA%\clink\zoxide_hook.lua` | Hook auto-track CWD trong cmd |
| `%LOCALAPPDATA%\clink\aliases.lua` | Alias `cd` → `cd /d` |

## 🗑️ Gỡ cài đặt

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

## 🤔 FAQ

**Q: `j --help` báo "no match found"?**
A: Đây là zoxide đang chạy đúng — nó hiểu `--help` là từ khóa tìm kiếm. Để xem help thật, dùng `zoxide --help`.

**Q: Tại sao cần Clink?**
A: cmd không có cơ chế profile như PowerShell. Clink cung cấp Lua scripting để inject hook tự động vào cmd, giúp zoxide học CWD mỗi khi prompt hiện ra.

**Q: PowerShell và cmd có dùng chung database không?**
A: Có. Database zoxide nằm ở `%LOCALAPPDATA%\zoxide\db.zo`, dùng chung cho mọi shell.

**Q: Có hoạt động với Windows Terminal / Cmder / Laragon không?**
A: Có, vì các terminal đó chỉ là wrapper cho PowerShell/cmd. Miễn shell bên trong là PowerShell hoặc cmd thì script chạy được.

## 📝 License

MIT — xem [LICENSE](LICENSE).

## 🙏 Credits

- [zoxide](https://github.com/ajeetdsouza/zoxide) by ajeetdsouza
- [Clink](https://github.com/chrisant996/clink) by chrisant996
- Inspired by [autojump](https://github.com/wting/autojump)

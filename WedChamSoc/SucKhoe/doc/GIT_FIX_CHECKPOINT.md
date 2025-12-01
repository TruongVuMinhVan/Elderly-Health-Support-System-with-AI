# 🔧 Hướng Dẫn Xử Lý Lỗi Push File Checkpoint Quá Lớn

## ❌ Lỗi Gặp Phải

```
remote: error: File WedChamSoc/SucKhoe/backend/models/checkpoints/resnet50_best_checkpoint.pth is 281.55 MB; 
this exceeds GitHub's file size limit of 100.00 MB
```

## ✅ Đã Xử Lý

1. ✅ Xóa file khỏi git cache: `git rm --cached`
2. ✅ Cập nhật `.gitignore` để ignore tất cả file trong `checkpoints/`
3. ✅ Commit thay đổi

## 📋 Các Bước Tiếp Theo

### Nếu file chỉ có trong local commit (chưa push lên remote):

```bash
# Đã xong - chỉ cần push lại
git push origin code_mv
```

### Nếu file đã có trong remote history (đã push trước đó):

Cần xóa file khỏi git history:

#### Cách 1: Sử dụng git filter-branch (Khuyến nghị)

```bash
# Xóa file khỏi toàn bộ history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch WedChamSoc/SucKhoe/backend/models/checkpoints/resnet50_best_checkpoint.pth" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (⚠️ CẨN THẬN - sẽ rewrite history)
git push origin --force --all
```

#### Cách 2: Sử dụng BFG Repo-Cleaner (Nhanh hơn)

```bash
# Download BFG: https://rtyley.github.io/bfg-repo-cleaner/

# Xóa file khỏi history
java -jar bfg.jar --delete-files resnet50_best_checkpoint.pth

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push
git push origin --force --all
```

## ⚠️ Lưu Ý Quan Trọng

1. **File vẫn còn trên máy local**: Chỉ xóa khỏi git, không xóa file thực tế
2. **Force push**: Sẽ rewrite history, cần thông báo cho team nếu làm việc nhóm
3. **Backup**: Nên backup file checkpoint trước khi xóa khỏi git

## 📁 File Checkpoint Nên Lưu Ở Đâu?

Vì file quá lớn, nên lưu ở:

1. **Google Drive / OneDrive / Dropbox**
2. **Git LFS** (nếu cần version control)
3. **Cloud Storage** (AWS S3, Azure Blob, etc.)
4. **GitHub Releases** (cho releases)

## 🔗 Tài Liệu Tham Khảo

- [GitHub File Size Limits](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github)
- [Git LFS](https://git-lfs.github.com/)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)


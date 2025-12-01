# 🗑️ Hướng Dẫn Xóa Nhánh code_mv Trên GitHub

## ✅ Đã Hoàn Thành

1. ✅ Tạo nhánh mới: `code_mv_clean`
2. ✅ Push thành công lên GitHub (không có file checkpoint)
3. ✅ Cập nhật `.gitignore` để ignore toàn bộ thư mục `checkpoints/`

## 🗑️ Xóa Nhánh `code_mv` Trên GitHub

### Cách 1: Xóa qua GitHub Web UI (Khuyến nghị)

1. Truy cập: https://github.com/TrungKien13/DoAnCN/branches
2. Tìm nhánh `code_mv`
3. Click vào icon **🗑️ Delete** bên cạnh nhánh
4. Xác nhận xóa

### Cách 2: Xóa qua Git Command

```bash
# Xóa nhánh trên remote (GitHub)
git push origin --delete code_mv
```

## ⚠️ LƯU Ý QUAN TRỌNG

- ✅ **KHÔNG xóa dự án trên máy local** - Chỉ xóa nhánh trên GitHub
- ✅ **File checkpoint vẫn còn trên máy** - Chỉ bị ignore bởi git
- ✅ **Nhánh `code_mv_clean` đã có đầy đủ code** - Không thiếu gì

## 📋 Sau Khi Xóa Nhánh Cũ

### Option 1: Đổi tên nhánh local (Khuyến nghị)

```bash
# Đổi tên nhánh local từ code_mv sang code_mv_old (backup)
git branch -m code_mv code_mv_old

# Checkout sang nhánh mới
git checkout code_mv_clean

# Đổi tên nhánh mới thành code_mv
git branch -m code_mv_clean code_mv

# Push nhánh mới lên GitHub
git push origin code_mv

# Set upstream
git push --set-upstream origin code_mv
```

### Option 2: Giữ nguyên nhánh mới

```bash
# Chỉ cần checkout sang nhánh mới
git checkout code_mv_clean

# Làm việc bình thường với nhánh mới
```

## 🔍 Kiểm Tra

Sau khi xóa nhánh cũ, kiểm tra:

```bash
# Xem các nhánh remote
git branch -r

# Xem các nhánh local
git branch
```

## 📁 File Checkpoint

File checkpoint vẫn còn tại:
- `WedChamSoc/SucKhoe/backend/models/checkpoints/resnet50_best_checkpoint.pth`

Chỉ bị ignore bởi git, không bị xóa khỏi máy.


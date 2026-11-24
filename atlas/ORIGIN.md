# Atlas trong repo của Hoàng Ân

`source.lua` là toàn bộ source Lua có thể đọc và sửa, không phải loader chuyển tiếp. Nền code lấy từ DarkBotGen/atlasbss tại commit `88492a18a102cdeadae279c5c2ac363816cd1b91`, sau đó áp dụng các bản vá Resume và giao diện VI1. Đây là bản Atlas+ bên thứ ba đã chỉnh sửa, chưa xác minh tương đương Atlas 1.2 chính chủ. Thông tin nguồn được giữ để ghi công; launcher không tải mã chính từ repo DarkBotGen.

Nguồn tham khảo: https://github.com/DarkBotGen/atlasbss/tree/88492a18a102cdeadae279c5c2ac363816cd1b91

## Giao diện VI1

- Mô tả và tooltip được Việt hóa theo thuật ngữ BSS, giữ tên vật phẩm/skill quen thuộc.
- Các dòng mô tả, nút tick, slider, dropdown, nút bấm và tiêu đề tự xuống hàng theo chiều rộng thực tế.
- Nút `?` mở/đóng giải thích ngay dưới tùy chọn. Không dùng toast góc dưới cho phần trợ giúp này.
- Thông báo hệ thống có khung giữa màn hình, cuộn được và đóng thủ công.
- Chỉ sửa phần hiển thị. Key config, giá trị dropdown và callback của các chức năng game giữ nguyên.
- Không áp dụng bản sửa hành vi A2 đang thử nghiệm. Chẩn đoán lỗi Mondo/farm đứng vẫn dựa trên log thực tế.

## Hai launcher

- `../atlas.lua`: bản thường.
- `../atlas-debug.lua`: cùng source, cộng log D1 và nút chép báo cáo khi bị đứng.

Cả hai tải `atlas/source.lua` tại một commit cố định của chính repo này, có kiểm tra dung lượng và checksum trước khi chạy. Reload config dùng lại mã đã tải trong phiên. Config cũ của bản thử vẫn ở `atlas-test/`.

Các asset/API kế thừa từ Atlas được giữ nguyên. Các địa chỉ đó không tự chứng minh ai hiện vận hành dịch vụ. Source của game Roblox, dịch vụ bên ngoài và ảnh/dữ liệu tải thêm không nằm trong repo này.

## Tự chỉnh sửa và cập nhật launcher

1. Clone/download repo, sửa `atlas/source.lua` trên máy.
2. Kiểm tra cú pháp nếu có Luau compiler, rồi commit và push source vào repo.
3. Lấy SHA đầy đủ của commit vừa chứa source.
4. Chạy Python 3: `python atlas/build_loaders.py <SOURCE_COMMIT_SHA>` từ thư mục gốc repo.
5. Commit/push `atlas.lua`, `atlas-debug.lua` và `atlas-build.json` được tạo ra. Launcher lúc này trỏ đúng snapshot source mới.

Builder không tải code từ bên ngoài. Nếu các điểm chèn log D1 không còn khớp sau khi sửa source, nó sẽ dừng để kiểm tra lại `diagnostic-patches.json`. Không tự nhận thay đổi từ upstream.

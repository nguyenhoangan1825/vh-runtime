# Atlas VI4 trong repo của Hoàng Ân

Nền: **DarkBotGen/atlasbss, atlasbss.lua, commit 59297071a022532b9a5556f7aa65595dcf9073c0**, bản mới nhất kiểm tra ngày 24/11/2026. Commit này ở ngày 22/11/2026. Đây là Atlas+ bên thứ ba, chưa xác minh tương đương Atlas 1.2 chính chủ.

Nguồn đối chiếu: https://github.com/DarkBotGen/atlasbss/blob/59297071a022532b9a5556f7aa65595dcf9073c0/atlasbss.lua

## Thay đổi UI trong VI4

- Bỏ dòng thông tin nguồn/ngày/commit trong Home; thông tin nguồn vẫn ghi tại tài liệu và metadata repo.
- Các tab được tạo một lần trong khung GUI, đổi tab bằng Visible thay vì tháo/gắn lại cả cây.
- Giữ kết quả đo chữ theo nội dung, font, cỡ chữ và chiều rộng; cache tối đa 1536 mục.
- Không đo lại chữ hay quét lại folder khi chỉ đổi màu, đổi chiều cao hoặc có thông báo ancestry nhưng chiều rộng không đổi.
- Gộp các yêu cầu cập nhật chiều cao cùng folder trong một lượt; chỉ xử lý ứng viên text trước khi đưa vào hàng chờ DescendantAdded.
- Thêm trạng thái Mondo Hop và nút chép trạng thái. Chỉ đọc điều kiện, worker, phiên, private ID và trạng thái chuyển server; không sửa cơ chế hop hay session.
- Chưa xác định nguyên nhân riêng trong phiên Roblox của người dùng. Đánh/loot Mondo rồi quay về bãi farm có thể là luồng Auto Kill thường, cần trạng thái/log để phân biệt.

## Phạm vi bản VI4

- Dựng lại trực tiếp từ nền trên; không dùng source VI2 làm nền.
- Giữ nguyên logic game của upstream: Stop Everything, Shower Resume, Mondo Resume, Autofarm, di chuyển, Walk Speed, RBC, Puffshroom và Royal Jelly.
- Bỏ toàn bộ vá Resume cũ của bản thử. Không mang bản vá khởi động/chờ loading cũ sang.
- Chỉ bổ sung giao diện: tiếng Việt cho mô tả, trợ giúp và các tên tùy chọn đã chọn; giữ tên bee, vật phẩm, skill, bãi và các giá trị dropdown của game.
- Chữ căn giữa ô, dòng dài tự xuống hàng và giãn chiều cao; tab Webhook giữ một dòng. Slider chừa vùng riêng cho giá trị số.
- Nút `?` mở mô tả ngay dưới tùy chọn, không dùng popup góc màn hình cho trợ giúp.
- Các mục Puffshroom mới có mô tả tiếng Việt. Mondo Hop được ghi rõ phải bắt đầu từ private server. Hiển thị vùng có người là 4 phần của bãi đang xem và cần bật xem vùng farm.
- Chỉ đổi tên/thông tin hiển thị; giữ nguyên config key và callback của chức năng game.

Để giữ thiết lập hiện có, các đường dẫn config dùng `atlas-test/` và tiền tố `atlas-test-`. Reload config dùng lại cùng source đã tải từ repo này. Đây là hai thay đổi tích hợp với bản riêng; không phải vá thuật toán farm.

`source.lua` là toàn bộ mã đọc được. Launcher tải snapshot cố định từ chính repo nguyenhoangan1825/vh-runtime, kiểm tra dung lượng và checksum. Không tải mã chính/reload từ DarkBotGen. Asset/API kế thừa được giữ nguyên; tên URL không xác minh ai vận hành dịch vụ.

## Hai launcher

- `../atlas.lua`: bản VI4 thường, không có bản vá Resume cũ và không chèn D1.
- `../atlas-debug.lua`: cùng nền VI4, chỉ thêm log quan sát D1 và nút Chép log khi bị đứng. Không thay cách Stop/Resume hay tự khởi động lại tác vụ.

Chạy lại từ một phiên Roblox mới để không còn tác vụ/GUI của bản trước trong phiên.

## Kiểm tra

- Compile Luau source thường, source có log và hai launcher.
- Kiểm tra giả lập căn chữ, xuống dòng, đổi chiều rộng, trợ giúp nội dòng, tab Webhook, chuyển tab hai cột và trạng thái Mondo.
- Đảo ngược toàn bộ thay đổi UI/đường dẫn/reload để khôi phục đúng từng byte source upstream.
- Đối chiếu riêng các khối Stop/Resume, Autofarm, WalkSpeed và Mondo với upstream.
- Kiểm tra launcher về checksum, lỗi tải/compile/runtime và reload.

Các kiểm tra trên không thực thi Atlas trong Roblox; chưa xác nhận độ ổn định khi treo lâu.

Kiểm tra giao diện: `python atlas/tests/test_ui.py --source atlas/source.lua --luau <đường_dẫn_luau>`.

## Tự sửa source và build

1. Sửa `atlas/source.lua`, kiểm tra cú pháp rồi commit/push source.
2. Lấy SHA đầy đủ của commit chứa source.
3. Chạy `python atlas/build_loaders.py <SOURCE_COMMIT_SHA>` từ thư mục gốc repo.
4. Commit/push `atlas.lua`, `atlas-debug.lua`, `atlas-build.json` được tạo ra.

Builder không tải code ngoài. Nếu điểm chèn D1 không còn khớp, builder dừng để kiểm tra `diagnostic-patches.json`. Lịch sử git giữ lại bản VI2 để đối chiếu. `v.lua` (VicHop) không thuộc lần cập nhật này.

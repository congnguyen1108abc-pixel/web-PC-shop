namespace PC_Store.Services
{
    /// <summary>
    /// Knowledge base cho PC Store Chatbot
    /// Chứa thông tin sản phẩm, FAQ, chính sách
    /// </summary>
    public static class ChatbotKnowledgeBase
    {
        public static string GetProductCatalog()
        {
            return @"
=== DANH CATALOG SẢN PHẨM PC STORE ===

📦 CPU (PROCESSOR):
- Intel Core Ultra 9: 18-25 triệu đ
- Ryzen 9 7950X: 20-22 triệu đ
- Intel Core i7: 12-16 triệu đ
- Ryzen 7: 10-14 triệu đ

🎮 GPU (VGA CARD):
- RTX 5090: 45-50 triệu đ
- RTX 5080: 30-35 triệu đ
- RTX 5070: 18-22 triệu đ
- RTX 4070 Ti: 20-25 triệu đ

💾 RAM:
- DDR5 64GB: 8-10 triệu đ
- DDR5 32GB: 4-5 triệu đ
- DDR5 16GB: 2-3 triệu đ

💿 SSD:
- NVMe 4TB: 3-4 triệu đ
- NVMe 2TB: 1.5-2 triệu đ
- NVMe 1TB: 800k-1 triệu đ

💻 LAPTOP GAMING:
- RTX 5080 ULTRA: 42.99 triệu đ
- RTX 5070 PRO: 36.99 triệu đ

🎧 GAMING GEAR:
- Gaming Headset: 3.29 triệu đ
- Wireless Mouse: 1.99 triệu đ
- Mechanical Keyboard: 2.49 triệu đ
- RGB Gamepad: 1.29 triệu đ

=== KHUYẾN MÃI HIỆN TẠI ===
- Mua 2 sản phẩm: Giảm 5%
- Mua 3 sản phẩm: Giảm 10%
- Mua bundle: Giảm đến 20%
";
        }

        public static string GetFAQ()
        {
            return @"
=== CÂU HỎI THƯỜNG GẶP (FAQ) ===

Q1: Giờ hoạt động của cửa hàng là bao nhiêu?
A: PC Store hoạt động từ 08:00 - 22:00 (Thứ 2 - Chủ nhật)

Q2: Bảo hành sản phẩm mấy năm?
A: Bảo hành 24 tháng cho phần cứng, 12 tháng cho linh kiện
   Bảo hành chính hãng từ nhà sản xuất

Q3: Giao hàng tới đâu?
A: Giao hàng toàn quốc
   - Miễn phí giao hàng cho đơn trên 5 triệu
   - Giao hàng trong 1-2 ngày ở thành phố lớn
   - Giao hàng 3-5 ngày ở ngoại tỉnh

Q4: Hỗ trợ trả góp không?
A: Có, trả góp 0% cho đơn hàng từ 10 triệu
   - Hỗ trợ: Ngân hàng Vietcombank, Agribank, MB

Q5: Chọn PC gaming phù hợp như thế nào?
A: Tùy mục đích:
   - MOBA, Esports: RTX 4070, CPU Core i7
   - AAA Games: RTX 5080, CPU Core i9
   - Work, Design: RTX 4060, Ryzen 7, RAM 32GB

Q6: Linh kiện nào nóng dễ hỏng?
A: CPU, GPU hay nóng nhất - cần làm mát tốt
   Kiểm tra nhiệt độ định kỳ dùng HWiNFO

Q7: SSD gì tốt nhất hiện nay?
A: Top: Samsung 990 Pro, WD Black SN850X, Crucial P5 Plus
   Giá rẻ tốt: Kingston A3000, SK Hynix

Q8: Cần upgrade gì cho PC gaming cũ?
A: GPU + SSD sẽ có hiệu quả cao nhất
   Sau đó nâng cấp CPU + RAM

Q9: Có chính sách đổi trả không?
A: Có trong 7 ngày nếu sản phẩm bị lỗi kỹ thuật
   Không hỗ trợ đổi trả nếu do người dùng

Q10: Địa chỉ cửa hàng ở đâu?
A: 10/4 Lê Quang Đạo, Hóc Môn, TP. Hồ Chí Minh
   Hotline: 0364885351
";
        }

        public static string GetPolicies()
        {
            return @"
=== CHÍNH SÁCH CỬA HÀNG ===

📋 CHÍNH SÁCH BẢO HÀNH:
- Bảo hành 24 tháng cho sản phẩm lỗi kỹ thuật
- Bảo hành chính hãng từ nhà sản xuất
- Không bảo hành nếu do tác động từ ngoài
- Hỗ trợ sửa chữa ngoài thời gian bảo hành

🚚 CHÍNH SÁCH GIAO HÀNG:
- Giao hàng miễn phí cho đơn ≥ 5 triệu
- Giao hàng 1-2 ngày ở TP.HCM
- Giao hàng 3-5 ngày ở tỉnh thành
- Đảm bảo hàng nguyên vẹn hoặc hoàn tiền

💳 CHÍNH SÁCH THANH TOÁN:
- Thanh toán tiền mặt, chuyển khoản, e-wallet
- Trả góp 0% cho đơn ≥ 10 triệu
- Ưu đãi thanh toán từ Vietcombank, MB, ACB

🔄 CHÍNH SÁCH ĐỔI TRẢ:
- Đổi sản phẩm trong 7 ngày nếu bị lỗi
- Hoàn tiền 100% nếu sản phẩm không hài lòng
- Không áp dụng nếu do lỗi người dùng

👤 CHÍNH SÁCH HỘI VIÊN:
- Điểm thưởng: 1% mỗi lần mua
- Hạng Gold: Giảm 5% + ưu tiên bảo hành
- Hạng Platinum: Giảm 10% + hỗ trợ 24/7

🆓 CHÍNH SÁCH DỊCH VỤ:
- Tư vấn PC miễn phí (online/offline)
- Lắp ráp máy: 500k - 2 triệu (tùy độ phức tạp)
- Nâng cấp linh kiện: 300k - 1 triệu
- Cài đặt phần mềm: 200k/lần
";
        }

        public static string GetContactInfo()
        {
            return @"
=== THÔNG TIN LIÊN HỆ ===

📍 ĐỊA CHỈ:
PC Store - HYPER CORE Premium Electronics
10/4 Lê Quang Đạo, Hóc Môn, TP. Hồ Chí Minh

📞 HOTLINE:
- Tổng đài & Zalo: 0364885351
- Hỗ trợ kỹ thuật: 0987.654.321

📧 EMAIL:
- Hỗ trợ khách hàng: support@pcstore.com.vn
- Báo cáo lỗi: bugs@pcstore.com.vn
- Quảng cáo: business@pcstore.com.vn

🕒 GIỜ HOẠT ĐỘNG:
- Thứ 2 - Chủ nhật: 08:00 - 22:00
- Tết: 08:00 - 20:00
- Hỗ trợ 24/7 qua chat

🌐 TRANG WEB:
- Website: https://pcstore.com.vn
- Facebook: fb.com/pcstore
- Instagram: @pcstore_vn
- YouTube: PCStore Channel

💬 HỖ TRỢ TRỰC TUYẾN:
- Chat AI: Available 24/7
- Live Chat với nhân viên: 08:00 - 22:00
- Email support: Trả lời trong 2-4 giờ
";
        }

        public static string GetTechSpecs()
        {
            return @"
=== THÔNG TIN KỸ THUẬT SẢN PHẨM ===

🖥️ CPU (Processor):
Intel Core Ultra 9:
- Cores/Threads: 24C/24T
- Base/Boost: 3.2GHz / 5.7GHz
- TDP: 55W
- Cache: 36MB
- Socket: LGA 1851

Ryzen 9 7950X:
- Cores/Threads: 16C/32T
- Base/Boost: 4.5GHz / 5.7GHz
- TDP: 105W
- Cache: 64MB
- Socket: AM5

🎮 GPU (VGA):
RTX 5090:
- Memory: 32GB GDDR7
- Bandwidth: 1792GB/s
- CUDA Cores: 14080
- Boost Clock: 2.62GHz
- Power: 575W

RTX 5080:
- Memory: 16GB GDDR7
- Bandwidth: 960GB/s
- CUDA Cores: 10240
- Boost Clock: 2.60GHz
- Power: 320W

💾 RAM:
DDR5 64GB (2x32GB):
- Speed: 6000MHz
- CAS: CL30
- Voltage: 1.40V
- Type: Unbuffered
- Temp: 0-40°C

💿 SSD:
NVMe 4TB:
- Interface: PCIe 5.0
- Seq Read: 14GB/s
- Seq Write: 12GB/s
- IOPS Read: 2M
- IOPS Write: 1.5M
- Form Factor: M.2 2280

🌡️ COOLING:
AIO Liquid 360mm:
- Pump: PWM 24V
- Radiator: Aluminum 360mm
- Fans: 3x 120mm RGB
- Max TDP: 350W
- Noise: 25-35dB

Air Tower:
- Height: 167mm
- TDP: 250W
- Fans: 2x 120mm
- Noise: 20-30dB
- Compatible: LGA1851, AM5

⚡ PSU (Power Supply):
850W Modular:
- Type: 80+ Gold
- Input: 100-240V
- Efficiency: 90%
- Protection: OCP, OVP, OTP
- Warranty: 10 năm
";
        }

        public static string GetBuildRecommendations()
        {
            return @"
=== HƯỚNG DẪN CHỌN CẤU HÌNH PC ===

🎮 PC GAMING (MOBA, Esports):
Budget: 15-20 triệu
- CPU: Core i5 / Ryzen 5
- GPU: RTX 4060 / RX 7600
- RAM: 16GB DDR5
- SSD: 512GB NVMe
- PSU: 600W 80+ Bronze
Hiệu năng: 100+ FPS LoL, 80+ FPS Valorant

🎮 PC GAMING (AAA Games High):
Budget: 35-45 triệu
- CPU: Core i9-13900K / Ryzen 9
- GPU: RTX 5080 / RX 7900 XTX
- RAM: 32GB DDR5
- SSD: 1TB NVMe Gen5
- PSU: 1000W 80+ Gold
- Cooling: AIO 360mm
Hiệu năng: 100+ FPS Ultra 1440p

🖥️ PC WORK (CAD, Blender, 3D):
Budget: 40-60 triệu
- CPU: Ryzen 9 9900X / Core i9
- GPU: RTX 6000 / RTX 5000 Ada
- RAM: 64GB DDR5
- SSD: 2TB NVMe Gen5
- PSU: 1200W 80+ Gold
- Cooling: AIO 360mm + Noctua Fans
Hiệu năng: Render Blender 4K

💼 PC OFFICE (Web, Word, Video):
Budget: 8-12 triệu
- CPU: Core i5 / Ryzen 5
- GPU: Integrated Graphics
- RAM: 8GB DDR5
- SSD: 256GB NVMe
- PSU: 400W 80+ Bronze
Hiệu năng: Đủ cho công việc văn phòng

📊 PC STREAMING:
Budget: 50-80 triệu
- CPU: Core i9-14900KS / Ryzen 9 9950X
- GPU: RTX 5090 / RTX 6000
- RAM: 64GB DDR5
- SSD: 2TB NVMe
- PSU: 1500W 80+ Platinum
- Cooling: AIO 420mm + Custom
Hiệu năng: 4K 60FPS Stream + Game

=== BẢNG SO SÁNH ===

| Tính năng | Gaming | Esports | Work | Office |
|----------|--------|---------|------|--------|
| CPU | i7/R7 | i5/R5 | i9/R9 | i5/R5 |
| GPU | RTX4070 | RTX4060 | RTX6000 | Integrated |
| RAM | 32GB | 16GB | 64GB | 8GB |
| SSD | 1TB | 512GB | 2TB | 256GB |
| Budget | 35-45M | 15-20M | 40-60M | 8-12M |
| FPS | 80-144 | 100+ | Real-time | 60+ |
";
        }
    }
}

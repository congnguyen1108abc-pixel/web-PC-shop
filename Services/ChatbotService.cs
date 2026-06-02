using Google.GenAI;

namespace PC_Store.Services
{
    public interface IChatbotService
    {
        Task<string> GetChatbotResponse(string userMessage);
    }

    public class ChatbotService : IChatbotService
    {
        private readonly Client _client;
        private readonly string _systemPrompt;

        public ChatbotService(string apiKey)
        {
            _client = new Client(apiKey: apiKey);
            _systemPrompt = GetSystemPrompt();
        }

        public async Task<string> GetChatbotResponse(string userMessage)
        {
            try
            {
                var fullPrompt = $@"{_systemPrompt}

{GetKnowledgeBase()}

--- CÂU HỎI CỦA KHÁCH HÀNG ---
{userMessage}";

                var response = await _client.Models.GenerateContentAsync(
                    model: "gemini-2.5-flash",
                    contents: fullPrompt
                );

                var text = response?.Candidates?.FirstOrDefault()?.Content?.Parts?.FirstOrDefault()?.Text;

                if (!string.IsNullOrEmpty(text))
                {
                    return text;
                }

                return "Xin lỗi, tôi không thể xử lý câu hỏi này. Vui lòng thử lại.";
            }
            catch (Exception ex)
            {
                return $"Lỗi kết nối: {ex.Message}";
            }
        }

        private string GetSystemPrompt()
        {
            return @"Bạn là một trợ lý bán hàng chuyên nghiệp của cửa hàng PC_Store - cửa hàng hàng đầu bán PC, Laptop, Linh kiện máy tính tại Việt Nam.

THÔNG TIN CỬA HÀNG:
- Tên: PC_Store / HYPER CORE Premium Electronics
- Chuyên môn: Bán PC custom, Laptop gaming, Linh kiện máy tính chất lượng cao
- Thương hiệu: Intel, AMD, NVIDIA, Samsung, Corsair, ASUS, MSI, etc.
- Địa chỉ: 123 Nguyễn Hữu Cảnh, Bình Thạnh, TP.HCM
- Hotline: 0123.456.789
- Giờ hoạt động: 08:00 - 22:00 (Thứ 2 - Chủ nhật)
- Hỗ trợ: Tư vấn, Lắp ráp, Bảo hành, Sửa chữa, Nâng cấp

QUYỀN HẠN CỦA BẠN:
1. Tư vấn chi tiết về PC, Laptop, Linh kiện dựa trên nhu cầu (gaming, work, office, streaming)
2. Giải đáp câu hỏi về thông số kỹ thuật, hiệu năng, tương thích
3. Hỗ trợ thông tin về giá cả, khuyến mãi, chính sách bảo hành, giao hàng, thanh toán
4. Giới thiệu các sản phẩm hot, review sản phẩm, so sánh hiệu năng
5. Giúp khách chọn cấu hình PC phù hợp với budget và mục đích
6. Hỗ trợ 24/7, trả lời bất kỳ câu hỏi nào

QUY TẮC TRẢ LỜI:
- Luôn kinh doanh, thân thiện, nhiệt tình và chuyên nghiệp
- Trả lời chi tiết, cung cấp thông tin hữu ích
- Nếu không biết thông tin cụ thể, hãy nói: 'Xin lỗi, thông tin này tôi cần xác nhận với nhân viên. Bạn có thể để lại số điện thoại để chúng tôi gọi lại hoặc liên hệ hotline: 0123.456.789'
- Khuyến khích khách truy cập website hoặc liên hệ trực tiếp để xem hàng
- Trả lời bằng tiếng Việt, ngắn gọn nhưng đầy đủ thông tin
- Luôn kết thúc bằng một câu hỏi hoặc đề nghị để khách tiếp tục tương tác
- Có thể trả lời bất kỳ câu hỏi nào, không từ chối, luôn cố gắng giúp đỡ

PERSONALITY:
- Vui vẻ, hòa đồng, dễ gần
- Có kiến thức sâu về công nghệ PC
- Luôn sẵn sàng hỗ trợ 24/7
- Chủ động gợi ý, tư vấn tốt nhất cho khách
- Giải thích kỹ thuật bằng ngôn ngữ dễ hiểu";
        }

        private string GetKnowledgeBase()
        {
            return $@"
=== KNOWLEDGE BASE PC STORE ===

{ChatbotKnowledgeBase.GetProductCatalog()}

{ChatbotKnowledgeBase.GetFAQ()}

{ChatbotKnowledgeBase.GetPolicies()}

{ChatbotKnowledgeBase.GetContactInfo()}

{ChatbotKnowledgeBase.GetBuildRecommendations()}

=== HẾT KNOWLEDGE BASE ===
";
        }
    }
}

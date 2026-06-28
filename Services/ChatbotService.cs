using Google.GenAI;
using PC_Store.DTOs.Chat;

namespace PC_Store.Services
{
    public interface IChatbotService
    {
        Task<string> GetChatbotResponse(string userMessage, IEnumerable<ChatHistoryItem> history);
        Task<string> GetContextualGreetingAsync(ContextualGreetingRequest request);
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

        public async Task<string> GetChatbotResponse(string userMessage, IEnumerable<ChatHistoryItem> history)
        {
            try
            {
                // Format history
                string historyText = "";
                if (history != null && history.Any())
                {
                    historyText = "--- LỊCH SỬ HỘI THOẠI (Hãy dựa vào lịch sử này để duy trì mạch hội thoại và đại từ xưng hô) ---\n";
                    foreach (var h in history.OrderBy(x => x.CreatedAt))
                    {
                        historyText += $"[Khách hàng]: {h.UserMessage}\n";
                        historyText += $"[Trợ lý AI]: {h.BotResponse}\n\n";
                    }
                }

                var fullPrompt = $@"{_systemPrompt}

{GetKnowledgeBase()}

{historyText}
--- CÂU HỎI MỚI CỦA KHÁCH HÀNG ---
{userMessage}";

                var response = await _client.Models.GenerateContentAsync(
                    model: "gemini-2.5-flash",
                    contents: fullPrompt
                );

                var text = response?.Text;

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

        public async Task<string> GetContextualGreetingAsync(ContextualGreetingRequest request)
        {
            try
            {
                string contextPrompt = "";
                if (!string.IsNullOrEmpty(request.ProductName))
                {
                    if (request.PageType == "ProductDetail")
                    {
                        contextPrompt = $"Khách hàng đang xem chi tiết sản phẩm: {request.ProductName}. Hãy chào họ thân thiện và hỏi xem có cần tư vấn chi tiết về sản phẩm này (hiệu năng, thông số, nguồn đi kèm, bo mạch tương thích) không.";
                    }
                    else
                    {
                        contextPrompt = $"Khách hàng vừa xem sản phẩm: {request.ProductName} và hiện đang di chuyển qua trang khác ({request.PageType}). Hãy chào họ, chủ động nhắc lại rằng bạn thấy họ vừa xem sản phẩm này (ví dụ: 'Tôi thấy bạn vừa xem sản phẩm {request.ProductName}...') và hỏi xem họ có cần hỗ trợ tư vấn linh kiện hoặc giải đáp thắc mắc gì thêm không.";
                    }
                }
                else if (request.PageType == "ShoppingCart")
                {
                    contextPrompt = "Khách hàng đang ở trang Giỏ hàng. Hãy tạo một câu chào thân thiện, nhắc nhở họ về chương trình khuyến mãi hiện có (mua 2 giảm 5%, mua 3 giảm 10%) và chủ động hỏi xem có cần tư vấn thêm linh kiện khác để tối ưu cấu hình và nhận ưu đãi không.";
                }
                else if (request.PageType == "PCBuild")
                {
                    contextPrompt = "Khách hàng đang ở trang tự xây dựng cấu hình PC Build. Hãy tạo một câu chào chủ động, đề xuất kiểm tra tính tương thích giữa các linh kiện (CPU, Mainboard, RAM, Nguồn) và hỏi xem họ có cần tư vấn cấu hình tối ưu trong tầm giá không.";
                }
                else
                {
                    contextPrompt = "Khách hàng đang xem trang web của chúng tôi. Hãy gửi lời chào nhiệt tình từ PC Store và hỏi xem họ đang tìm kiếm dòng PC, Laptop hay linh kiện công nghệ nào hôm nay.";
                }

                var fullPrompt = $@"{_systemPrompt}

{GetKnowledgeBase()}

--- YÊU CẦU NGỮ CẢNH ---
{contextPrompt}

LƯU Ý: Tạo câu chào ngắn gọn (khoảng 2-3 câu), tự nhiên, hướng đến đúng ngữ cảnh sản phẩm/trang họ đang xem.";

                var response = await _client.Models.GenerateContentAsync(
                    model: "gemini-2.5-flash",
                    contents: fullPrompt
                );

                return response?.Text ?? $"Chào bạn! Tôi thấy bạn đang quan tâm đến sản phẩm {request.ProductName}. Bạn có cần tôi tư vấn gì thêm không?";
            }
            catch (Exception)
            {
                return !string.IsNullOrEmpty(request.ProductName)
                    ? $"Chào bạn! Tôi thấy bạn đang quan tâm đến sản phẩm {request.ProductName}. Bạn có cần tôi tư vấn về hiệu năng chơi game hoặc linh kiện đi kèm phù hợp không?"
                    : "Chào bạn! Tôi có thể hỗ trợ gì cho bạn về sản phẩm và cấu hình PC hôm nay?";
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

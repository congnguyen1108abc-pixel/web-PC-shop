using Microsoft.AspNetCore.Mvc;
using PC_Store.Services;

namespace PC_Store.Controllers
{
    [ApiController]
    [Route("api/chatbot")]
    public class ChatbotController : ControllerBase
    {
        private readonly IChatbotService _chatbotService;

        public ChatbotController(IChatbotService chatbotService)
        {
            _chatbotService = chatbotService;
        }

        [HttpPost]
        public async Task<IActionResult> Chat([FromBody] ChatRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Message))
            {
                return BadRequest(new { reply = "Vui lòng nhập câu hỏi." });
            }

            try
            {
                var response = await _chatbotService.GetChatbotResponse(request.Message);
                return Ok(new { reply = response });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { reply = $"Lỗi hệ thống: {ex.Message}" });
            }
        }
    }

    public class ChatRequest
    {
        public string Message { get; set; } = string.Empty;
    }
}

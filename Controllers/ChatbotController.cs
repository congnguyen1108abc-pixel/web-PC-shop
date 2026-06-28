using Microsoft.AspNetCore.Mvc;
using PC_Store.Services;
using PC_Store.Repositories.Interfaces;
using PC_Store.DTOs.Chat;

namespace PC_Store.Controllers
{
    [ApiController]
    [Route("api/chatbot")]
    public class ChatbotController : ControllerBase
    {
        private readonly IChatbotService _chatbotService;
        private readonly IChatRepository _chatRepo;

        public ChatbotController(IChatbotService chatbotService, IChatRepository chatRepo)
        {
            _chatbotService = chatbotService;
            _chatRepo = chatRepo;
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
                // Fetch previous conversation history for the current session from SQL Server
                var history = Enumerable.Empty<ChatHistoryItem>();
                if (!string.IsNullOrEmpty(request.SessionId))
                {
                    try
                    {
                        history = await _chatRepo.GetHistoryAsync(new ChatHistoryRequest(request.SessionId));
                    }
                    catch (Exception dbEx)
                    {
                        Console.WriteLine($"[Chatbot DB History Error] Failed to load history: {dbEx.Message}");
                    }
                }

                var response = await _chatbotService.GetChatbotResponse(request.Message, history);

                // Save message history to ChatMessages database table
                try
                {
                    await _chatRepo.SaveMessageAsync(new ChatSaveMessageRequest(
                        request.UserId,
                        request.SessionId ?? "default_session",
                        request.Message,
                        response
                    ));
                }
                catch (Exception dbEx)
                {
                    Console.WriteLine($"[Chatbot DB Error] Failed to save message: {dbEx.Message}");
                }

                return Ok(new { reply = response });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { reply = $"Lỗi hệ thống: {ex.Message}" });
            }
        }

        [HttpPost("context-greeting")]
        public async Task<IActionResult> GetContextGreeting([FromBody] ContextualGreetingRequest request)
        {
            if (request == null)
            {
                return BadRequest(new { reply = "Yêu cầu không hợp lệ." });
            }

            try
            {
                var response = await _chatbotService.GetContextualGreetingAsync(request);

                // Save context greeting to ChatMessages database table
                try
                {
                    await _chatRepo.SaveMessageAsync(new ChatSaveMessageRequest(
                        request.UserId,
                        request.SessionId ?? "default_session",
                        $"[Đọc vị ngữ cảnh: Khách xem {request.PageType}{(string.IsNullOrEmpty(request.ProductName) ? "" : $" - {request.ProductName}")}]",
                        response
                    ));
                }
                catch (Exception dbEx)
                {
                    Console.WriteLine($"[Chatbot Context DB Error] Failed to save greeting: {dbEx.Message}");
                }

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
        public string? SessionId { get; set; }
        public int? UserId { get; set; }
    }
}

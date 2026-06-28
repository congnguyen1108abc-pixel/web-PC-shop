using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using PC_Store.DTOs.Chat;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public sealed class ChatController : ControllerBase
{
    private readonly IChatService _chat;

    public ChatController(IChatService chat)
    {
        _chat = chat;
    }


    /// <summary>
    /// Lấy lịch sử chat theo sessionId.
    /// Cần đăng nhập.
    /// </summary>
    [HttpGet("history")]
    public async Task<ActionResult<IEnumerable<ChatHistoryItem>>> GetHistory(
        [FromQuery] ChatHistoryRequest request)
    {
        var result = await _chat.GetHistoryAsync(request);
        return Ok(result);
    }

    /// <summary>
    /// Lưu tin nhắn chatbot vào DB.
    /// Cần đăng nhập.
    /// </summary>
    [EnableRateLimiting("write")]  // 30 req / phút / IP — chặn spam tin nhắn chatbot
    [HttpPost("message")]
    public async Task<ActionResult> SaveMessage([FromBody] ChatSaveMessageRequest request)
    {
        await _chat.SaveMessageAsync(request);

        return Ok(new
        {
            message = "Đã lưu tin nhắn thành công."
        });
    }
}
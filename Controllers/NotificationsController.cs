using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Notifications;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public sealed class NotificationsController : ControllerBase
{
    private readonly INotificationService _notifications;

    public NotificationsController(INotificationService notifications)
    {
        _notifications = notifications;
    }

    /// <summary>
    /// Lấy danh sách thông báo của user (có phân trang)
    /// </summary>
    [HttpGet("user/{userId:int}")]
    public async Task<ActionResult<PagedResult<NotificationItem>>> GetByUser(int userId, [FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 20, [FromQuery] bool? isRead = null)
    {
        var request = new NotificationQueryRequest(userId, isRead, pageNumber, pageSize);
        var result = await _notifications.GetByUserAsync(request);
        return Ok(result);
    }

    /// <summary>
    /// Đánh dấu đã đọc 1 thông báo
    /// </summary>
    [HttpPut("read")]
    public async Task<ActionResult> MarkRead(NotificationMarkReadRequest request)
    {
        await _notifications.MarkReadAsync(request);

        return Ok(new
        {
            message = "Đã đánh dấu thông báo là đã đọc"
        });
    }

    /// <summary>
    /// Đánh dấu tất cả thông báo đã đọc
    /// </summary>
    [HttpPut("read-all/{userId:int}")]
    public async Task<ActionResult> MarkAllRead(int userId)
    {
        await _notifications.MarkAllReadAsync(userId);

        return Ok(new
        {
            message = "Đã đánh dấu tất cả thông báo là đã đọc"
        });
    }

    /// <summary>
    /// Xóa 1 thông báo
    /// </summary>
    [HttpDelete("{notifId:int}")]
    public async Task<ActionResult> Delete(int notifId, [FromQuery] int userId)
    {
        await _notifications.DeleteAsync(new NotificationDeleteRequest(notifId, userId));

        return Ok(new
        {
            message = "Xóa thông báo thành công"
        });
    }
}
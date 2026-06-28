using Microsoft.AspNetCore.SignalR;

namespace PC_Store.Hubs;

/// <summary>
/// Triển khai INotificationPusher dùng IHubContext để push từ bất kỳ đâu trong app.
/// Không cần kết nối Hub trực tiếp — IHubContext là thread-safe và có thể inject vào Controller/Service.
/// </summary>
public sealed class NotificationPusher : INotificationPusher
{
    private readonly IHubContext<NotificationHub> _hub;
    private readonly ILogger<NotificationPusher> _logger;

    public NotificationPusher(
        IHubContext<NotificationHub> hub,
        ILogger<NotificationPusher> logger)
    {
        _hub    = hub;
        _logger = logger;
    }

    // ── Gửi đến User cụ thể ──────────────────────────────────────────────────

    /// <summary>
    /// Push 1 notification đến user qua nhóm "user_{userId}".
    /// Client lắng nghe event "ReceiveNotification".
    /// </summary>
    public async Task PushToUserAsync(
        int    userId,
        string title,
        string message,
        string type,
        int?   relatedId = null)
    {
        try
        {
            var groupName = $"user_{userId}";

            await _hub.Clients.Group(groupName).SendAsync(
                "ReceiveNotification",
                new
                {
                    title,
                    message,
                    type,        // "Order" | "Warranty" | "System"
                    relatedId,
                    createdAt = DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss")
                });

            _logger.LogDebug(
                "SignalR → [{Group}] event=ReceiveNotification type={Type} relatedId={RelatedId}",
                groupName, type, relatedId);
        }
        catch (Exception ex)
        {
            // Không để lỗi SignalR làm crash business logic
            _logger.LogWarning(ex,
                "SignalR PushToUser thất bại (userId={UserId}). Hệ thống vẫn hoạt động bình thường.",
                userId);
        }
    }

    // ── Gửi đến nhóm Admin ────────────────────────────────────────────────────

    /// <summary>
    /// Push sự kiện đến tất cả Admin đang online qua nhóm "admin".
    /// Client lắng nghe event "AdminEvent".
    /// </summary>
    public async Task PushToAdminAsync(string eventType, object data)
    {
        try
        {
            await _hub.Clients.Group("admin").SendAsync(
                "AdminEvent",
                new
                {
                    eventType,   // "NewOrder" | "OrderUpdated" | "NewWarrantyClaim"
                    data,
                    timestamp = DateTime.Now.ToString("yyyy-MM-ddTHH:mm:ss")
                });

            _logger.LogDebug(
                "SignalR → [admin] event=AdminEvent type={EventType}",
                eventType);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex,
                "SignalR PushToAdmin thất bại (eventType={EventType}). Hệ thống vẫn hoạt động bình thường.",
                eventType);
        }
    }
}

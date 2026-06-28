using Microsoft.AspNetCore.SignalR;

namespace PC_Store.Hubs;

/// <summary>
/// SignalR Hub xử lý kết nối real-time giữa server và client.
///
/// Luồng hoạt động:
///   1. Client kết nối → gọi JoinUserGroup(userId) để nhận thông báo cá nhân
///   2. Admin kết nối  → gọi JoinAdminGroup()     để nhận sự kiện đơn hàng mới
///   3. Server gửi push từ INotificationPusher khi có sự kiện (đặt hàng, đổi trạng thái...)
///
/// Client nhận 2 loại event:
///   - "ReceiveNotification" → thông báo cá nhân (đặt hàng, xác nhận, hủy, bảo hành...)
///   - "AdminEvent"          → sự kiện Admin (đơn mới, đơn đổi trạng thái)
/// </summary>
public sealed class NotificationHub : Hub
{
    private readonly ILogger<NotificationHub> _logger;

    public NotificationHub(ILogger<NotificationHub> logger)
    {
        _logger = logger;
    }

    // ── Client tự đăng ký nhóm khi connect ───────────────────────────────────

    /// <summary>
    /// Khách hàng gọi khi đăng nhập xong để nhận thông báo cá nhân.
    /// </summary>
    public async Task JoinUserGroup(string userId)
    {
        var groupName = $"user_{userId}";
        await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
        _logger.LogInformation("SignalR: Client {ConnectionId} joined group [{Group}]",
            Context.ConnectionId, groupName);
    }

    /// <summary>
    /// Admin gọi khi vào trang Admin để nhận sự kiện đơn hàng mới real-time.
    /// </summary>
    public async Task JoinAdminGroup()
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, "admin");
        _logger.LogInformation("SignalR: Admin {ConnectionId} joined admin group",
            Context.ConnectionId);
    }

    /// <summary>
    /// Tự động xóa khỏi group khi client ngắt kết nối.
    /// (ASP.NET Core SignalR tự dọn group, không cần làm gì thêm.)
    /// </summary>
    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        _logger.LogInformation("SignalR: Client {ConnectionId} disconnected",
            Context.ConnectionId);
        await base.OnDisconnectedAsync(exception);
    }
}

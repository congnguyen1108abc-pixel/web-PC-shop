namespace PC_Store.DTOs.Notifications;

public sealed record NotificationQueryRequest(
    int UserId,
    bool? IsRead = null,
    int PageNumber = 1,
    int PageSize = 20)
{
    /// <summary>Validate và normalize pagination parameters</summary>
    public NotificationQueryRequest Normalize()
    {
        var pageNum = PageNumber < 1 ? 1 : PageNumber;
        var pageSize = PageSize < 1 ? 20 : (PageSize > 100 ? 100 : PageSize);
        
        return this with { PageNumber = pageNum, PageSize = pageSize };
    }
};

public sealed record NotificationItem(
    int NotifId,
    int UserId,
    string Title,
    string Message,
    string Type,
    int? RelatedId,
    bool IsRead,
    DateTime CreatedAt);

public sealed record NotificationMarkReadRequest(int NotifId, int UserId);

public sealed record NotificationMarkAllReadRequest(int UserId);

public sealed record NotificationDeleteRequest(int NotifId, int UserId);

/// <summary>Admin gửi thông báo đến 1 hoặc nhiều user</summary>
public sealed record AdminSendNotificationRequest(
    int[] UserIds,     // Danh sách userId cần gửi
    string Title,
    string Message,
    string Type,       // "Order" | "Promotion" | "System" | "Warranty"
    int? RelatedId);



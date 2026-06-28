using PC_Store.DTOs.Common;
using PC_Store.DTOs.Notifications;

namespace PC_Store.Repositories.Interfaces;

public interface INotificationRepository
{
    Task<PagedResult<NotificationItem>> GetByUserAsync(NotificationQueryRequest request);
    Task MarkReadAsync(NotificationMarkReadRequest request);
    Task MarkAllReadAsync(int userId);
    Task DeleteAsync(NotificationDeleteRequest request);
    Task<int?> SendAsync(int userId, string title, string message, string type, int? relatedId);
}


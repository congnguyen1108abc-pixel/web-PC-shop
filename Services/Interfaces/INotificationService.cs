using PC_Store.DTOs.Common;
using PC_Store.DTOs.Notifications;

namespace PC_Store.Services.Interfaces;

public interface INotificationService
{
    Task<PagedResult<NotificationItem>> GetByUserAsync(NotificationQueryRequest request);
    Task MarkReadAsync(NotificationMarkReadRequest request);
    Task MarkAllReadAsync(int userId);
    Task DeleteAsync(NotificationDeleteRequest request);
    Task SendNotificationAsync(AdminSendNotificationRequest request);
}



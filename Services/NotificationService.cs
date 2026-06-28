using PC_Store.DTOs.Common;
using PC_Store.DTOs.Notifications;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class NotificationService : INotificationService
{
    private readonly INotificationRepository _repo;
    public NotificationService(INotificationRepository repo) => _repo = repo;

    public Task<PagedResult<NotificationItem>> GetByUserAsync(NotificationQueryRequest request) => _repo.GetByUserAsync(request);
    public Task MarkReadAsync(NotificationMarkReadRequest request) => _repo.MarkReadAsync(request);
    public Task MarkAllReadAsync(int userId) => _repo.MarkAllReadAsync(userId);
    public Task DeleteAsync(NotificationDeleteRequest request) => _repo.DeleteAsync(request);

    public async Task SendNotificationAsync(AdminSendNotificationRequest request)
    {
        foreach (var userId in request.UserIds)
            await _repo.SendAsync(userId, request.Title, request.Message, request.Type, request.RelatedId);
    }
}


using PC_Store.DTOs.Common;
using PC_Store.DTOs.Notifications;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class NotificationRepository : INotificationRepository
{
    private readonly IDbRepository _db;
    public NotificationRepository(IDbRepository db) => _db = db;

    public async Task<PagedResult<NotificationItem>> GetByUserAsync(NotificationQueryRequest request)
    {
        var normalized = request.Normalize();
        
        var items = await _db.QueryAsync<NotificationItemWithTotal>("sp_Notifications_GetByUserPaged", new
        {
            normalized.UserId, normalized.IsRead, normalized.PageNumber, normalized.PageSize
        });

        var itemsList = items.ToList();
        var totalRecords = itemsList.FirstOrDefault()?.TotalRecords ?? 0;

        return new PagedResult<NotificationItem>(
            items: itemsList.Select(x => new NotificationItem(
                x.NotifId, x.UserId, x.Title, x.Message, x.Type, x.RelatedId, x.IsRead, x.CreatedAt
            )),
            totalRecords: totalRecords,
            pageNumber: normalized.PageNumber,
            pageSize: normalized.PageSize
        );
    }

    public Task MarkReadAsync(NotificationMarkReadRequest request)
        => _db.ExecuteAsync("sp_Notification_MarkRead", new { request.NotifId, request.UserId });

    public Task MarkAllReadAsync(int userId)
        => _db.ExecuteAsync("sp_Notification_MarkAllRead", new { UserId = userId });

    public Task DeleteAsync(NotificationDeleteRequest request)
        => _db.ExecuteAsync("sp_Notification_Delete", new { request.NotifId, request.UserId });

    public async Task<int?> SendAsync(int userId, string title, string message, string type, int? relatedId)
    {
        var r = await _db.QuerySingleAsync<NewNotifResult>("sp_Admin_SendNotification", new
        {
            UserId = userId, Title = title, Message = message, Type = type, RelatedId = relatedId
        });
        return r?.NewNotifId;
    }

    private sealed record NewNotifResult(int NewNotifId);

    private sealed record NotificationItemWithTotal(
        int NotifId, int UserId, string Title, string Message, string Type,
        int? RelatedId, bool IsRead, DateTime CreatedAt, int TotalRecords);
}


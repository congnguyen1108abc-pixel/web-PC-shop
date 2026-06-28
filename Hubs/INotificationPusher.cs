namespace PC_Store.Hubs;

/// <summary>
/// Interface để inject INotificationPusher vào bất kỳ Controller/Service nào.
/// Dùng interface giúp dễ mock khi test và tách biệt logic SignalR khỏi business logic.
/// </summary>
public interface INotificationPusher
{
    /// <summary>
    /// Gửi thông báo đến 1 user cụ thể qua nhóm user_{userId}.
    /// Dùng sau khi: đặt hàng, xác nhận đơn, hủy đơn, cập nhật bảo hành.
    /// </summary>
    Task PushToUserAsync(int userId, string title, string message,
        string type, int? relatedId = null);

    /// <summary>
    /// Gửi sự kiện đến nhóm Admin.
    /// Dùng sau khi: có đơn hàng mới, đơn được xử lý.
    /// </summary>
    Task PushToAdminAsync(string eventType, object data);
}

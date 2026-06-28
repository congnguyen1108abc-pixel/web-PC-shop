namespace PC_Store.Models;

public sealed record Notification(
    int NotifId,
    int UserId,
    string Title,
    string Message,
    string Type,
    int? RelatedId,
    bool IsRead,
    DateTime CreatedAt);

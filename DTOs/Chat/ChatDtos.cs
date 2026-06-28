namespace PC_Store.DTOs.Chat;

public sealed record ChatHistoryRequest(string SessionId);

public sealed record ChatHistoryItem(
    int MessageId,
    int? UserId,
    string SessionId,
    string UserMessage,
    string BotResponse,
    DateTime CreatedAt);

public sealed record AdminChatQueryRequest(
    int? UserId,
    string? SessionId,
    DateTime? DateFrom,
    DateTime? DateTo);

public sealed record AdminChatItem(
    int MessageId,
    int? UserId,
    string? FullName,
    string? Email,
    string SessionId,
    string UserMessage,
    string BotResponse,
    DateTime CreatedAt);

// Customer / visitor gửi message lên chatbot
public sealed record ChatSaveMessageRequest(
    int? UserId,
    string SessionId,
    string UserMsg,
    string BotRes);

public sealed record ContextualGreetingRequest(
    string Url,
    string PageType,
    string PageTitle,
    string ProductName,
    string? SessionId,
    int? UserId);


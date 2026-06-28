using PC_Store.DTOs.Chat;

namespace PC_Store.Services.Interfaces;

public interface IChatService
{
    Task<IEnumerable<ChatHistoryItem>> GetHistoryAsync(ChatHistoryRequest request);
    Task<IEnumerable<AdminChatItem>> GetAdminMessagesAsync(AdminChatQueryRequest request);
    Task SaveMessageAsync(ChatSaveMessageRequest request);
}


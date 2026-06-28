using PC_Store.DTOs.Chat;

namespace PC_Store.Repositories.Interfaces;

public interface IChatRepository
{
    Task<IEnumerable<ChatHistoryItem>> GetHistoryAsync(ChatHistoryRequest request);
    Task<IEnumerable<AdminChatItem>> GetAdminMessagesAsync(AdminChatQueryRequest request);
    Task SaveMessageAsync(ChatSaveMessageRequest request);
}

using PC_Store.DTOs.Chat;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class ChatService : IChatService
{
    private readonly IChatRepository _repo;
    public ChatService(IChatRepository repo) => _repo = repo;

    public Task<IEnumerable<ChatHistoryItem>> GetHistoryAsync(ChatHistoryRequest request) => _repo.GetHistoryAsync(request);
    public Task<IEnumerable<AdminChatItem>> GetAdminMessagesAsync(AdminChatQueryRequest request) => _repo.GetAdminMessagesAsync(request);
    public Task SaveMessageAsync(ChatSaveMessageRequest request) => _repo.SaveMessageAsync(request);
}

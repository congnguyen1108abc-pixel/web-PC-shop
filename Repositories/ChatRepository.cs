using PC_Store.DTOs.Chat;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class ChatRepository : IChatRepository
{
    private readonly IDbRepository _db;
    public ChatRepository(IDbRepository db) => _db = db;

    public Task<IEnumerable<ChatHistoryItem>> GetHistoryAsync(ChatHistoryRequest request)
        => _db.QueryAsync<ChatHistoryItem>("sp_Chat_GetHistory", new { request.SessionId });

    public Task<IEnumerable<AdminChatItem>> GetAdminMessagesAsync(AdminChatQueryRequest request)
        => _db.QueryAsync<AdminChatItem>("sp_Admin_GetChatMessages", new
        {
            request.UserId, request.SessionId, request.DateFrom, request.DateTo
        });

    public Task SaveMessageAsync(ChatSaveMessageRequest request)
        => _db.ExecuteAsync("sp_Chat_SaveMessage", new
        {
            request.UserId,
            request.SessionId,
            UserMsg = request.UserMsg,
            BotRes = request.BotRes
        });
}

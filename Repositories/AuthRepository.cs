using PC_Store.DTOs.Auth;
using PC_Store.Models;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class AuthRepository : IAuthRepository
{
    private readonly IDbRepository _db;

    public AuthRepository(IDbRepository db) => _db = db;

    public Task<AuthUser?> GoogleLoginAsync(AuthGoogleLoginRequest request)
        => _db.QuerySingleAsync<AuthUser>("sp_Auth_GoogleLogin", new
        {
            request.Email,
            request.FullName,
            request.ProviderKey,
            AvatarURL = request.AvatarUrl
        });

    public Task<int?> RegisterAsync(AuthRegisterRequest request)
        => _db.QuerySingleAsync<int?>("sp_Auth_Register", new
        {
            request.FullName,
            request.Email,
            PasswordHash = request.Password,  // Password đã được hash ở Controller
            request.PhoneNumber
        });

    public Task<AuthUser?> LoginAsync(AuthLoginRequest request)
        => _db.QuerySingleAsync<AuthUser>("sp_Auth_LoginLocal", new
        {
            request.Email,
            PasswordHash = request.Password  // Password đã được hash ở Controller
        });

    public async Task<int?> ChangePasswordAsync(ChangePasswordRequest request)
    {
        var r = await _db.QuerySingleAsync<ChangedResult>("sp_Auth_ChangePassword", new
        {
            request.UserId,
            request.OldPasswordHash,
            request.NewPasswordHash
        });
        return r?.UpdatedUserId;
    }

    private sealed record ChangedResult(int UpdatedUserId);

    public async Task<bool> CheckEmailAsync(string email)
    {
        var r = await _db.QuerySingleAsync<EmailExistsResult>("sp_Auth_CheckEmail", new { Email = email });
        return r?.Exists == 1;
    }

    private sealed record EmailExistsResult(int Exists);

    public Task<ForgotPasswordResult?> ForgotPasswordAsync(string email)
        => _db.QuerySingleAsync<ForgotPasswordResult>("sp_Auth_ForgotPassword", new { Email = email });

    public async Task<int?> ResetPasswordAsync(string resetToken, string newPasswordHash)
    {
        var r = await _db.QuerySingleAsync<ResetResult>("sp_Auth_ResetPassword", new
        {
            ResetToken = resetToken,
            NewPasswordHash = newPasswordHash
        });
        return r?.UpdatedUserId;
    }

    private sealed record ResetResult(int UpdatedUserId);

    public Task<VerifyTokenResult?> VerifyResetTokenAsync(string resetToken)
        => _db.QuerySingleAsync<VerifyTokenResult>("sp_Auth_VerifyResetToken", new { ResetToken = resetToken });

    // ============================================================
    // REFRESH TOKEN METHODS
    // ============================================================

    public async Task<int?> CreateRefreshTokenAsync(int userId, string refreshToken, DateTime expiresAt, string? deviceInfo)
    {
        var result = await _db.QuerySingleAsync<CreateRefreshTokenResult>("sp_Auth_CreateRefreshToken", new
        {
            UserID = userId,
            RefreshToken = refreshToken,
            ExpiresAt = expiresAt,
            DeviceInfo = deviceInfo
        });
        return result?.TokenID;
    }

    private sealed record CreateRefreshTokenResult(int TokenID);

    public Task<RefreshTokenVerifyResult?> VerifyRefreshTokenAsync(string refreshToken)
        => _db.QuerySingleAsync<RefreshTokenVerifyResult>("sp_Auth_VerifyRefreshToken", new { RefreshToken = refreshToken });

    public async Task<bool> RevokeRefreshTokenAsync(string refreshToken)
    {
        var result = await _db.QuerySingleAsync<RevokeResult>("sp_Auth_RevokeRefreshToken", new { RefreshToken = refreshToken });
        return result?.RowsAffected > 0;
    }

    private sealed record RevokeResult(int RowsAffected);

    public async Task<bool> RevokeAllUserTokensAsync(int userId)
    {
        var result = await _db.QuerySingleAsync<RevokeResult>("sp_Auth_RevokeAllUserTokens", new { UserID = userId });
        return result?.RowsAffected > 0;
    }
}

// Helper records cho Forgot Password
public sealed record ForgotPasswordResult(
    string? ResetToken,
    int? UserID,
    string? FullName,
    string? Email,
    DateTime? ExpiresAt);

public sealed record VerifyTokenResult(
    int TokenID,
    int UserID,
    string Email,
    string? FullName,
    DateTime ExpiresAt,
    bool IsUsed,
    bool IsValid);

// Helper class cho Refresh Token để Dapper map linh hoạt các cột trả về từ sp_Auth_VerifyRefreshToken
public sealed class RefreshTokenVerifyResult
{
    public int TokenID { get; set; }
    public int UserID { get; set; }
    public string Email { get; set; } = null!;
    public string? FullName { get; set; }
    public string Role { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
    public bool IsRevoked { get; set; }
    public bool IsValid { get; set; }
}

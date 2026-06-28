using PC_Store.DTOs.Auth;
using PC_Store.Models;

namespace PC_Store.Repositories.Interfaces;

public interface IAuthRepository
{
    Task<AuthUser?> GoogleLoginAsync(AuthGoogleLoginRequest request);
    Task<int?> RegisterAsync(AuthRegisterRequest request);
    Task<AuthUser?> LoginAsync(AuthLoginRequest request);
    Task<int?> ChangePasswordAsync(ChangePasswordRequest request);
    Task<bool> CheckEmailAsync(string email);
    Task<ForgotPasswordResult?> ForgotPasswordAsync(string email);
    Task<int?> ResetPasswordAsync(string resetToken, string newPasswordHash);
    Task<VerifyTokenResult?> VerifyResetTokenAsync(string resetToken);
    
    // Refresh Token methods
    Task<int?> CreateRefreshTokenAsync(int userId, string refreshToken, DateTime expiresAt, string? deviceInfo);
    Task<RefreshTokenVerifyResult?> VerifyRefreshTokenAsync(string refreshToken);
    Task<bool> RevokeRefreshTokenAsync(string refreshToken);
    Task<bool> RevokeAllUserTokensAsync(int userId);
}


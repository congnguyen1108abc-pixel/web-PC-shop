using PC_Store.DTOs.Auth;

namespace PC_Store.Services.Interfaces;

public interface IAuthService
{
    Task<AuthResponseWithRefresh?> GoogleLoginAsync(AuthGoogleLoginRequest request, string? deviceInfo);
    Task<int?> RegisterAsync(AuthRegisterRequest request);
    Task<AuthResponseWithRefresh?> LoginAsync(AuthLoginRequest request, string? deviceInfo);
    Task<int?> ChangePasswordAsync(ChangePasswordRequest request);
    Task<bool> CheckEmailAsync(string email);
    Task<ForgotPasswordResponse> ForgotPasswordAsync(ForgotPasswordRequest request);
    Task<int?> ResetPasswordAsync(ResetPasswordRequest request);
    Task<VerifyResetTokenResponse> VerifyResetTokenAsync(VerifyResetTokenRequest request);
    
    // Refresh Token methods
    Task<RefreshTokenResponse?> RefreshTokenAsync(RefreshTokenRequest request, string? deviceInfo);
    Task<bool> RevokeTokenAsync(RevokeTokenRequest request);
}


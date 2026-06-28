using PC_Store.DTOs.Auth;

namespace PC_Store.Services.Interfaces;

public interface IAuthService
{
    Task<AuthResponse?> GoogleLoginAsync(AuthGoogleLoginRequest request);
    Task<int?> RegisterAsync(AuthRegisterRequest request);
    Task<AuthResponse?> LoginAsync(AuthLoginRequest request);
    Task<int?> ChangePasswordAsync(ChangePasswordRequest request);
    Task<bool> CheckEmailAsync(string email);
    Task<ForgotPasswordResponse> ForgotPasswordAsync(ForgotPasswordRequest request);
    Task<int?> ResetPasswordAsync(ResetPasswordRequest request);
    Task<VerifyResetTokenResponse> VerifyResetTokenAsync(VerifyResetTokenRequest request);
    
    // Refresh Token methods
    Task<RefreshTokenResponse?> RefreshTokenAsync(RefreshTokenRequest request, string? deviceInfo);
    Task<bool> RevokeTokenAsync(RevokeTokenRequest request);
}


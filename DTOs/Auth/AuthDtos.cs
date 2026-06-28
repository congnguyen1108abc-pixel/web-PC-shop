namespace PC_Store.DTOs.Auth;

public sealed record AuthGoogleLoginRequest(
    string Email,
    string FullName,
    string ProviderKey,
    string? AvatarUrl);

public sealed record AuthRegisterRequest(
    string FullName,
    string Email,
    string Password,
    string? PhoneNumber);

public sealed record AuthResponse(
    int UserId,
    string? FullName,
    string Email,
    string Role,
    string Token);

/// <summary>Đổi mật khẩu — frontend phải hash password trước khi gửi</summary>
public sealed record ChangePasswordRequest(
    int UserId,
    string OldPasswordHash,
    string NewPasswordHash);

/// <summary>Quên mật khẩu — gửi email chứa link reset</summary>
public sealed record ForgotPasswordRequest(
    string Email);

/// <summary>Response sau khi gửi email reset password</summary>
public sealed record ForgotPasswordResponse(
    bool Success,
    string Message);

/// <summary>Reset mật khẩu bằng token — frontend phải hash password trước khi gửi</summary>
public sealed record ResetPasswordRequest(
    string ResetToken,
    string NewPasswordHash);

/// <summary>Verify token có hợp lệ không</summary>
public sealed record VerifyResetTokenRequest(
    string ResetToken);

/// <summary>Response khi verify token</summary>
public sealed record VerifyResetTokenResponse(
    bool IsValid,
    string? Email,
    string? Message);

// ============================================================
// REFRESH TOKEN DTOs
// ============================================================

/// <summary>Response khi đăng nhập — bao gồm cả AccessToken và RefreshToken</summary>
public sealed record AuthResponseWithRefresh(
    int UserId,
    string? FullName,
    string Email,
    string Role,
    string AccessToken,
    string RefreshToken,
    DateTime AccessTokenExpires,
    DateTime RefreshTokenExpires);

/// <summary>Request để refresh access token</summary>
public sealed record RefreshTokenRequest(
    string RefreshToken);

/// <summary>Response sau khi refresh token thành công</summary>
public sealed record RefreshTokenResponse(
    string AccessToken,
    string RefreshToken,
    DateTime AccessTokenExpires,
    DateTime RefreshTokenExpires);

/// <summary>Request để revoke refresh token (đăng xuất)</summary>
public sealed record RevokeTokenRequest(
    string RefreshToken);


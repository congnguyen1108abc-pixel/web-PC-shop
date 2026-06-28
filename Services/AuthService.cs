using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using PC_Store.DTOs.Auth;
using PC_Store.Models;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class AuthService : IAuthService
{
    private readonly IAuthRepository _auth;
    private readonly IConfiguration _config;
    private readonly IEmailService _emailService;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IAuthRepository auth,
        IConfiguration config,
        IEmailService emailService,
        ILogger<AuthService> logger)
    {
        _auth = auth;
        _config = config;
        _emailService = emailService;
        _logger = logger;
    }

    public async Task<AuthResponse?> GoogleLoginAsync(AuthGoogleLoginRequest request)
    {
        var user = await _auth.GoogleLoginAsync(request);

        if (user is null)
            return null;

        if (!user.IsActive)
        {
            _logger.LogWarning("User {Email} cố đăng nhập Google nhưng tài khoản đã bị khóa", request.Email);
            throw new UnauthorizedAccessException("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.");
        }

        var token = GenerateToken(user);

        // Note: Để tương thích ngược, method này vẫn trả AuthResponse cũ
        // Frontend nên chuyển sang dùng endpoint mới trả về AuthResponseWithRefresh
        return new AuthResponse(
            user.UserId,
            user.FullName,
            user.Email,
            user.Role,
            token
        );
    }

    public Task<int?> RegisterAsync(AuthRegisterRequest request)
    {
        return _auth.RegisterAsync(request);
    }

    public async Task<AuthResponse?> LoginAsync(AuthLoginRequest request)
    {
        var user = await _auth.LoginAsync(request);

        if (user is null)
            return null;

        if (!user.IsActive)
        {
            _logger.LogWarning("User {Email} cố đăng nhập nhưng tài khoản đã bị khóa", request.Email);
            throw new UnauthorizedAccessException("Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.");
        }

        var token = GenerateToken(user);

        // Note: Để tương thích ngược, method này vẫn trả AuthResponse cũ
        // Frontend nên chuyển sang dùng endpoint mới trả về AuthResponseWithRefresh
        return new AuthResponse(
            user.UserId,
            user.FullName,
            user.Email,
            user.Role,
            token
        );
    }

    public Task<int?> ChangePasswordAsync(ChangePasswordRequest request)
    {
        return _auth.ChangePasswordAsync(request);
    }

    public Task<bool> CheckEmailAsync(string email)
    {
        return _auth.CheckEmailAsync(email);
    }

    public async Task<ForgotPasswordResponse> ForgotPasswordAsync(ForgotPasswordRequest request)
    {
        try
        {
            // Gọi SP để tạo token
            var result = await _auth.ForgotPasswordAsync(request.Email);

            // Nếu email không tồn tại hoặc không active → trả về success (không tiết lộ thông tin)
            if (result?.ResetToken == null || result.Email == null)
            {
                _logger.LogWarning("Forgot password request cho email không tồn tại: {Email}", request.Email);
                return new ForgotPasswordResponse(
                    Success: true,
                    Message: "Nếu email tồn tại trong hệ thống, bạn sẽ nhận được email hướng dẫn đặt lại mật khẩu."
                );
            }

            // Gửi email
            var emailSent = await _emailService.SendPasswordResetEmailAsync(
                result.Email,
                result.FullName ?? "User",
                result.ResetToken
            );

            if (!emailSent)
            {
                _logger.LogError("Không thể gửi email reset password đến {Email}", result.Email);
                return new ForgotPasswordResponse(
                    Success: false,
                    Message: "Có lỗi xảy ra khi gửi email. Vui lòng thử lại sau."
                );
            }

            _logger.LogInformation("Đã gửi email reset password đến {Email}", result.Email);

            return new ForgotPasswordResponse(
                Success: true,
                Message: "Nếu email tồn tại trong hệ thống, bạn sẽ nhận được email hướng dẫn đặt lại mật khẩu."
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Exception trong ForgotPasswordAsync cho email {Email}", request.Email);
            return new ForgotPasswordResponse(
                Success: false,
                Message: "Có lỗi xảy ra. Vui lòng thử lại sau."
            );
        }
    }

    public async Task<int?> ResetPasswordAsync(ResetPasswordRequest request)
    {
        try
        {
            // Verify token trước
            var verifyResult = await _auth.VerifyResetTokenAsync(request.ResetToken);

            if (verifyResult == null || !verifyResult.IsValid)
            {
                _logger.LogWarning("Reset password với token không hợp lệ");
                return null;
            }

            // Reset password
            var userId = await _auth.ResetPasswordAsync(request.ResetToken, request.NewPasswordHash);

            if (userId != null)
            {
                // Gửi email xác nhận
                _ = _emailService.SendPasswordResetConfirmationAsync(
                    verifyResult.Email,
                    verifyResult.FullName ?? "User"
                );

                _logger.LogInformation("User {UserId} đã reset password thành công", userId);
            }

            return userId;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Exception trong ResetPasswordAsync");
            return null;
        }
    }

    public async Task<VerifyResetTokenResponse> VerifyResetTokenAsync(VerifyResetTokenRequest request)
    {
        try
        {
            var result = await _auth.VerifyResetTokenAsync(request.ResetToken);

            if (result == null)
            {
                return new VerifyResetTokenResponse(
                    IsValid: false,
                    Email: null,
                    Message: "Token không hợp lệ"
                );
            }

            if (!result.IsValid)
            {
                if (result.IsUsed)
                {
                    return new VerifyResetTokenResponse(
                        IsValid: false,
                        Email: null,
                        Message: "Token đã được sử dụng"
                    );
                }
                else if (result.ExpiresAt < DateTime.Now)
                {
                    return new VerifyResetTokenResponse(
                        IsValid: false,
                        Email: null,
                        Message: "Token đã hết hạn"
                    );
                }
                else
                {
                    return new VerifyResetTokenResponse(
                        IsValid: false,
                        Email: null,
                        Message: "Token không hợp lệ"
                    );
                }
            }

            return new VerifyResetTokenResponse(
                IsValid: true,
                Email: result.Email,
                Message: "Token hợp lệ"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Exception trong VerifyResetTokenAsync");
            return new VerifyResetTokenResponse(
                IsValid: false,
                Email: null,
                Message: "Có lỗi xảy ra"
            );
        }
    }

    private string GenerateToken(AuthUser user)
    {
        var jwtKey = _config["Jwt:Key"];

        if (string.IsNullOrWhiteSpace(jwtKey))
            throw new InvalidOperationException("Jwt:Key chưa được cấu hình trong appsettings.json.");

        var issuer = _config["Jwt:Issuer"];
        var audience = _config["Jwt:Audience"];

        var claims = new List<Claim>
        {
            // UserId
            new Claim(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),

            // User information
            new Claim(ClaimTypes.Name, user.FullName ?? string.Empty),
            new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new Claim(ClaimTypes.Email, user.Email ?? string.Empty),

            // Role: dòng này rất quan trọng cho [Authorize(Roles = "...")]
            new Claim(ClaimTypes.Role, user.Role ?? "Customer"),

            // Token id
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var signingKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(jwtKey)
        );

        var credentials = new SigningCredentials(
            signingKey,
            SecurityAlgorithms.HmacSha256
        );

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddHours(4),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    // ============================================================
    // REFRESH TOKEN METHODS
    // ============================================================

    /// <summary>
    /// Tạo cặp Access Token + Refresh Token mới
    /// </summary>
    private (string AccessToken, string RefreshToken, DateTime AccessExpires, DateTime RefreshExpires) GenerateTokenPair(AuthUser user)
    {
        var jwtKey = _config["Jwt:Key"];

        if (string.IsNullOrWhiteSpace(jwtKey))
            throw new InvalidOperationException("Jwt:Key chưa được cấu hình trong appsettings.json.");

        var issuer = _config["Jwt:Issuer"];
        var audience = _config["Jwt:Audience"];

        // Đọc cấu hình thời gian sống từ appsettings.json
        var accessTokenMinutes = int.Parse(_config["Jwt:AccessTokenExpirationMinutes"] ?? "15");
        var refreshTokenDays = int.Parse(_config["Jwt:RefreshTokenExpirationDays"] ?? "7");

        var accessExpires = DateTime.UtcNow.AddMinutes(accessTokenMinutes);
        var refreshExpires = DateTime.UtcNow.AddDays(refreshTokenDays);

        // Tạo Access Token (JWT)
        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim(ClaimTypes.Name, user.FullName ?? string.Empty),
            new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new Claim(ClaimTypes.Email, user.Email ?? string.Empty),
            new Claim(ClaimTypes.Role, user.Role ?? "Customer"),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var jwtToken = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: accessExpires,
            signingCredentials: credentials
        );

        var accessToken = new JwtSecurityTokenHandler().WriteToken(jwtToken);

        // Tạo Refresh Token (random secure string)
        var refreshToken = GenerateSecureRefreshToken();

        return (accessToken, refreshToken, accessExpires, refreshExpires);
    }

    /// <summary>
    /// Tạo Refresh Token ngẫu nhiên an toàn (256-bit)
    /// </summary>
    private string GenerateSecureRefreshToken()
    {
        var randomBytes = new byte[32]; // 256 bits
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }

    /// <summary>
    /// Refresh Access Token bằng Refresh Token
    /// </summary>
    public async Task<RefreshTokenResponse?> RefreshTokenAsync(RefreshTokenRequest request, string? deviceInfo)
    {
        try
        {
            // 1. Verify refresh token
            var verifyResult = await _auth.VerifyRefreshTokenAsync(request.RefreshToken);

            if (verifyResult == null || !verifyResult.IsValid)
            {
                _logger.LogWarning("Refresh token không hợp lệ hoặc đã hết hạn");
                return null;
            }

            // 2. Tạo cặp token mới
            var user = new AuthUser(
                verifyResult.UserID,
                verifyResult.FullName,
                verifyResult.Email,
                verifyResult.Role,
                true
            );

            var (accessToken, refreshToken, accessExpires, refreshExpires) = GenerateTokenPair(user);

            // 3. Revoke refresh token cũ (rotation strategy)
            await _auth.RevokeRefreshTokenAsync(request.RefreshToken);

            // 4. Lưu refresh token mới vào database
            await _auth.CreateRefreshTokenAsync(
                verifyResult.UserID,
                refreshToken,
                refreshExpires,
                deviceInfo
            );

            _logger.LogInformation("User {UserId} đã refresh token thành công", verifyResult.UserID);

            return new RefreshTokenResponse(
                accessToken,
                refreshToken,
                accessExpires,
                refreshExpires
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Exception trong RefreshTokenAsync");
            return null;
        }
    }

    /// <summary>
    /// Revoke refresh token (đăng xuất)
    /// </summary>
    public async Task<bool> RevokeTokenAsync(RevokeTokenRequest request)
    {
        try
        {
            var result = await _auth.RevokeRefreshTokenAsync(request.RefreshToken);
            
            if (result)
            {
                _logger.LogInformation("Refresh token đã được revoke thành công");
            }
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Exception trong RevokeTokenAsync");
            return false;
        }
    }
}
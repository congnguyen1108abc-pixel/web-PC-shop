using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using PC_Store.DTOs.Auth;
using PC_Store.Services.Interfaces;

namespace PC_Store.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class AuthController : ControllerBase
{
    private readonly IAuthService _auth;

    public AuthController(IAuthService auth)
    {
        _auth = auth;
    }

    /// <summary>
    /// Helper method để hash password bằng SHA256
    /// </summary>
    private static string HashPassword(string password)
    {
        using var sha256 = SHA256.Create();
        var bytes = Encoding.UTF8.GetBytes(password);
        var hash = sha256.ComputeHash(bytes);
        return BitConverter.ToString(hash).Replace("-", "").ToLower();
    }

    /// <summary>
    /// Đăng nhập bằng tài khoản Google.
    /// Public API: không cần token.
    /// Gọi Stored Procedure: sp_Auth_GoogleLogin.
    /// </summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth")]   // 5 req / phút / IP — chặn giả mạo Google token
    [HttpPost("google-login")]
    public async Task<ActionResult<AuthResponse>> GoogleLogin(
        [FromBody] AuthGoogleLoginRequest request)
    {
        try
        {
            var result = await _auth.GoogleLoginAsync(request);

            if (result is null)
                return Unauthorized(new { message = "Đăng nhập Google thất bại" });

            return Ok(result);
        }
        catch (UnauthorizedAccessException ex)
        {
            // Tài khoản bị khóa
            return Unauthorized(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Đăng ký tài khoản mới - Backend tự động hash password.
    /// Public API: không cần token.
    /// Gọi Stored Procedure: sp_Auth_Register.
    /// </summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth")]   // 5 req / phút / IP — chặn tạo tài khoản hàng loạt
    [HttpPost("register")]
    public async Task<ActionResult> Register(
        [FromBody] AuthRegisterRequest request)
    {
        // Hash password trước khi gọi service
        var passwordHash = HashPassword(request.Password);
        
        var registerRequest = new AuthRegisterRequest(
            request.FullName,
            request.Email,
            passwordHash,
            request.PhoneNumber
        );

        var id = await _auth.RegisterAsync(registerRequest);

        if (id is null)
            return BadRequest(new { message = "Đăng ký thất bại. Email có thể đã tồn tại hoặc dữ liệu không hợp lệ." });

        return Ok(new
        {
            message = "Đăng ký thành công",
            newUserId = id
        });
    }

    /// <summary>
    /// Đăng nhập bằng email + password - Backend tự động hash password.
    /// Public API: không cần token.
    /// Gọi Stored Procedure: sp_Auth_LoginLocal.
    /// </summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth")]   // 5 req / phút / IP — chặn brute force mật khẩu
    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(
        [FromBody] AuthLoginRequest request)
    {
        try
        {
            // Hash password trước khi gọi service
            var passwordHash = HashPassword(request.Password);
            
            var loginRequest = new AuthLoginRequest(
                request.Email,
                passwordHash
            );

            var result = await _auth.LoginAsync(loginRequest);

            if (result is null)
                return Unauthorized(new { message = "Email hoặc mật khẩu không chính xác" });

            return Ok(result);
        }
        catch (UnauthorizedAccessException ex)
        {
            // Tài khoản bị khóa
            return Unauthorized(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Đổi mật khẩu.
    /// Protected API: yêu cầu đăng nhập bằng JWT token.
    /// Gọi Stored Procedure: sp_Auth_ChangePassword.
    /// </summary>
    [Authorize]
    [EnableRateLimiting("auth")]   // 5 req / phút / IP — chặn thử mật khẩu hàng loạt
    [HttpPost("change-password")]
    public async Task<ActionResult> ChangePassword(
        [FromBody] ChangePasswordRequest request)
    {
        var id = await _auth.ChangePasswordAsync(request);

        if (id is null)
        {
            return BadRequest(new
            {
                message = "Mật khẩu cũ không chính xác hoặc tài khoản không hợp lệ."
            });
        }

        return Ok(new
        {
            message = "Đổi mật khẩu thành công.",
            updatedUserId = id
        });
    }

    /// <summary>
    /// Lấy thông tin user hiện tại từ JWT token.
    /// Protected API: yêu cầu đăng nhập.
    /// Không cần query database.
    /// </summary>
    [Authorize]
    [HttpGet("me")]
    public ActionResult GetMe()
    {
        var userId = User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
                  ?? User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        var email = User.FindFirst(JwtRegisteredClaimNames.Email)?.Value
                 ?? User.FindFirst(ClaimTypes.Email)?.Value;

        var role = User.FindFirst(ClaimTypes.Role)?.Value;

        var fullName = User.FindFirst(ClaimTypes.Name)?.Value;

        return Ok(new
        {
            userId,
            fullName,
            email,
            role
        });
    }

    /// <summary>
    /// Kiểm tra email đã tồn tại chưa.
    /// Public API: dùng khi đăng ký real-time.
    /// Gọi Stored Procedure: sp_Auth_CheckEmail.
    /// </summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth-check")]  // 20 req / phút / IP
    [HttpGet("check-email/{email}")]
    public async Task<ActionResult> CheckEmail(string email)
    {
        var exists = await _auth.CheckEmailAsync(email);

        return Ok(new
        {
            email,
            exists
        });
    }

    /// <summary>
    /// Quên mật khẩu - Gửi email chứa link reset.
    /// Public API: không cần token.
    /// Gọi Stored Procedure: sp_Auth_ForgotPassword.
    /// </summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth")]  // 5 req / phút / IP — chặn spam
    [HttpPost("forgot-password")]
    public async Task<ActionResult<ForgotPasswordResponse>> ForgotPassword(
        [FromBody] ForgotPasswordRequest request)
    {
        var result = await _auth.ForgotPasswordAsync(request);
        return Ok(result);
    }

    /// <summary>
    /// Reset mật khẩu bằng token.
    /// Public API: không cần JWT token (dùng reset token).
    /// Gọi Stored Procedure: sp_Auth_ResetPassword.
    /// </summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth")]  // 5 req / phút / IP
    [HttpPost("reset-password")]
    public async Task<ActionResult> ResetPassword(
        [FromBody] ResetPasswordRequest request)
    {
        var userId = await _auth.ResetPasswordAsync(request);

        if (userId is null)
        {
            return BadRequest(new
            {
                message = "Token không hợp lệ, đã hết hạn hoặc đã được sử dụng."
            });
        }

        return Ok(new
        {
            message = "Đặt lại mật khẩu thành công. Bạn có thể đăng nhập ngay bây giờ.",
            updatedUserId = userId
        });
    }

    /// <summary>
    /// Verify reset token có hợp lệ không.
    /// Public API: dùng để kiểm tra token trước khi hiển thị form reset password.
    /// Gọi Stored Procedure: sp_Auth_VerifyResetToken.
    /// </summary>
    [AllowAnonymous]
    [HttpGet("verify-reset-token")]
    public async Task<ActionResult<VerifyResetTokenResponse>> VerifyResetToken(
        [FromQuery] string token)
    {
        var result = await _auth.VerifyResetTokenAsync(new VerifyResetTokenRequest(token));
        return Ok(result);
    }

    // ============================================================
    // REFRESH TOKEN ENDPOINTS
    // ============================================================

    /// <summary>
    /// Refresh Access Token bằng Refresh Token.
    /// Public API: không cần JWT token (dùng refresh token).
    /// Gọi Stored Procedure: sp_Auth_VerifyRefreshToken, sp_Auth_CreateRefreshToken, sp_Auth_RevokeRefreshToken.
    /// </summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth")]  // 5 req / phút / IP
    [HttpPost("refresh-token")]
    public async Task<ActionResult<RefreshTokenResponse>> RefreshToken(
        [FromBody] RefreshTokenRequest request)
    {
        // Lấy device info từ User-Agent header
        var deviceInfo = Request.Headers["User-Agent"].ToString();
        
        var result = await _auth.RefreshTokenAsync(request, deviceInfo);

        if (result is null)
        {
            return Unauthorized(new
            {
                message = "Refresh token không hợp lệ, đã hết hạn hoặc đã bị thu hồi."
            });
        }

        return Ok(result);
    }

    /// <summary>
    /// Revoke Refresh Token (đăng xuất).
    /// Public API: không cần JWT token.
    /// Gọi Stored Procedure: sp_Auth_RevokeRefreshToken.
    /// </summary>
    [AllowAnonymous]
    [EnableRateLimiting("auth")]  // 5 req / phút / IP
    [HttpPost("revoke-token")]
    public async Task<ActionResult> RevokeToken(
        [FromBody] RevokeTokenRequest request)
    {
        var result = await _auth.RevokeTokenAsync(request);

        if (!result)
        {
            return BadRequest(new
            {
                message = "Không thể thu hồi token. Token có thể không tồn tại hoặc đã bị thu hồi trước đó."
            });
        }

        return Ok(new
        {
            message = "Đăng xuất thành công. Token đã được thu hồi."
        });
    }
}
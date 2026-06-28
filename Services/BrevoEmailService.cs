using System.Net;
using System.Net.Mail;
using Microsoft.AspNetCore.Http;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

/// <summary>
/// Email service sử dụng SMTP linh hoạt (hỗ trợ Brevo, Gmail, Outlook...)
/// Tự động lấy URL hiện tại (bao gồm ngrok, localhost, custom domain) từ HttpContext
/// </summary>
public sealed class BrevoEmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<BrevoEmailService> _logger;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public BrevoEmailService(
        IConfiguration config,
        ILogger<BrevoEmailService> logger,
        IHttpContextAccessor httpContextAccessor)
    {
        _config = config;
        _logger = logger;
        _httpContextAccessor = httpContextAccessor;
    }

    /// <summary>
    /// Lấy cấu hình SMTP từ Smtp hoặc fallback về Brevo
    /// </summary>
    private (string Server, int Port, bool EnableSsl, string User, string Password, string SenderEmail, string SenderName) GetSmtpConfig()
    {
        // 1. Đọc từ cấu hình chung Smtp
        var smtpServer = _config["Smtp:Server"] ?? "smtp-relay.brevo.com";
        
        var smtpPortVal = _config["Smtp:Port"];
        int smtpPort = string.IsNullOrEmpty(smtpPortVal) ? 587 : int.Parse(smtpPortVal);
        
        var enableSslVal = _config["Smtp:EnableSsl"];
        bool enableSsl = string.IsNullOrEmpty(enableSslVal) ? true : bool.Parse(enableSslVal);

        // Fallback user/pass/email từ Brevo nếu Smtp không khai báo
        var smtpUser = _config["Smtp:Username"] ?? _config["Brevo:SmtpUser"] ?? "";
        var smtpPassword = _config["Smtp:Password"] ?? _config["Brevo:SmtpPassword"] ?? "";
        var senderEmail = _config["Smtp:SenderEmail"] ?? _config["Brevo:SenderEmail"] ?? "noreply@pcstore.com";
        var senderName = _config["Smtp:SenderName"] ?? _config["Brevo:SenderName"] ?? "PC Store";

        return (smtpServer, smtpPort, enableSsl, smtpUser, smtpPassword, senderEmail, senderName);
    }

    /// <summary>
    /// Lấy base URL động của ứng dụng từ HTTP Request hiện tại
    /// </summary>
    private string GetDynamicBaseUrl()
    {
        try
        {
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext != null)
            {
                var request = httpContext.Request;
                // Ví dụ: https://ronny-chymic-sunnily.ngrok-free.dev hoặc http://localhost:5187
                var baseUrl = $"{request.Scheme}://{request.Host}";
                _logger.LogInformation("🔗 Detected dynamic host URL from request context: {BaseUrl}", baseUrl);
                return baseUrl;
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to get request host dynamically, falling back to configuration");
        }

        // Fallback về config
        return _config["Brevo:FrontendUrl"] ?? _config["Smtp:FrontendUrl"] ?? "https://localhost:7115";
    }

    public async Task<bool> SendPasswordResetEmailAsync(string toEmail, string toName, string resetToken)
    {
        try
        {
            var (server, port, enableSsl, smtpUser, smtpPassword, senderEmail, senderName) = GetSmtpConfig();
            var baseUrl = GetDynamicBaseUrl();

            if (string.IsNullOrWhiteSpace(smtpUser) || string.IsNullOrWhiteSpace(smtpPassword))
            {
                _logger.LogError("SMTP Credentials (Smtp:Username/Password hoặc Brevo:SmtpUser/Password) chưa được cấu hình!");
                return false;
            }

            // Tạo link reset password động
            var resetLink = $"{baseUrl}/reset-password?token={resetToken}";
            _logger.LogInformation("👉 Generated password reset link: {ResetLink}", resetLink);

            // Tạo HTML email
            var htmlContent = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset=""UTF-8"">
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: #111827; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }}
        .content {{ background: #f9f9f9; padding: 30px; border: 1px solid #e5e7eb; border-radius: 0 0 8px 8px; margin-top: 0; }}
        .button {{ display: inline-block; padding: 12px 30px; background: #0284c7; color: white; text-decoration: none; border-radius: 8px; margin: 20px 0; font-weight: bold; }}
        .footer {{ text-align: center; margin-top: 30px; font-size: 12px; color: #666; }}
        .warning {{ background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 4px; }}
    </style>
</head>
<body>
    <div class=""container"">
        <div class=""header"">
            <h1>🔐 Đặt Lại Mật Khẩu</h1>
        </div>
        <div class=""content"">
            <p>Xin chào <strong>{toName}</strong>,</p>
            <p>Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản của bạn tại <strong>PC Store</strong>.</p>
            <p>Nhấn vào nút bên dưới để đặt lại mật khẩu:</p>
            <div style=""text-align: center;"">
                <a href=""{resetLink}"" class=""button"" style=""color: #ffffff;"">Đặt Lại Mật Khẩu</a>
            </div>
            <p>Hoặc copy link sau vào trình duyệt:</p>
            <p style=""background: #f0f0f0; padding: 10px; word-break: break-all; font-size: 12px; border-radius: 4px;"">{resetLink}</p>
            <div class=""warning"">
                <strong>⚠️ Lưu ý quan trọng:</strong>
                <ul>
                    <li>Link này chỉ có hiệu lực trong <strong>15 phút</strong></li>
                    <li>Link chỉ sử dụng được <strong>1 lần</strong></li>
                    <li>Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này</li>
                </ul>
            </div>
        </div>
        <div class=""footer"">
            <p>© 2024 PC Store. All rights reserved.</p>
            <p>Email này được gửi tự động, vui lòng không trả lời.</p>
        </div>
    </div>
</body>
</html>";

            // Tạo email message
            using var message = new MailMessage();
            message.From = new MailAddress(senderEmail, senderName);
            message.To.Add(new MailAddress(toEmail, toName));
            message.Subject = "🔐 Đặt Lại Mật Khẩu - PC Store";
            message.Body = htmlContent;
            message.IsBodyHtml = true;
            message.Priority = MailPriority.High;

            // Cấu hình SMTP client
            using var smtpClient = new SmtpClient(server, port);
            smtpClient.Credentials = new NetworkCredential(smtpUser, smtpPassword);
            smtpClient.EnableSsl = enableSsl;
            smtpClient.DeliveryMethod = SmtpDeliveryMethod.Network;
            smtpClient.Timeout = 30000; // 30 seconds

            _logger.LogInformation("🔌 Attempting to send email via SMTP server: {Server}:{Port} (SSL: {SSL}) using sender: {Sender}", server, port, enableSsl, senderEmail);

            // Gửi email
            await smtpClient.SendMailAsync(message);

            _logger.LogInformation("✅ Đã gửi email reset password đến {Email} thành công qua SMTP", toEmail);
            return true;
        }
        catch (SmtpException ex)
        {
            _logger.LogError(ex, "❌ SMTP Error khi gửi email đến {Email}: {Message}", toEmail, ex.Message);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Exception khi gửi email reset password đến {Email}: {Message}", toEmail, ex.Message);
            return false;
        }
    }

    public async Task<bool> SendPasswordResetConfirmationAsync(string toEmail, string toName)
    {
        try
        {
            var (server, port, enableSsl, smtpUser, smtpPassword, senderEmail, senderName) = GetSmtpConfig();

            if (string.IsNullOrWhiteSpace(smtpUser) || string.IsNullOrWhiteSpace(smtpPassword))
            {
                _logger.LogError("SMTP Credentials (Smtp:Username/Password hoặc Brevo:SmtpUser/Password) chưa được cấu hình!");
                return false;
            }

            var htmlContent = $@"
<!DOCTYPE html>
<html>
<head>
    <meta charset=""UTF-8"">
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: #111827; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }}
        .content {{ background: #f9f9f9; padding: 30px; border: 1px solid #e5e7eb; border-radius: 0 0 8px 8px; margin-top: 0; }}
        .success {{ background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 20px 0; border-radius: 4px; }}
        .footer {{ text-align: center; margin-top: 30px; font-size: 12px; color: #666; }}
    </style>
</head>
<body>
    <div class=""container"">
        <div class=""header"">
            <h1>✅ Mật Khẩu Đã Được Đặt Lại</h1>
        </div>
        <div class=""content"">
            <p>Xin chào <strong>{toName}</strong>,</p>
            <div class=""success"">
                <p><strong>✅ Thành công!</strong></p>
                <p>Mật khẩu của bạn đã được đặt lại thành công.</p>
            </div>
            <p>Bạn có thể đăng nhập ngay bây giờ với mật khẩu mới.</p>
            <p><strong>⚠️ Lưu ý bảo mật:</strong></p>
            <ul>
                <li>Nếu bạn không thực hiện thay đổi này, vui lòng liên hệ với chúng tôi ngay lập tức</li>
                <li>Không chia sẻ mật khẩu với bất kỳ ai</li>
                <li>Sử dụng mật khẩu mạnh và duy nhất cho tài khoản này</li>
            </ul>
        </div>
        <div class=""footer"">
            <p>© 2024 PC Store. All rights reserved.</p>
            <p>Email này được gửi tự động, vui lòng không trả lời.</p>
        </div>
    </div>
</body>
</html>";

            // Tạo email message
            using var message = new MailMessage();
            message.From = new MailAddress(senderEmail, senderName);
            message.To.Add(new MailAddress(toEmail, toName));
            message.Subject = "✅ Mật Khẩu Đã Được Đặt Lại - PC Store";
            message.Body = htmlContent;
            message.IsBodyHtml = true;
            message.Priority = MailPriority.Normal;

            // Cấu hình SMTP client
            using var smtpClient = new SmtpClient(server, port);
            smtpClient.Credentials = new NetworkCredential(smtpUser, smtpPassword);
            smtpClient.EnableSsl = enableSsl;
            smtpClient.DeliveryMethod = SmtpDeliveryMethod.Network;
            smtpClient.Timeout = 30000; // 30 seconds

            // Gửi email
            await smtpClient.SendMailAsync(message);

            _logger.LogInformation("✅ Đã gửi email xác nhận reset password đến {Email} thành công qua SMTP", toEmail);
            return true;
        }
        catch (SmtpException ex)
        {
            _logger.LogError(ex, "❌ SMTP Error khi gửi email xác nhận đến {Email}: {Message}", toEmail, ex.Message);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Exception khi gửi email xác nhận đến {Email}: {Message}", toEmail, ex.Message);
            return false;
        }
    }
}

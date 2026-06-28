namespace PC_Store.Services.Interfaces;

public interface IEmailService
{
    /// <summary>
    /// Gửi email reset password
    /// </summary>
    Task<bool> SendPasswordResetEmailAsync(string toEmail, string toName, string resetToken);

    /// <summary>
    /// Gửi email xác nhận reset password thành công
    /// </summary>
    Task<bool> SendPasswordResetConfirmationAsync(string toEmail, string toName);
}

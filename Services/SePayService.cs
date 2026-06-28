using PC_Store.Services.Interfaces;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace PC_Store.Services;

public class SePayService : ISePayService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SePayService> _logger;

    private string MerchantId => _configuration["SePay:MerchantId"] ?? "";
    private string ApiKey => _configuration["SePay:ApiKey"] ?? "";
    private string SecretKey => _configuration["SePay:SecretKey"] ?? "";
    private string ApiUrl => _configuration["SePay:ApiUrl"] ?? "https://api.sepay.vn/api";
    private string ReturnUrl => _configuration["SePay:ReturnUrl"] ?? "";
    
    // Bank account info
    private string AccountName => _configuration["SePay:BankAccount:AccountName"] ?? "HYPER CORE";
    private string AccountNumber => _configuration["SePay:BankAccount:AccountNumber"] ?? "";
    private string BankName => _configuration["SePay:BankAccount:BankName"] ?? "";
    private string BankCode => _configuration["SePay:BankAccount:BankCode"] ?? "VCB";

    public SePayService(HttpClient httpClient, IConfiguration configuration, ILogger<SePayService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// Tạo link thanh toán từ SePay
    /// </summary>
    public async Task<SePayCreatePaymentResponse> CreatePaymentAsync(SePayCreatePaymentRequest request)
    {
        try
        {
            _logger.LogInformation($"[SePay] Creating payment for Order: {request.OrderId}, Amount: {request.Amount}");

            // Generate unique transaction reference
            string transactionRef = $"ORD{request.OrderId}_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}";

            // Prepare request payload
            var payload = new
            {
                merchant_id = MerchantId,
                amount = (long)(request.Amount * 100), // Convert to cents
                order_id = request.OrderId.ToString(),
                order_description = request.OrderDescription ?? $"Order #{request.OrderId}",
                return_url = ReturnUrl,
                webhook_url = _configuration["SePay:NotificationUrl"],
                transaction_uuid = transactionRef,
                bank_code = request.BankCode ?? "all"
            };

            var content = new StringContent(
                JsonSerializer.Serialize(payload),
                Encoding.UTF8,
                "application/json"
            );

            // Add authentication headers
            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {ApiKey}");
            _httpClient.DefaultRequestHeaders.Add("User-Agent", "PC_Store/1.0");

            // Call SePay API
            var response = await _httpClient.PostAsync($"{ApiUrl}/create-payment-link", content);
            var responseBody = await response.Content.ReadAsStringAsync();

            _logger.LogInformation($"[SePay] API Response: {responseBody}");

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"[SePay] Failed to create payment. Status: {response.StatusCode}, Body: {responseBody}");
                return new SePayCreatePaymentResponse
                {
                    Success = false,
                    Message = "Không thể tạo link thanh toán từ SePay",
                    ErrorCode = (int)response.StatusCode
                };
            }

            var result = JsonSerializer.Deserialize<SePayCreatePaymentResponse>(responseBody, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (result?.Data != null)
            {
                result.Data.TransactionRef = transactionRef;
            }

            _logger.LogInformation($"[SePay] Payment created successfully. Ref: {transactionRef}");

            return result ?? new SePayCreatePaymentResponse { Success = false, Message = "Invalid response format" };
        }
        catch (Exception ex)
        {
            _logger.LogError($"[SePay] Exception in CreatePaymentAsync: {ex.Message}", ex);
            return new SePayCreatePaymentResponse
            {
                Success = false,
                Message = $"Lỗi: {ex.Message}"
            };
        }
    }

    /// <summary>
    /// Verify webhook signature từ SePay
    /// </summary>
    public bool VerifyWebhookSignature(string signature, string body)
    {
        try
        {
            _logger.LogInformation("[SePay] Verifying webhook signature");

            if (string.IsNullOrEmpty(signature) || string.IsNullOrEmpty(body))
            {
                _logger.LogWarning("[SePay] Missing signature or body");
                return false;
            }

            // HMAC-SHA256 verification
            using (var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(SecretKey)))
            {
                var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(body));
                var computedSignature = Convert.ToBase64String(hash);

                bool isValid = computedSignature == signature;
                _logger.LogInformation($"[SePay] Signature verification: {(isValid ? "PASSED" : "FAILED")}");

                return isValid;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError($"[SePay] Exception in VerifyWebhookSignature: {ex.Message}", ex);
            return false;
        }
    }

    /// <summary>
    /// Tạo QR code từ thông tin tài khoản ngân hàng
    /// </summary>
    public string GenerateQRCode(decimal amount, string orderDescription = "")
    {
        try
        {
            // VietQR standard: img.vietqr.io
            // Format: https://img.vietqr.io/image/{BANK_CODE}-{ACCOUNT_NUMBER}-{TEMPLATE}.jpg?amount={AMOUNT}&addInfo={CONTENT}
            
            // Bank code for MBBank: 970422
            string bankId = "970422";
            string template = "qr_only"; // Clean QR without bank logo/text
            
            // Content format: HYPERCORE {OrderID}
            string content = orderDescription; // orderDescription đã chứa format HYPERCORE {OrderID}
            
            // Build VietQR URL
            string qrCodeUrl = $"https://img.vietqr.io/image/{bankId}-{AccountNumber}-{template}.jpg?amount={(long)amount}&addInfo={Uri.EscapeDataString(content)}&accountName={Uri.EscapeDataString(AccountName)}";
            
            _logger.LogInformation($"[SePay] VietQR generated: Amount={amount}, Content={content}");
            
            return qrCodeUrl;
        }
        catch (Exception ex)
        {
            _logger.LogError($"[SePay] Error generating QR code: {ex.Message}", ex);
            return "";
        }
    }

    /// <summary>
    /// Lấy thông tin tài khoản ngân hàng cho hiển thị
    /// </summary>
    public (string AccountName, string AccountNumber, string BankName) GetBankAccountInfo()
    {
        return (AccountName, AccountNumber, BankName);
    }

    /// <summary>
    /// Lấy thông tin giao dịch từ SePay
    /// </summary>
    public async Task<SePayTransactionResponse> GetTransactionStatusAsync(string transactionRef)
    {
        try
        {
            _logger.LogInformation($"[SePay] Getting transaction status for: {transactionRef}");

            _httpClient.DefaultRequestHeaders.Clear();
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {ApiKey}");

            var response = await _httpClient.GetAsync($"{ApiUrl}/transaction/{transactionRef}");
            var responseBody = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError($"[SePay] Failed to get transaction status. Status: {response.StatusCode}");
                return new SePayTransactionResponse
                {
                    Success = false,
                    Message = "Không thể lấy trạng thái giao dịch",
                    ErrorCode = (int)response.StatusCode
                };
            }

            var result = JsonSerializer.Deserialize<SePayTransactionResponse>(responseBody, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            return result ?? new SePayTransactionResponse { Success = false };
        }
        catch (Exception ex)
        {
            _logger.LogError($"[SePay] Exception in GetTransactionStatusAsync: {ex.Message}", ex);
            return new SePayTransactionResponse
            {
                Success = false,
                Message = $"Lỗi: {ex.Message}"
            };
        }
    }
}

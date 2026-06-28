namespace PC_Store.Services.Interfaces;

public interface ISePayService
{
    /// <summary>
    /// Tạo link thanh toán từ SePay
    /// </summary>
    Task<SePayCreatePaymentResponse> CreatePaymentAsync(SePayCreatePaymentRequest request);

    /// <summary>
    /// Verify webhook signature từ SePay
    /// </summary>
    bool VerifyWebhookSignature(string signature, string body);

    /// <summary>
    /// Lấy thông tin giao dịch từ SePay
    /// </summary>
    Task<SePayTransactionResponse> GetTransactionStatusAsync(string transactionRef);

    /// <summary>
    /// Tạo QR code từ thông tin tài khoản ngân hàng
    /// </summary>
    string GenerateQRCode(decimal amount, string orderDescription = "");

    /// <summary>
    /// Lấy thông tin tài khoản ngân hàng
    /// </summary>
    (string AccountName, string AccountNumber, string BankName) GetBankAccountInfo();
}

public class SePayCreatePaymentRequest
{
    public int OrderId { get; set; }
    public int UserId { get; set; }
    public decimal Amount { get; set; }
    public string? OrderDescription { get; set; }
    public string? BankCode { get; set; }
}

public class SePayCreatePaymentResponse
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public SePayPaymentData? Data { get; set; }
    public int? ErrorCode { get; set; }
}

public class SePayPaymentData
{
    public string? TransactionRef { get; set; }
    public string? PaymentLink { get; set; }
    public string? QrCode { get; set; }
    public decimal Amount { get; set; }
    public string? Currency { get; set; }
    public string? Description { get; set; }
}

public class SePayTransactionResponse
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public SePayTransactionData? Data { get; set; }
    public int? ErrorCode { get; set; }
}

public class SePayTransactionData
{
    public string? TransactionRef { get; set; }
    public string? Status { get; set; } // pending, success, failed, cancelled
    public decimal Amount { get; set; }
    public string? Currency { get; set; }
    public DateTime? CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class SePayWebhookPayload
{
    public string? TransactionRef { get; set; }
    public string? Status { get; set; }
    public decimal Amount { get; set; }
    public string? Description { get; set; }
    public DateTime? Timestamp { get; set; }
    
    // SePay Transfer Monitoring format
    public string? Gateway { get; set; }
    public string? TransactionDate { get; set; }
    public string? AccountNumber { get; set; }
    public string? Code { get; set; }
    public string? Content { get; set; }
    public decimal? TransferAmount { get; set; }
    public string? ReferenceNumber { get; set; }
    public string? Body { get; set; }
}

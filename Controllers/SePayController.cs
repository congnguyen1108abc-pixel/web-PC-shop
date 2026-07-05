using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PC_Store.DTOs.Common;
using PC_Store.Repositories.Base;
using PC_Store.Services.Interfaces;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace PC_Store.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SePayController : ControllerBase
{
    private readonly ISePayService _sePayService;
    private readonly IDbRepository _db;
    private readonly ILogger<SePayController> _logger;
    private readonly IConfiguration _configuration;

    public SePayController(
        ISePayService sePayService,
        IDbRepository db,
        ILogger<SePayController> logger,
        IConfiguration configuration)
    {
        _sePayService = sePayService;
        _db = db;
        _logger = logger;
        _configuration = configuration;
    }

    /// <summary>
    /// Tạo link thanh toán SePay
    /// </summary>
    [Authorize]
    [HttpPost("create-payment")]
    public async Task<ActionResult<ApiResponse<object>>> CreatePayment([FromBody] SePayCreatePaymentRequest request)
    {
        try
        {
            _logger.LogInformation($"[SePay] Create payment request for Order: {request.OrderId}");

            // Validate request
            if (request.Amount <= 0)
            {
                return BadRequest(ApiResponse<object>.ErrorResponse(
                    "Số tiền phải lớn hơn 0", 400
                ));
            }

            // Tạo QR code từ tài khoản ngân hàng
            string orderDesc = $"HYPERCORE {request.OrderId}";
            string qrCodeUrl = _sePayService.GenerateQRCode(request.Amount, orderDesc);

            // Get bank account info
            var (accountName, accountNumber, bankName) = _sePayService.GetBankAccountInfo();

            // Insert transaction record to database
            try
            {
                await _db.ExecuteAsync("sp_InsertSePayTransaction", new
                {
                    OrderID = request.OrderId,
                    UserID = request.UserId,
                    MerchantID = "BG",
                    TransactionRef = $"ORD{request.OrderId}_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}",
                    Amount = request.Amount,
                    Status = "pending"
                });
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"[SePay] Failed to insert transaction record: {ex.Message}");
            }

            return Ok(ApiResponse<object>.SuccessResponse(
                new
                {
                    qrCodeUrl = qrCodeUrl,
                    accountName = accountName,
                    accountNumber = accountNumber,
                    bankName = bankName,
                    amount = request.Amount,
                    orderDescription = orderDesc
                },
                "Tạo QR code thanh toán thành công", 200
            ));
        }
        catch (Exception ex)
        {
            _logger.LogError($"[SePay] Exception in CreatePayment: {ex.Message}", ex);
            return StatusCode(500, ApiResponse<object>.ErrorResponse(
                $"Lỗi server: {ex.Message}", 500
            ));
        }
    }

    /// <summary>
    /// Webhook endpoint để nhận callback từ SePay
    /// </summary>
    [HttpPost("webhook")]
    [AllowAnonymous] // Cho phép SePay gọi mà không cần authentication
    public async Task<IActionResult> ReceiveWebhook()
    {
        try
        {
            _logger.LogInformation("[SePay] ============ WEBHOOK RECEIVED ============");
            _logger.LogInformation($"[SePay] Request Method: {Request.Method}");
            _logger.LogInformation($"[SePay] Request Path: {Request.Path}");

            // Log tất cả headers để debug
            foreach (var header in Request.Headers)
            {
                _logger.LogInformation($"[SePay] Header: {header.Key} = {header.Value}");
            }

            // SePay gửi API key qua Authorization header dạng: "Apikey {API_KEY}"
            var authHeader = Request.Headers["Authorization"].ToString();
            var sePayApiKey = _configuration["SePay:ApiKey"] ?? "";
            _logger.LogInformation($"[SePay] Auth header received: {authHeader}");

            // Kiểm tra API key nếu có (bỏ qua nếu rỗng để tương thích)
            if (!string.IsNullOrEmpty(authHeader) && !string.IsNullOrEmpty(sePayApiKey))
            {
                // SePay format: "Apikey SKPQVZUQ..."
                var providedKey = authHeader.Replace("Apikey ", "").Replace("Bearer ", "").Trim();
                if (!providedKey.Equals(sePayApiKey, StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogWarning("[SePay] ⚠️ API key mismatch - proceeding anyway (webhook monitoring mode)");
                    // Không reject - SePay Transfer Monitoring có thể dùng key khác
                }
                else
                {
                    _logger.LogInformation("[SePay] ✅ API key verified");
                }
            }

            // Read body
            string body;
            using (var reader = new StreamReader(Request.Body, leaveOpen: true))
            {
                body = await reader.ReadToEndAsync();
                // Reset position nếu stream hỗ trợ
                if (Request.Body.CanSeek) Request.Body.Position = 0;
            }

            _logger.LogInformation($"[SePay] Request Body: {body}");

            if (string.IsNullOrWhiteSpace(body))
            {
                _logger.LogWarning("[SePay] Empty request body received");
                return Ok(new { success = true, message = "Empty body - acknowledged" });
            }

            // Parse JSON
            JsonElement payload;
            try
            {
                payload = JsonSerializer.Deserialize<JsonElement>(body);
            }
            catch (Exception ex)
            {
                _logger.LogError($"[SePay] Failed to parse JSON: {ex.Message}");
                return BadRequest(new { success = false, error = "Invalid JSON format" });
            }

            // Parse webhook data
            var webhookData = JsonSerializer.Deserialize<SePayWebhookPayload>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (webhookData == null)
            {
                _logger.LogError("[SePay] webhookData is null after deserialization");
                return BadRequest(new { success = false, error = "Invalid webhook data" });
            }

            // Xác định format: SePay API hoặc SePay Transfer Monitoring
            bool isTransferMonitoring = !string.IsNullOrEmpty(webhookData.TransferAmount?.ToString()) || 
                                       !string.IsNullOrEmpty(webhookData.Content);
            
            string transactionRef = "";
            string status = "success"; // Mặc định success vì đã nhận được tiền
            decimal amount = 0;
            string description = "";
            
            if (isTransferMonitoring)
            {
                // Format: SePay Transfer Monitoring
                _logger.LogInformation("[SePay] Format: Transfer Monitoring");
                _logger.LogInformation($"  - Content: {webhookData.Content}");
                _logger.LogInformation($"  - Amount: {webhookData.TransferAmount}");
                _logger.LogInformation($"  - Account: {webhookData.AccountNumber}");
                _logger.LogInformation($"  - Gateway: {webhookData.Gateway}");
                
                amount = webhookData.TransferAmount ?? 0;
                description = webhookData.Content ?? "";
                transactionRef = webhookData.ReferenceNumber ?? $"TM{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}";
            }
            else
            {
                // Format: SePay API standard
                _logger.LogInformation("[SePay] Format: Standard API");
                _logger.LogInformation($"  - TransactionRef: {webhookData.TransactionRef}");
                _logger.LogInformation($"  - Status: {webhookData.Status}");
                _logger.LogInformation($"  - Amount: {webhookData.Amount}");
                _logger.LogInformation($"  - Description: {webhookData.Description}");
                
                transactionRef = webhookData.TransactionRef ?? "";
                status = webhookData.Status ?? "success";
                amount = webhookData.Amount;
                description = webhookData.Description ?? "";
            }

            // --- HÀNH ĐỘNG CHUNG: TRÍCH XUẤT MÃ ĐƠN HÀNG VÀ CẬP NHẬT TRẠNG THÁI ---
            var contentUpper = description.ToUpper().Trim();
            _logger.LogInformation($"[SePay] Parsing order ID from description: '{contentUpper}'");

            // Thử nhiều pattern để extract Order ID
            var patterns = new[]
            {
                @"HYPERCORE\s*#?\s*(\d+)",           // HYPERCORE 33, HYPERCORE#33
                @"(?:ORDER|ORD)\s*#?\s*(\d+)",        // ORDER 33, ORD33, ORDER#33
                @"(?:DH|HD|DONHANG|DON\s*HANG)\s*#?\s*(\d+)", // DH33, DON HANG 33
                @"(?:^|\s)(\d{1,6})(?:\s|$)"          // Số cuối cùng trong chuỗi (fallback)
            };

            Match match = Match.Empty;
            foreach (var pattern in patterns)
            {
                match = Regex.Match(contentUpper, pattern);
                if (match.Success)
                {
                    _logger.LogInformation($"[SePay] Matched pattern '{pattern}'");
                    break;
                }
            }

            if (match.Success && int.TryParse(match.Groups[1].Value, out int orderId))
            {
                if (string.IsNullOrEmpty(transactionRef))
                {
                    transactionRef = $"ORD{orderId}_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}";
                }
                _logger.LogInformation($"[SePay] Extracted Order ID: {orderId}");

                // Dùng SP để update - đúng chuẩn kiến trúc của project
                try
                {
                    var updateResult = await _db.QuerySingleAsync<RowsAffectedResult>(
                        "sp_SePay_UpdatePaymentStatus",
                        new
                        {
                            OrderID = orderId,
                            PaymentStatus = "Đã thanh toán",
                            NewStatus = "Chờ xác nhận"
                        }
                    );

                    int rowsAffected = updateResult?.RowsAffected ?? 0;

                    if (rowsAffected > 0)
                        _logger.LogInformation($"[SePay] ✅ Order {orderId} updated to 'Đã thanh toán' ({rowsAffected} row affected)");
                    else
                        _logger.LogWarning($"[SePay] ⚠️ Order {orderId} - no rows updated (already paid or not found)");
                }
                catch (Exception ex)
                {
                    _logger.LogError($"[SePay] ❌ Failed to update Order {orderId}: {ex.Message}");
                }
            }
            else
            {
                _logger.LogWarning($"[SePay] ⚠️ Could not extract Order ID from content: '{description}'");
                if (string.IsNullOrEmpty(transactionRef))
                {
                    transactionRef = $"UNKNOWN_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}";
                }
            }

            // Update transaction status in database
            try
            {
                _logger.LogInformation($"[SePay] Updating transaction: {transactionRef} to status: {status}");
                
                await _db.ExecuteAsync("sp_UpdateSePayTransactionStatus", new
                {
                    TransactionRef = transactionRef,
                    Status = status,
                    ResponseData = body,
                    ErrorMessage = (string?)null
                });
                
                _logger.LogInformation($"[SePay] ✅ Transaction status updated successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError($"[SePay] ❌ Failed to update transaction status: {ex.Message}");
                // Don't fail the webhook if DB update fails
            }

            _logger.LogInformation("[SePay] ============ WEBHOOK PROCESSED ============");
            
            // SePay expects simple response: { "success": true } or plain text "ok"
            return Ok(new { success = true, message = "Webhook processed successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError($"[SePay] ❌ Exception in ReceiveWebhook: {ex.Message}");
            _logger.LogError($"[SePay] Stack Trace: {ex.StackTrace}");
            return StatusCode(500, new { success = false, error = $"Server error: {ex.Message}" });
        }
    }

    /// <summary>
    /// Kiểm tra trạng thái giao dịch
    /// </summary>
    [Authorize]
    [HttpGet("status/{transactionId}")]
    public async Task<ActionResult<ApiResponse<object>>> GetTransactionStatus(string transactionId)
    {
        try
        {
            _logger.LogInformation($"[SePay] Getting transaction status: {transactionId}");

            var status = await _sePayService.GetTransactionStatusAsync(transactionId);

            if (!status.Success)
            {
                return StatusCode(500, ApiResponse<object>.ErrorResponse(
                    status.Message ?? "Không thể lấy trạng thái", 500
                ));
            }

            return Ok(ApiResponse<object>.SuccessResponse(
                status.Data, "Lấy trạng thái thành công", 200
            ));
        }
        catch (Exception ex)
        {
            _logger.LogError($"[SePay] Exception in GetTransactionStatus: {ex.Message}", ex);
            return StatusCode(500, ApiResponse<object>.ErrorResponse(
                $"Lỗi server: {ex.Message}", 500
            ));
        }
    }

    /// <summary>
    /// POLLING ENDPOINT: Frontend gọi mỗi 5 giây để check xem đơn hàng đã được thanh toán chưa
    /// Không cần webhook phải hoạt động - check trực tiếp từ DB
    /// </summary>
    [Authorize]
    [HttpGet("payment-status/{orderId:int}")]
    public async Task<ActionResult> CheckPaymentStatus(int orderId)
    {
        try
        {
            _logger.LogInformation($"[SePay] Checking payment status for Order: {orderId}");

            // Dùng SP - đúng chuẩn kiến trúc của project
            var result = await _db.QuerySingleAsync<PaymentStatusResult>(
                "sp_SePay_GetPaymentStatus",
                new { OrderID = orderId }
            );

            if (result == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy đơn hàng", orderId });
            }

            bool isPaid = result.PaymentStatus == "Đã thanh toán";

            if (!isPaid)
            {
                // Fallback check: Direct real-time check against SePay API (in case webhook is blocked or ngrok is down)
                try
                {
                    var sePayApiKey = _configuration["SePay:ApiKey"];
                    if (!string.IsNullOrEmpty(sePayApiKey))
                    {
                        using (var httpClient = new HttpClient())
                        {
                            httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {sePayApiKey}");
                            
                            var apiResponse = await httpClient.GetAsync("https://api.sepay.vn/api/transactions/list?limit=25");
                            if (apiResponse.IsSuccessStatusCode)
                            {
                                var apiBody = await apiResponse.Content.ReadAsStringAsync();
                                using (var doc = JsonDocument.Parse(apiBody))
                                {
                                    var root = doc.RootElement;
                                    if (root.TryGetProperty("transactions", out var transactionsArr) && transactionsArr.ValueKind == JsonValueKind.Array)
                                    {
                                        foreach (var tx in transactionsArr.EnumerateArray())
                                        {
                                            string content = "";
                                            if (tx.TryGetProperty("transactionContent", out var contentProp1))
                                                content = contentProp1.GetString() ?? "";
                                            else if (tx.TryGetProperty("content", out var contentProp2))
                                                content = contentProp2.GetString() ?? "";

                                            string refNo = "";
                                            if (tx.TryGetProperty("referenceNumber", out var refProp1))
                                                refNo = refProp1.GetString() ?? "";
                                            else if (tx.TryGetProperty("transactionRef", out var refProp2))
                                                refNo = refProp2.GetString() ?? "";
                                            else if (tx.TryGetProperty("id", out var refProp3))
                                                refNo = refProp3.ValueKind == JsonValueKind.Number ? refProp3.GetInt64().ToString() : refProp3.GetString() ?? "";

                                            var targetPattern = $"HYPERCORE {orderId}";
                                            if (content.ToUpper().Contains(targetPattern))
                                            {
                                                _logger.LogInformation($"[SePay API Fallback] Match found! Order {orderId} paid via transaction ref {refNo}. Updating status...");

                                                // Update Order Payment Status
                                                await _db.QuerySingleAsync<RowsAffectedResult>(
                                                    "sp_SePay_UpdatePaymentStatus",
                                                    new
                                                    {
                                                        OrderID = orderId,
                                                        PaymentStatus = "Đã thanh toán",
                                                        NewStatus = "Chờ xác nhận"
                                                    }
                                                );

                                                // Log the transaction update
                                                try
                                                {
                                                    await _db.ExecuteAsync("sp_UpdateSePayTransactionStatus", new
                                                    {
                                                        TransactionRef = refNo,
                                                        Status = "success",
                                                        ResponseData = tx.ToString(),
                                                        ErrorMessage = (string?)null
                                                    });
                                                }
                                                catch { }

                                                isPaid = true;
                                                result.PaymentStatus = "Đã thanh toán";
                                                result.Status = "Chờ xác nhận";
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                catch (Exception apiEx)
                {
                    _logger.LogWarning($"[SePay API Fallback] Failed to check SePay transactions API: {apiEx.Message}");
                }
            }

            _logger.LogInformation($"[SePay] Order {orderId}: PaymentStatus={result.PaymentStatus}, IsPaid={isPaid}");

            return Ok(new
            {
                success = true,
                orderId = orderId,
                paymentStatus = result.PaymentStatus,
                orderStatus = result.Status,
                isPaid = isPaid
            });
        }
        catch (Exception ex)
        {
            _logger.LogError($"[SePay] Exception in CheckPaymentStatus: {ex.Message}", ex);
            return StatusCode(500, new { success = false, message = $"Lỗi server: {ex.Message}" });
        }
    }

    /// <summary>
    /// TEST ENDPOINT: Manually trigger webhook for testing
    /// </summary>
    [HttpPost("test-webhook")]
    [AllowAnonymous]
    public async Task<ActionResult<ApiResponse<object>>> TestWebhook([FromBody] TestWebhookRequest request)
    {
        try
        {
            _logger.LogInformation($"[SePay] TEST WEBHOOK triggered for Order: {request.OrderId}");

            // Dùng cùng SP như real webhook
            var updateResult = await _db.QuerySingleAsync<RowsAffectedResult>(
                "sp_SePay_UpdatePaymentStatus",
                new
                {
                    OrderID = request.OrderId,
                    PaymentStatus = "Đã thanh toán",
                    NewStatus = "Chờ xác nhận"
                }
            );

            int rowsAffected = updateResult?.RowsAffected ?? 0;
            _logger.LogInformation($"[SePay] TEST: Order {request.OrderId} updated ({rowsAffected} rows affected)");

            // Cập nhật SePayTransactions nếu có
            try
            {
                var txRef = $"TEST_ORD{request.OrderId}_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}";
                var webhookBody = JsonSerializer.Serialize(new
                {
                    transactionRef = txRef,
                    status = request.Status ?? "success",
                    amount = request.Amount,
                    description = $"Test payment for Order #{request.OrderId}",
                    timestamp = DateTime.UtcNow
                });

                await _db.ExecuteAsync("sp_UpdateSePayTransactionStatus", new
                {
                    TransactionRef = txRef,
                    Status = request.Status ?? "success",
                    ResponseData = webhookBody,
                    ErrorMessage = (string?)null
                });
            }
            catch { /* Bỏ qua nếu không có transaction record */ }

            _logger.LogInformation($"[SePay] ✅ Test webhook fully processed for Order: {request.OrderId}");

            return Ok(ApiResponse<object>.SuccessResponse(
                new { orderId = request.OrderId, status = request.Status, rowsUpdated = rowsAffected },
                "Test webhook processed - Order PaymentStatus updated",
                200
            ));
        }
        catch (Exception ex)
        {
            _logger.LogError($"[SePay] Exception in TestWebhook: {ex.Message}", ex);
            return StatusCode(500, ApiResponse<object>.ErrorResponse($"Lỗi: {ex.Message}", 500));
        }
    }
}

public class TestWebhookRequest
{
    public int OrderId { get; set; }
    public decimal Amount { get; set; }
    public string? Status { get; set; } = "success";
}

public class PaymentStatusResult
{
    public int OrderID { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime? UpdatedAt { get; set; }
}

/// <summary>Nhận kết quả @@ROWCOUNT từ SP</summary>
public class RowsAffectedResult
{
    public int RowsAffected { get; set; }
}

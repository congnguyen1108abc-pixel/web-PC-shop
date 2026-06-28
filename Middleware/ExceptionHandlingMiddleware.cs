using Microsoft.Data.SqlClient;
using System.Net;
using System.Text.Json;

namespace PC_Store.Middleware;

/// <summary>
/// Middleware xử lý lỗi tập trung toàn bộ ứng dụng.
/// Bắt SqlException (từ RAISERROR trong Stored Procedure) và các exception khác,
/// trả về JSON chuẩn thay vì HTTP 500 xấu với stack trace lộ thông tin hệ thống.
/// </summary>
public sealed class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }

        // ── SqlException: RAISERROR từ Stored Procedure ──────────────────────
        // Severity 16 (lỗi nghiệp vụ) sẽ bị bắt ở đây.
        // Ví dụ: "Email đã tồn tại", "SKU đã tồn tại", "Giỏ hàng trống", v.v.
        catch (SqlException sqlEx)
        {
            _logger.LogWarning(
                "SQL Exception [{Number}] tại {Path}: {Message}",
                sqlEx.Number, context.Request.Path, sqlEx.Message);

            // Severity 16 = lỗi nghiệp vụ từ RAISERROR → 400 Bad Request
            // Severity cao hơn (mất kết nối, deadlock...) → 503
            var statusCode = sqlEx.Class >= 20
                ? HttpStatusCode.ServiceUnavailable
                : HttpStatusCode.BadRequest;

            await WriteJsonAsync(context, statusCode, sqlEx.Message);
        }

        // ── Lỗi JWT / xác thực ───────────────────────────────────────────────
        catch (UnauthorizedAccessException uaEx)
        {
            _logger.LogWarning("Unauthorized tại {Path}: {Message}",
                context.Request.Path, uaEx.Message);

            await WriteJsonAsync(context, HttpStatusCode.Unauthorized,
                "Bạn không có quyền thực hiện thao tác này.");
        }

        // ── Argument / format lỗi (data từ client không đúng kiểu) ───────────
        catch (ArgumentException argEx)
        {
            _logger.LogWarning("ArgumentException tại {Path}: {Message}",
                context.Request.Path, argEx.Message);

            await WriteJsonAsync(context, HttpStatusCode.BadRequest, argEx.Message);
        }

        // ── Lỗi cấu hình hệ thống (Jwt:Key chưa set, connection string rỗng) ─
        catch (InvalidOperationException ioEx)
        {
            _logger.LogError(ioEx, "InvalidOperation tại {Path}: {Message}",
                context.Request.Path, ioEx.Message);

            await WriteJsonAsync(context, HttpStatusCode.InternalServerError,
                "Lỗi cấu hình hệ thống. Vui lòng liên hệ quản trị viên.");
        }

        // ── Mọi lỗi không xác định khác ──────────────────────────────────────
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled Exception tại {Path}: {Message}",
                context.Request.Path, ex.Message);

            await WriteJsonAsync(context, HttpStatusCode.InternalServerError,
                "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.");
        }
    }

    // ── Helper: ghi JSON response chuẩn ──────────────────────────────────────

    private static readonly JsonSerializerOptions _jsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        WriteIndented = false
    };

    private static async Task WriteJsonAsync(
        HttpContext context,
        HttpStatusCode statusCode,
        string message)
    {
        // Tránh ghi đè nếu response đã bắt đầu stream
        if (context.Response.HasStarted)
            return;

        context.Response.StatusCode  = (int)statusCode;
        context.Response.ContentType = "application/json; charset=utf-8";

        var payload = new ErrorResponse(
            Success:    false,
            StatusCode: (int)statusCode,
            Message:    message
        );

        await context.Response.WriteAsync(
            JsonSerializer.Serialize(payload, _jsonOptions)
        );
    }

    // ── DTO nội bộ cho response lỗi ──────────────────────────────────────────

    private sealed record ErrorResponse(
        bool   Success,
        int    StatusCode,
        string Message);
}

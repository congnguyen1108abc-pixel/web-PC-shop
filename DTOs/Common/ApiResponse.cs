namespace PC_Store.DTOs.Common;

/// <summary>
/// Chuẩn hóa response cho toàn bộ API
/// </summary>
/// <typeparam name="T">Kiểu dữ liệu trả về</typeparam>
public sealed record ApiResponse<T>
{
    /// <summary>Trạng thái thành công hay thất bại</summary>
    public bool Success { get; init; }

    /// <summary>HTTP Status Code</summary>
    public int StatusCode { get; init; }

    /// <summary>Thông báo cho người dùng</summary>
    public string? Message { get; init; }

    /// <summary>Dữ liệu trả về</summary>
    public T? Data { get; init; }

    /// <summary>Chi tiết lỗi (nếu có)</summary>
    public object? Errors { get; init; }

    /// <summary>
    /// Tạo response thành công
    /// </summary>
    public static ApiResponse<T> SuccessResponse(T data, string? message = null, int statusCode = 200)
    {
        return new ApiResponse<T>
        {
            Success = true,
            StatusCode = statusCode,
            Message = message,
            Data = data
        };
    }

    /// <summary>
    /// Tạo response lỗi
    /// </summary>
    public static ApiResponse<T> ErrorResponse(string message, int statusCode = 400, object? errors = null)
    {
        return new ApiResponse<T>
        {
            Success = false,
            StatusCode = statusCode,
            Message = message,
            Errors = errors
        };
    }
}

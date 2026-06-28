using System.Data;
using Microsoft.Data.SqlClient;

namespace PC_Store.Helpers;

/// <summary>
/// Helper class cung cấp các phương thức tiện ích để tạo và quản lý kết nối SQL Server.
/// Thay thế logic tạo connection bằng reflection trong Program.cs bằng cách gọi trực tiếp SqlConnection.
/// </summary>
public static class DbHelper
{
    /// <summary>
    /// Tạo một <see cref="IDbConnection"/> kết nối tới SQL Server từ connection string.
    /// Connection được trả về ở trạng thái chưa mở (Closed) — Dapper sẽ tự mở/đóng khi cần.
    /// </summary>
    /// <param name="connectionString">Connection string lấy từ appsettings.json.</param>
    /// <returns>Instance của <see cref="SqlConnection"/> implement <see cref="IDbConnection"/>.</returns>
    /// <exception cref="ArgumentNullException">Ném khi connection string rỗng hoặc null.</exception>
    public static IDbConnection CreateConnection(string? connectionString)
    {
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new ArgumentNullException(nameof(connectionString),
                "Connection string 'DefaultConnection' không được để trống. Kiểm tra appsettings.json.");
        }

        return new SqlConnection(connectionString);
    }

    /// <summary>
    /// Tạo và mở ngay một <see cref="SqlConnection"/> — dùng khi cần thao tác thủ công với connection.
    /// Nhớ <c>await using</c> hoặc <c>Dispose()</c> sau khi dùng xong.
    /// </summary>
    /// <param name="connectionString">Connection string lấy từ appsettings.json.</param>
    /// <returns>SqlConnection đã ở trạng thái Open.</returns>
    public static async Task<SqlConnection> CreateOpenConnectionAsync(string? connectionString)
    {
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new ArgumentNullException(nameof(connectionString),
                "Connection string 'DefaultConnection' không được để trống. Kiểm tra appsettings.json.");
        }

        var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();
        return connection;
    }

    /// <summary>
    /// Kiểm tra kết nối tới SQL Server có hoạt động không.
    /// Dùng để health-check khi khởi động ứng dụng.
    /// </summary>
    /// <param name="connectionString">Connection string cần kiểm tra.</param>
    /// <returns><c>true</c> nếu kết nối thành công, <c>false</c> nếu thất bại.</returns>
    public static async Task<bool> TestConnectionAsync(string? connectionString)
    {
        try
        {
            await using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();
            return connection.State == ConnectionState.Open;
        }
        catch
        {
            return false;
        }
    }
}

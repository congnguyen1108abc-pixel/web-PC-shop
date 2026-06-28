using Dapper;

namespace PC_Store.Helpers;

/// <summary>
/// Helper xây dựng <see cref="DynamicParameters"/> cho Dapper,
/// tự động chuyển đổi giá trị <c>null</c> của C# thành <c>DBNull.Value</c>
/// để SQL Server Stored Procedure nhận đúng tham số NULL thay vì bị lỗi.
/// </summary>
/// <remarks>
/// Vấn đề: Khi truyền anonymous object { Keyword = (string?)null } vào Dapper,
/// một số trường hợp SQL Server không nhận được NULL đúng cách dẫn đến lỗi
/// hoặc stored procedure không lọc đúng.
/// Giải pháp: Dùng <see cref="DynamicParameters"/> và luôn map null → DBNull.Value.
/// </remarks>
public static class SqlParameterHelper
{
    /// <summary>
    /// Tạo <see cref="DynamicParameters"/> từ danh sách tham số tên-giá trị,
    /// tự động chuyển <c>null</c> → <c>DBNull.Value</c>.
    /// </summary>
    /// <param name="parameters">Danh sách cặp (tên tham số, giá trị).</param>
    /// <returns><see cref="DynamicParameters"/> sẵn sàng truyền vào Dapper.</returns>
    /// <example>
    /// <code>
    /// var p = SqlParameterHelper.Create(
    ///     ("UserId",  request.UserId),
    ///     ("Keyword", request.Keyword),   // null → DBNull.Value tự động
    ///     ("DateFrom", request.DateFrom)  // null → DBNull.Value tự động
    /// );
    /// await _repository.QueryAsync&lt;MyItem&gt;("sp_MyProc", p);
    /// </code>
    /// </example>
    public static DynamicParameters Create(params (string Name, object? Value)[] parameters)
    {
        var dp = new DynamicParameters();

        foreach (var (name, value) in parameters)
        {
            dp.Add(name, value ?? DBNull.Value);
        }

        return dp;
    }

    /// <summary>
    /// Tạo <see cref="DynamicParameters"/> từ một anonymous object,
    /// tự động duyệt qua tất cả các property và chuyển <c>null</c> → <c>DBNull.Value</c>.
    /// </summary>
    /// <param name="obj">Anonymous object chứa các tham số, ví dụ: <c>new { UserId = 1, Keyword = (string?)null }</c>.</param>
    /// <returns><see cref="DynamicParameters"/> sẵn sàng truyền vào Dapper.</returns>
    /// <example>
    /// <code>
    /// var p = SqlParameterHelper.FromObject(new
    /// {
    ///     request.UserId,
    ///     request.Keyword,    // null → DBNull.Value tự động
    ///     request.DateFrom    // null → DBNull.Value tự động
    /// });
    /// await _repository.QueryAsync&lt;MyItem&gt;("sp_MyProc", p);
    /// </code>
    /// </example>
    public static DynamicParameters FromObject(object obj)
    {
        var dp = new DynamicParameters();

        if (obj is null)
        {
            return dp;
        }

        foreach (var prop in obj.GetType().GetProperties())
        {
            var value = prop.GetValue(obj);
            dp.Add(prop.Name, value ?? DBNull.Value);
        }

        return dp;
    }

    /// <summary>
    /// Extension method trên <see cref="DynamicParameters"/> để thêm một tham số
    /// và tự động chuyển <c>null</c> → <c>DBNull.Value</c>, hỗ trợ fluent chaining.
    /// </summary>
    /// <param name="dp">Đối tượng DynamicParameters hiện tại.</param>
    /// <param name="name">Tên tham số SQL.</param>
    /// <param name="value">Giá trị tham số (có thể null).</param>
    /// <returns>Chính <see cref="DynamicParameters"/> để chain tiếp.</returns>
    /// <example>
    /// <code>
    /// var p = new DynamicParameters()
    ///     .AddNullSafe("UserId", request.UserId)
    ///     .AddNullSafe("Status", request.Status)   // null → DBNull.Value
    ///     .AddNullSafe("DateFrom", request.DateFrom); // null → DBNull.Value
    /// </code>
    /// </example>
    public static DynamicParameters AddNullSafe(this DynamicParameters dp, string name, object? value)
    {
        dp.Add(name, value ?? DBNull.Value);
        return dp;
    }
}

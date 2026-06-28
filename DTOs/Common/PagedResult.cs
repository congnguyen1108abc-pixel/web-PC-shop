namespace PC_Store.DTOs.Common;

/// <summary>
/// Generic wrapper cho kết quả phân trang
/// </summary>
/// <typeparam name="T">Kiểu dữ liệu của items trong danh sách</typeparam>
public sealed record PagedResult<T>
{
    /// <summary>Danh sách items trong trang hiện tại</summary>
    public IEnumerable<T> Items { get; init; } = [];

    /// <summary>Tổng số bản ghi trong database (không phân trang)</summary>
    public int TotalRecords { get; init; }

    /// <summary>Số trang hiện tại (bắt đầu từ 1)</summary>
    public int PageNumber { get; init; }

    /// <summary>Số bản ghi mỗi trang</summary>
    public int PageSize { get; init; }

    /// <summary>Tổng số trang</summary>
    public int TotalPages { get; init; }

    /// <summary>Có trang trước không</summary>
    public bool HasPreviousPage => PageNumber > 1;

    /// <summary>Có trang sau không</summary>
    public bool HasNextPage => PageNumber < TotalPages;

    /// <summary>
    /// Constructor tính toán tự động TotalPages
    /// </summary>
    public PagedResult(IEnumerable<T> items, int totalRecords, int pageNumber, int pageSize)
    {
        Items = items;
        TotalRecords = totalRecords;
        PageNumber = pageNumber;
        PageSize = pageSize;
        TotalPages = pageSize > 0 ? (int)Math.Ceiling(totalRecords / (double)pageSize) : 0;
    }

    /// <summary>
    /// Constructor mặc định (dùng cho init syntax)
    /// </summary>
    public PagedResult() { }
}

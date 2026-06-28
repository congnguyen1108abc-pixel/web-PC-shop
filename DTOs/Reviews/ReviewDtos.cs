namespace PC_Store.DTOs.Reviews;

public sealed record AdminReviewQueryRequest(
    int? ProductId,
    bool? IsApproved,
    string? Keyword,
    int PageNumber = 1,
    int PageSize = 10)
{
    /// <summary>Validate và normalize pagination parameters</summary>
    public AdminReviewQueryRequest Normalize()
    {
        var pageNum = PageNumber < 1 ? 1 : PageNumber;
        var pageSize = PageSize < 1 ? 10 : (PageSize > 100 ? 100 : PageSize);
        
        return this with { PageNumber = pageNum, PageSize = pageSize };
    }
};

public sealed record AdminReviewItem(
    int ReviewId,
    int ProductId,
    string ProductName,
    string SKU,
    int UserId,
    string FullName,
    int Rating,
    string? Comment,
    string? ImageUrl,
    bool IsApproved,
    DateTime CreatedAt);

public sealed record DeleteReviewRequest(int ReviewId);

// Customer: gửi đánh giá sản phẩm (chỉ khi đã mua và nhận hàng)
public sealed record AddReviewRequest(
    int UserId,
    int ProductId,
    int Rating,
    string? Comment,
    string? ImageUrl);

// Item trả về khi khách xem reviews của 1 sản phẩm
public sealed record CustomerReviewItem(
    int ReviewId,
    int ProductId,
    int UserId,
    string? FullName,
    string? AvatarUrl,
    int Rating,
    string? Comment,
    string? ImageUrl,
    DateTime CreatedAt);

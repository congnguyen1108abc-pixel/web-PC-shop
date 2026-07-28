using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Reviews;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class ReviewRepository : IReviewRepository
{
    private readonly IDbRepository _db;
    public ReviewRepository(IDbRepository db) => _db = db;

    public async Task<PagedResult<AdminReviewItem>> GetAdminReviewsAsync(AdminReviewQueryRequest request)
    {
        var normalized = request.Normalize();
        
        var items = await _db.QueryAsync<AdminReviewItemWithTotal>("sp_Reviews_GetAdminReviewsPaged", new
        {
            normalized.ProductId, normalized.IsApproved, normalized.Keyword,
            normalized.PageNumber, normalized.PageSize
        });

        var itemsList = items.ToList();
        var totalRecords = itemsList.FirstOrDefault()?.TotalRecords ?? 0;

        return new PagedResult<AdminReviewItem>(
            items: itemsList.Select(x => new AdminReviewItem(
                x.ReviewId, x.ProductId, x.ProductName, x.SKU, x.UserId,
                x.FullName, x.Rating, x.Comment, x.ImageURL, x.IsApproved, x.CreatedAt, x.Sentiment
            )),
            totalRecords: totalRecords,
            pageNumber: normalized.PageNumber,
            pageSize: normalized.PageSize
        );
    }

    public Task DeleteAsync(int reviewId, int? userId = null)
        => _db.ExecuteAsync("sp_Admin_DeleteReview", new { ReviewId = reviewId, UserID = userId });

    public Task ApproveAsync(ApproveReviewRequest request)
        => _db.ExecuteAsync("sp_Admin_ApproveReview", new { request.ReviewId, request.IsApproved });

    public Task AddAsync(AddReviewRequest request, string? sentiment)
        => _db.ExecuteAsync("sp_Customer_AddReview", new
        {
            request.UserId,
            request.ProductId,
            request.Rating,
            request.Comment,
            ImageUrl = request.ImageUrl,
            Sentiment = sentiment
        });

    public Task UpdateAsync(int reviewId, int userId, int rating, string? comment, string? imageUrl, string? sentiment)
    {
        return _db.ExecuteRawAsync(
            "UPDATE Reviews SET Rating = @Rating, Comment = @Comment, ImageURL = @ImageUrl, Sentiment = @Sentiment WHERE ReviewID = @ReviewId AND UserID = @UserId",
            new { ReviewId = reviewId, UserId = userId, Rating = rating, Comment = comment, ImageUrl = imageUrl, Sentiment = sentiment }
        );
    }

    public async Task<PagedResult<CustomerReviewItem>> GetByProductAsync(int productId, int pageNumber = 1, int pageSize = 10)
    {
        // Normalize pagination
        pageNumber = pageNumber < 1 ? 1 : pageNumber;
        pageSize = pageSize < 1 ? 10 : (pageSize > 100 ? 100 : pageSize);

        var items = await _db.QueryAsync<CustomerReviewItemWithTotal>("sp_Reviews_GetByProductPaged", new
        {
            ProductId = productId, PageNumber = pageNumber, PageSize = pageSize
        });

        var itemsList = items.ToList();
        var totalRecords = itemsList.FirstOrDefault()?.TotalRecords ?? 0;

        return new PagedResult<CustomerReviewItem>(
            items: itemsList.Select(x => new CustomerReviewItem(
                x.ReviewId, x.ProductId, x.UserId, x.FullName, x.AvatarURL,
                x.Rating, x.Comment, x.ImageURL, x.CreatedAt, x.Sentiment
            )),
            totalRecords: totalRecords,
            pageNumber: pageNumber,
            pageSize: pageSize
        );
    }

    public Task<IEnumerable<TestimonialItem>> GetTopTestimonialsAsync()
    {
        const string sql = @"
            SELECT TOP 3 
                r.ReviewID, 
                r.Rating, 
                r.Comment, 
                r.CreatedAt,
                u.FullName,
                u.AvatarURL
            FROM [dbo].[Reviews] r
            INNER JOIN [dbo].[Users] u ON r.UserID = u.UserID
            WHERE r.Rating >= 4 AND r.IsApproved = 1
            ORDER BY r.CreatedAt DESC;";
        return _db.QueryRawAsync<TestimonialItem>(sql);
    }

    private sealed class AdminReviewItemWithTotal
    {
        public int ReviewId { get; set; }
        public int ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string SKU { get; set; } = string.Empty;
        public int UserId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public string? ImageURL { get; set; }
        public bool IsApproved { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? Sentiment { get; set; }
        public int TotalRecords { get; set; }
    }

    private sealed class CustomerReviewItemWithTotal
    {
        public int ReviewId { get; set; }
        public int ProductId { get; set; }
        public int UserId { get; set; }
        public string? FullName { get; set; }
        public string? AvatarURL { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public string? ImageURL { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? Sentiment { get; set; }
        public int TotalRecords { get; set; }
    }
}


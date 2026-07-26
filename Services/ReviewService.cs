using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Reviews;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class ReviewService : IReviewService
{
    private readonly IReviewRepository _repo;
    private readonly ISentimentService _sentiment;

    public ReviewService(IReviewRepository repo, ISentimentService sentiment)
    {
        _repo = repo;
        _sentiment = sentiment;
    }

    public Task<PagedResult<AdminReviewItem>> GetAdminReviewsAsync(AdminReviewQueryRequest request) => _repo.GetAdminReviewsAsync(request);
    public Task DeleteAsync(int reviewId, int? userId = null) => _repo.DeleteAsync(reviewId, userId);
    public Task ApproveAsync(ApproveReviewRequest request) => _repo.ApproveAsync(request);

    public async Task AddAsync(AddReviewRequest request)
    {
        var sentiment = await _sentiment.AnalyzeSentimentWithGeminiAsync(request.Comment ?? "");
        await _repo.AddAsync(request, sentiment);
    }

    public Task<PagedResult<CustomerReviewItem>> GetByProductAsync(int productId, int pageNumber = 1, int pageSize = 10) 
        => _repo.GetByProductAsync(productId, pageNumber, pageSize);

    public async Task UpdateAsync(int reviewId, int userId, int rating, string? comment, string? imageUrl)
    {
        var sentiment = await _sentiment.AnalyzeSentimentWithGeminiAsync(comment ?? "");
        await _repo.UpdateAsync(reviewId, userId, rating, comment, imageUrl, sentiment);
    }

    public Task<IEnumerable<TestimonialItem>> GetTopTestimonialsAsync() => _repo.GetTopTestimonialsAsync();
}


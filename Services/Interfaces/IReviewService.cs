using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Reviews;

namespace PC_Store.Services.Interfaces;

public interface IReviewService
{
    Task<PagedResult<AdminReviewItem>> GetAdminReviewsAsync(AdminReviewQueryRequest request);
    Task DeleteAsync(int reviewId);
    Task ApproveAsync(ApproveReviewRequest request);
    Task AddAsync(AddReviewRequest request);
    Task<PagedResult<CustomerReviewItem>> GetByProductAsync(int productId, int pageNumber = 1, int pageSize = 10);
}

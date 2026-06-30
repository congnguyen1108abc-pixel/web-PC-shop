using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Common;
using PC_Store.DTOs.Reviews;

namespace PC_Store.Repositories.Interfaces;

public interface IReviewRepository
{
    Task<PagedResult<AdminReviewItem>> GetAdminReviewsAsync(AdminReviewQueryRequest request);
    Task DeleteAsync(int reviewId, int? userId = null);
    Task ApproveAsync(ApproveReviewRequest request);
    Task AddAsync(AddReviewRequest request);
    Task<PagedResult<CustomerReviewItem>> GetByProductAsync(int productId, int pageNumber = 1, int pageSize = 10);
}

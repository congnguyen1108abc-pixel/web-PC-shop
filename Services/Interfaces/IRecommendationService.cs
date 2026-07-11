using PC_Store.DTOs.Recommendations;

namespace PC_Store.Services.Interfaces;

public interface IRecommendationService
{
    Task<IReadOnlyList<RecommendationResult>> GetRecommendationsAsync(int productId, int topN = 8);
}
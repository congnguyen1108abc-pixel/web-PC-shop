using PC_Store.DTOs.Admin;
using PC_Store.Repositories.Interfaces;
using PC_Store.Services.Interfaces;

namespace PC_Store.Services;

public sealed class DashboardService : IDashboardService
{
    private readonly IDashboardRepository _repo;
    private readonly ICacheService _cache;

    private const string CacheKeyPrefix = "dashboard";
    private static readonly TimeSpan SummaryCacheExpiration = TimeSpan.FromMinutes(1);

    public DashboardService(IDashboardRepository repo, ICacheService cache)
    {
        _repo = repo;
        _cache = cache;
    }

    public async Task<DashboardSummary?> GetSummaryAsync()
    {
        var cacheKey = $"{CacheKeyPrefix}:summary";

        var result = await _cache.GetOrCreateAsync(
            key: cacheKey,
            factory: async () =>
            {
                var summary = await _repo.GetSummaryAsync();
                return summary ?? new DashboardSummary(0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
            },
            expiration: SummaryCacheExpiration
        );

        return result;
    }

    public Task<IEnumerable<RevenueReportItem>> GetRevenueReportAsync(RevenueReportRequest request) => _repo.GetRevenueReportAsync(request);
}

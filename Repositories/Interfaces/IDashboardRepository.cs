using PC_Store.DTOs.Admin;

namespace PC_Store.Repositories.Interfaces;

public interface IDashboardRepository
{
    Task<DashboardSummary?> GetSummaryAsync();
    Task<IEnumerable<RevenueReportItem>> GetRevenueReportAsync(RevenueReportRequest request);
}

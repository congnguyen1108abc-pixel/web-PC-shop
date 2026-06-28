using PC_Store.DTOs.Admin;

namespace PC_Store.Services.Interfaces;

public interface IDashboardService
{
    Task<DashboardSummary?> GetSummaryAsync();
    Task<IEnumerable<RevenueReportItem>> GetRevenueReportAsync(RevenueReportRequest request);
}

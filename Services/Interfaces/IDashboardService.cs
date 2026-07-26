using PC_Store.DTOs.Admin;

namespace PC_Store.Services.Interfaces;

public interface IDashboardService
{
    Task<DashboardSummary?> GetSummaryAsync();
    Task<IEnumerable<RevenueReportItem>> GetRevenueReportAsync(RevenueReportRequest request);

    // Financial Reports
    Task<IEnumerable<FinancialDetailItem>> GetFinancialDetailsAsync(DateTime? startDate, DateTime? endDate);
    Task<IEnumerable<TopProductItem>> GetTopProductsAsync(DateTime? startDate, DateTime? endDate, int top = 10);
    Task<IEnumerable<RevenueByCategoryItem>> GetRevenueByCategoryAsync(DateTime? startDate, DateTime? endDate);
    Task<IEnumerable<FinancialYearlySummary>> GetFinancialYearlySummaryAsync();
}

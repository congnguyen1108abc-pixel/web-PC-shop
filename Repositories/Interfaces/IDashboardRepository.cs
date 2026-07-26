using PC_Store.DTOs.Admin;

namespace PC_Store.Repositories.Interfaces;

public interface IDashboardRepository
{
    Task<DashboardSummary?> GetSummaryAsync();
    Task<IEnumerable<RevenueReportItem>> GetRevenueReportAsync(RevenueReportRequest request);

    // Financial Reports
    Task<IEnumerable<FinancialDetailItem>> GetFinancialDetailsAsync(DateTime? startDate, DateTime? endDate);
    Task<IEnumerable<TopProductItem>> GetTopProductsAsync(DateTime? startDate, DateTime? endDate, int top = 10);
    Task<IEnumerable<RevenueByCategoryItem>> GetRevenueByCategoryAsync(DateTime? startDate, DateTime? endDate);
    Task<IEnumerable<FinancialYearlySummary>> GetFinancialYearlySummaryAsync();
}


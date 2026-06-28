using PC_Store.DTOs.Admin;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class DashboardRepository : IDashboardRepository
{
    private readonly IDbRepository _db;

    public DashboardRepository(IDbRepository db) => _db = db;

    public Task<DashboardSummary?> GetSummaryAsync()
        => _db.QuerySingleAsync<DashboardSummary>("sp_Dashboard_GetSummary");

    public Task<IEnumerable<RevenueReportItem>> GetRevenueReportAsync(RevenueReportRequest request)
        => _db.QueryAsync<RevenueReportItem>("sp_Admin_GetRevenueReport", new
        {
            request.StartDate, request.EndDate
        });
}

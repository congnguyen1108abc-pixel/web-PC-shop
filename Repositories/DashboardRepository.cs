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

    // ── Financial Reports ─────────────────────────────────────────────────

    public Task<IEnumerable<FinancialDetailItem>> GetFinancialDetailsAsync(DateTime? startDate, DateTime? endDate)
        => _db.QueryRawAsync<FinancialDetailItem>(@"
            SELECT
                o.OrderID,
                o.OrderDate,
                ISNULL(u.FullName, N'Vãng lai')   AS CustomerName,
                p.ProductName,
                p.SKU,
                od.Quantity,
                od.OriginalPrice,
                ISNULL(od.PromotionDiscount, 0)    AS PromotionDiscount,
                od.UnitPrice                        AS PromoOrFinalPrice,
                v.VoucherCode,
                ISNULL(od.VoucherDiscount, 0)      AS VoucherDiscount,
                od.CostPrice                        AS CostPriceAtPurchase,
                od.UnitPrice * od.Quantity          AS LineTotal,
                od.CostPrice * od.Quantity          AS LineCogs,
                (od.UnitPrice - od.CostPrice) * od.Quantity AS LineProfit
            FROM Orders o
            JOIN OrderDetails od ON od.OrderID = o.OrderID
            JOIN Products p      ON p.ProductID = od.ProductID
            LEFT JOIN Users u    ON u.UserID = o.UserID
            LEFT JOIN Vouchers v ON v.VoucherID = o.VoucherID
            WHERE o.Status = N'Hoàn tất'
              AND (@StartDate IS NULL OR o.OrderDate >= @StartDate)
              AND (@EndDate   IS NULL OR o.OrderDate <= DATEADD(day,1,@EndDate))
            ORDER BY o.OrderDate DESC",
            new { StartDate = startDate, EndDate = endDate });

    public Task<IEnumerable<TopProductItem>> GetTopProductsAsync(DateTime? startDate, DateTime? endDate, int top = 10)
        => _db.QueryRawAsync<TopProductItem>(@"
            SELECT TOP (@Top)
                p.ProductID,
                p.ProductName,
                ISNULL(c.CategoryName, N'Khác') AS CategoryName,
                SUM(od.Quantity)                 AS TotalSold,
                p.Price                          AS SalePrice,
                SUM(od.UnitPrice * od.Quantity)  AS TotalRevenue,
                0.0                              AS ConversionRate
            FROM Orders o
            JOIN OrderDetails od ON od.OrderID = o.OrderID
            JOIN Products p      ON p.ProductID = od.ProductID
            LEFT JOIN Categories c ON c.CategoryID = p.CategoryID
            WHERE o.Status = N'Hoàn tất'
              AND (@StartDate IS NULL OR o.OrderDate >= @StartDate)
              AND (@EndDate   IS NULL OR o.OrderDate <= DATEADD(day,1,@EndDate))
            GROUP BY p.ProductID, p.ProductName, c.CategoryName, p.Price
            ORDER BY TotalRevenue DESC",
            new { StartDate = startDate, EndDate = endDate, Top = top });

    public Task<IEnumerable<RevenueByCategoryItem>> GetRevenueByCategoryAsync(DateTime? startDate, DateTime? endDate)
        => _db.QueryRawAsync<RevenueByCategoryItem>(@"
            SELECT
                ISNULL(c.CategoryName, N'Khác') AS CategoryName,
                COUNT(DISTINCT p.ProductID)      AS TotalProducts,
                SUM(od.Quantity)                 AS TotalSold,
                SUM(od.UnitPrice * od.Quantity)  AS TotalRevenue
            FROM Orders o
            JOIN OrderDetails od ON od.OrderID = o.OrderID
            JOIN Products p      ON p.ProductID = od.ProductID
            LEFT JOIN Categories c ON c.CategoryID = p.CategoryID
            WHERE o.Status = N'Hoàn tất'
              AND (@StartDate IS NULL OR o.OrderDate >= @StartDate)
              AND (@EndDate   IS NULL OR o.OrderDate <= DATEADD(day,1,@EndDate))
            GROUP BY c.CategoryName
            ORDER BY TotalRevenue DESC",
            new { StartDate = startDate, EndDate = endDate });

    public Task<IEnumerable<FinancialYearlySummary>> GetFinancialYearlySummaryAsync()
        => _db.QueryRawAsync<FinancialYearlySummary>(@"
            SELECT
                YEAR(o.OrderDate)                        AS Year,
                SUM(od.UnitPrice * od.Quantity)          AS TotalRevenue,
                SUM(od.CostPrice * od.Quantity)          AS TotalCogs,
                SUM(ISNULL(od.PromotionDiscount,0) * od.Quantity + ISNULL(od.VoucherDiscount,0)) AS TotalPromoDiscount,
                SUM((od.UnitPrice - od.CostPrice) * od.Quantity) AS NetProfit,
                CASE WHEN SUM(od.UnitPrice * od.Quantity) = 0 THEN 0
                     ELSE ROUND(100.0 * SUM((od.UnitPrice - od.CostPrice) * od.Quantity)
                                     / SUM(od.UnitPrice * od.Quantity), 2) END AS ProfitMargin,
                COUNT(DISTINCT o.OrderID)                AS TotalOrders,
                SUM(od.Quantity)                         AS TotalProductsSold
            FROM Orders o
            JOIN OrderDetails od ON od.OrderID = o.OrderID
            WHERE o.Status = N'Hoàn tất'
            GROUP BY YEAR(o.OrderDate)
            ORDER BY Year DESC");
}

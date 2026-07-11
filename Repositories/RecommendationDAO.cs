using Dapper;
using PC_Store.DTOs.Recommendations;
using System.Data;

namespace PC_Store.Repositories;

public sealed class RecommendationDAO
{
    private readonly IDbConnection _connection;

    public RecommendationDAO(IDbConnection connection)
    {
        _connection = connection;
    }

    public async Task<IReadOnlyList<Transaction>> GetCompletedTransactionsAsync()
    {
        const string sql = @"
SELECT
    o.OrderID AS OrderId,
    od.ProductID AS ProductId,
    od.Quantity,
    od.UnitPrice
FROM Orders o
INNER JOIN OrderDetails od ON od.OrderID = o.OrderID
WHERE o.Status = N'Completed'
ORDER BY o.OrderDate, o.OrderID, od.DetailID";

        var rows = (await _connection.QueryAsync<TransactionRow>(sql)).ToList();

        return rows
            .GroupBy(row => row.OrderId)
            .Select(group => new Transaction(
                group.Key,
                group.Select(row => new TransactionItem(
                    row.ProductId,
                    row.Quantity,
                    row.UnitPrice)).ToList()))
            .ToList();
    }

    public async Task<IReadOnlyList<RecommendationProductRow>> GetProductsByIdsAsync(IEnumerable<int> productIds)
    {
        var ids = productIds.Distinct().ToArray();
        if (ids.Length == 0)
        {
            return Array.Empty<RecommendationProductRow>();
        }

        const string sql = @"
SELECT
    p.ProductID AS ProductId,
    p.ProductName,
    p.Slug,
    p.Price,
    p.DiscountPrice,
    p.StockQuantity,
    p.SoldCount,
    COALESCE(img.ImageUrl, '') AS ImageUrl,
    COALESCE(rv.AvgRating, 0) AS AvgRating,
    COALESCE(rv.ReviewCount, 0) AS ReviewCount
FROM Products p
LEFT JOIN (
    SELECT
        ProductID,
        COALESCE(MAX(CASE WHEN IsDefault = 1 THEN ImageUrl END), MAX(ImageUrl)) AS ImageUrl
    FROM ProductImages
    GROUP BY ProductID
) img ON img.ProductID = p.ProductID
LEFT JOIN (
    SELECT
        ProductID,
        CAST(AVG(CAST(Rating AS DECIMAL(18, 2))) AS DECIMAL(18, 2)) AS AvgRating,
        COUNT(1) AS ReviewCount
    FROM Reviews
    WHERE IsApproved = 1
    GROUP BY ProductID
) rv ON rv.ProductID = p.ProductID
WHERE p.ProductID IN @ProductIds
  AND p.IsActive = 1";

        var rows = await _connection.QueryAsync<RecommendationProductRow>(sql, new { ProductIds = ids });
        return rows.ToList();
    }

    private sealed record TransactionRow(
        int OrderId,
        int ProductId,
        int Quantity,
        decimal UnitPrice);

    public sealed record RecommendationProductRow(
        int ProductId,
        string ProductName,
        string? Slug,
        decimal Price,
        decimal DiscountPrice,
        int StockQuantity,
        int SoldCount,
        string? ImageUrl,
        decimal AvgRating,
        int ReviewCount);
}
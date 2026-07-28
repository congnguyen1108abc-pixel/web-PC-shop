using PC_Store.DTOs.Admin;
using PC_Store.DTOs.Warranty;
using PC_Store.Repositories.Base;
using PC_Store.Repositories.Interfaces;

namespace PC_Store.Repositories;

public sealed class WarrantyRepository : IWarrantyRepository
{
    private readonly IDbRepository _db;
    public WarrantyRepository(IDbRepository db) => _db = db;

    public Task CreateClaimAsync(CreateWarrantyClaimRequest request)
        => _db.ExecuteAsync("sp_Customer_CreateWarrantyClaim", new
        {
            request.WarrantyCode, request.UserId, request.Description, request.ImageUrl
        });

    public Task<IEnumerable<WarrantyItem>> GetWarrantiesAsync(int userId)
        => _db.QueryAsync<WarrantyItem>("sp_Customer_GetWarranties", new { UserId = userId });

    public Task<WarrantyItem?> GetByCodeAsync(string warrantyCode, int? userId)
        => _db.QuerySingleAsync<WarrantyItem>("sp_Warranty_GetByCode", new { WarrantyCode = warrantyCode, UserId = userId });

    public Task<IEnumerable<WarrantyClaimItem>> GetAdminClaimsAsync(WarrantyClaimQueryRequest request)
        => _db.QueryAsync<WarrantyClaimItem>("sp_Admin_GetWarrantyClaims", new
        {
            request.Status, request.UserId, request.WarrantyCode, request.DateFrom, request.DateTo
        });

    public Task ProcessClaimAsync(ProcessWarrantyClaimRequest request)
        => _db.ExecuteAsync("sp_Admin_ProcessWarrantyClaim", new
        {
            request.ClaimId, request.NewStatus, request.Resolution
        });

    public Task<IEnumerable<WarrantyItem>> PublicLookupAsync(string query)
    {
        var sql = @"
            SELECT 
                ISNULL(pw.WarrantyID, 0) AS WarrantyId,
                od.DetailID AS OrderDetailId,
                od.OrderID,
                p.ProductID,
                p.ProductName,
                p.SKU,
                ISNULL(img.ImageURL, '/images/default_product.png') AS DefaultImageUrl,
                o.OrderDate AS StartDate,
                DATEADD(MONTH, ISNULL(p.WarrantyMonths, 12), o.OrderDate) AS EndDate,
                ISNULL(pw.WarrantyCode, CONCAT('SN-', p.SKU, '-', o.OrderID, '-', od.DetailID)) AS WarrantyCode,
                CASE 
                    WHEN DATEADD(MONTH, ISNULL(p.WarrantyMonths, 12), o.OrderDate) >= GETDATE() THEN N'🟢 Còn bảo hành'
                    ELSE N'🔴 Hết bảo hành'
                END AS Status,
                od.Quantity,
                od.UnitPrice
            FROM OrderDetails od
            JOIN Orders o ON od.OrderID = o.OrderID
            JOIN Users u ON o.UserID = u.UserID
            JOIN Products p ON od.ProductID = p.ProductID
            LEFT JOIN ProductWarranties pw ON pw.OrderDetailID = od.DetailID
            OUTER APPLY
            (
                SELECT TOP 1 ImageURL
                FROM ProductImages
                WHERE ProductID = p.ProductID
                ORDER BY IsDefault DESC, SortOrder ASC, ImageID ASC
            ) img
            WHERE u.PhoneNumber = @Query 
               OR o.ReceiverPhone = @Query
               OR pw.WarrantyCode = @Query
               OR p.SKU = @Query
               OR p.SKU LIKE '%' + @Query + '%'
               OR pw.WarrantyCode LIKE '%' + @Query + '%'
            ORDER BY o.OrderDate DESC";
        return _db.QueryAsync<WarrantyItem>(sql, new { Query = query });
    }
}

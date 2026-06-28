namespace PC_Store.DTOs.Admin;

public sealed record ManageUserRoleRequest(
    int AdminId,
    int UserId,
    string RoleCode,
    string Action);

public sealed record ImportStockRequest(int ProductId, int QuantityToAdd, string Note);

public sealed record UpdateOrderStatusRequest(int OrderId, int UserId, string NewStatus, string? AdminNote);

public sealed record ProcessWarrantyClaimRequest(int ClaimId, string NewStatus, string Resolution);

public sealed record UpsertBannerRequest(
    int? BannerId,
    string Title,
    string ImageUrl,
    string? LinkUrl,
    int DisplayOrder,
    DateTime? StartDate,
    DateTime? EndDate,
    bool IsActive);

public sealed record RevenueReportRequest(DateTime StartDate, DateTime EndDate);

public sealed record LowStockAlertRequest(int Threshold);

public sealed record ApproveReviewRequest(int ReviewId, bool IsApproved);

public sealed record TopSellingRequest(int TopN, DateTime? StartDate, DateTime? EndDate);

public sealed record RevenueReportItem(
    DateTime SalesDate,
    int TotalOrders,
    decimal Revenue,
    decimal TotalDiscount,
    decimal AvgOrderValue);

public sealed record LowStockItem(string SKU, string ProductName, int StockQuantity, int SoldCount);

public sealed record TopSellingItem(
    int ProductId,
    string ProductName,
    string SKU,
    int TotalSold,
    decimal TotalRevenue);

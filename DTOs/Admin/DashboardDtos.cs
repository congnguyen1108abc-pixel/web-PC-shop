namespace PC_Store.DTOs.Admin;

public sealed record DashboardSummary(
    int TotalUsers,
    int ActiveUsers,
    int TotalProducts,
    int ActiveProducts,
    int PendingOrders,
    int ShippingOrders,
    int CompletedOrders,
    int LowStockProducts,
    int OpenWarrantyClaims,
    int UnreadNotifications,
    decimal NetRevenue,
    decimal TotalCogs,
    decimal NetProfit);

// ── Financial Reports ────────────────────────────────────────────────────

public sealed record FinancialDetailItem(
    int OrderID,
    DateTime OrderDate,
    string CustomerName,
    string ProductName,
    string SKU,
    int Quantity,
    decimal OriginalPrice,
    decimal PromotionDiscount,
    decimal PromoOrFinalPrice,
    string? VoucherCode,
    decimal VoucherDiscount,
    decimal CostPriceAtPurchase,
    decimal LineTotal,
    decimal LineCogs,
    decimal LineProfit);

public sealed record TopProductItem(
    int ProductID,
    string ProductName,
    string CategoryName,
    int TotalSold,
    decimal SalePrice,
    decimal TotalRevenue,
    decimal ConversionRate);

public sealed record RevenueByCategoryItem(
    string CategoryName,
    int TotalProducts,
    int TotalSold,
    decimal TotalRevenue);

public sealed record FinancialYearlySummary(
    int Year,
    decimal TotalRevenue,
    decimal TotalCogs,
    decimal TotalPromoDiscount,
    decimal NetProfit,
    decimal ProfitMargin,
    int TotalOrders,
    int TotalProductsSold);


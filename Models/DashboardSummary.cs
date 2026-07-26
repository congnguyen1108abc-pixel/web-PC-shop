namespace PC_Store.Models;

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

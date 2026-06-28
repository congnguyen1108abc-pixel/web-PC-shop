namespace PC_Store.DTOs.Admin;

public sealed record InventoryLogQueryRequest(
    int? ProductId,
    string? LogType,
    int? RelatedOrderId,
    DateTime? DateFrom,
    DateTime? DateTo);

public sealed record InventoryLogItem(
    int LogId,
    int ProductId,
    string ProductName,
    string SKU,
    int ChangeQuantity,
    int QuantityAfter,
    string LogType,
    int? RelatedOrderId,
    DateTime CreatedAt,
    string? Note);

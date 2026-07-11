namespace PC_Store.DTOs.Recommendations;

public sealed record TransactionItem(
    int ProductId,
    int Quantity,
    decimal UnitPrice)
{
    public decimal Utility => Quantity * UnitPrice;
}
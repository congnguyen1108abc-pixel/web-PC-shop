namespace PC_Store.DTOs.Recommendations;

public sealed record Transaction(
    int OrderId,
    IReadOnlyList<TransactionItem> Items)
{
    public IReadOnlyCollection<int> ProductIds => Items
        .Select(item => item.ProductId)
        .Distinct()
        .ToArray();
}
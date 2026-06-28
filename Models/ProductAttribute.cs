namespace PC_Store.Models;

public sealed record ProductAttribute(
    int AttrId,
    int ProductId,
    string AttributeName,
    string AttributeValue,
    int SortOrder);

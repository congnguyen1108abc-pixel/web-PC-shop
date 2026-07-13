using System;

namespace PC_Store.DTOs.Orders;

public sealed record CustomerCreateReturnRequest(
    int OrderId,
    int UserId,
    string Reason,
    string? EvidenceImages,
    decimal RefundAmount,
    string RefundBankName,
    string RefundAccountNo,
    string RefundAccountName,
    string ReturnAddress,
    string ReturnWardCode,
    int ReturnDistrictId);


public sealed record AdminProcessReturnRequest(
    int ReturnId,
    string NewStatus,
    string? AdminNote);

public sealed record AdminCompleteRefundRequest(
    int ReturnId,
    string PaymentMethod,
    string? TransactionNo,
    string? AdminNote);

public sealed record ReturnRequestListItem(
    int ReturnId,
    int OrderId,
    int UserId,
    string FullName,
    string Email,
    string Reason,
    string? EvidenceImages,
    decimal RefundAmount,
    string? RefundBankName,
    string? RefundAccountNo,
    string? RefundAccountName,
    string? ReturnAddress,
    string? ReturnWardCode,
    int? ReturnDistrictId,
    string Status,
    string? ReturnTrackingCode,
    string? AdminNote,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    int TotalRecords);

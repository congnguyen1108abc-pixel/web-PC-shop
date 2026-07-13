IF OBJECT_ID('sp_Admin_CompleteRefund', 'P') IS NOT NULL
    DROP PROCEDURE sp_Admin_CompleteRefund;
GO
CREATE PROCEDURE sp_Admin_CompleteRefund
    @ReturnID INT,
    @PaymentMethod NVARCHAR(50),
    @TransactionNo NVARCHAR(100) = NULL,
    @AdminNote NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @OrderID INT;
        DECLARE @RefundAmount DECIMAL(18,2);
        SELECT @OrderID = OrderID, @RefundAmount = RefundAmount FROM ReturnRequests WHERE ReturnID = @ReturnID;

        IF @OrderID IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy yêu cầu đổi trả.', 16, 1);
            RETURN;
        END

        -- Cập nhật trạng thái đổi trả thành 'Refunded'
        UPDATE ReturnRequests
        SET Status = 'Refunded',
            AdminNote = ISNULL(@AdminNote, AdminNote),
            UpdatedAt = GETDATE()
        WHERE ReturnID = @ReturnID;

        -- Ghi nhận lịch sử giao dịch hoàn tiền
        INSERT INTO RefundTransactions (ReturnID, Amount, PaymentMethod, TransactionNo, Status, CreatedAt)
        VALUES (@ReturnID, @RefundAmount, @PaymentMethod, @TransactionNo, 'Success', GETDATE());

        -- Cập nhật trạng thái đơn hàng gốc thành 'Đã hủy' và trạng thái thanh toán thành 'Hoàn tiền'
        UPDATE Orders
        SET Status = N'Đã hủy',
            PaymentStatus = N'Hoàn tiền',
            AdminNote = N'Hoàn đơn thành công - Đã hoàn tiền cho khách',
            UpdatedAt = GETDATE()
        WHERE OrderID = @OrderID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

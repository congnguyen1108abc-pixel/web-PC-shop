Text                                                                                                                                                                                                                                                           
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

                                                                                                                                                                                                                                                             
-- ============================================================================
                                                                                                                                                                              
-- CẬP NHẬT CÁC STORED PROCEDURES
                                                                                                                                                                                                                       
-- ============================================================================
                                                                                                                                                                              

                                                                                                                                                                                                                                                             
-- 1. sp_Product_GetAllPaged (KM động)
                                                                                                                                                                                                                    
CREATE   PROCEDURE sp_Product_GetAllPaged
                                                                                                                                                                                                                    
    @CategoryId INT = NULL,
                                                                                                                                                                                                                                  
    @BrandId INT = NULL,
                                                                                                                                                                                                                                     
    @Keyword NVARCHAR(100) = NULL,
                                                                                                                                                                                                                           
    @MinPrice DECIMAL(18,2) = NULL,
                                                                                                                                                                                                                          
    @MaxPrice DECIMAL(18,2) = NULL,
                                                                                                                                                                                                                          
    @OnlyActive BIT = 1,
                                                                                                                                                                                                                                     
    @SortBy VARCHAR(50) = 'Newest',
                                                                                                                                                                                                                          
    @PageNumber INT = 1,
                                                                                                                                                                                                                                     
    @PageSize INT = 10
                                                                                                                                                                                                                                       
AS
                                                                                                                                                                                                                                                           
BEGIN
                                                                                                                                                                                                                                                        
    SET NOCOUNT ON;
                                                                                                                                                                                                                                          

                                                                                                                                                                                                                                                             
    IF @PageNumber < 1 SET @PageNumber = 1;
                                                                                                                                                                                                                  
    IF @PageSize < 1 SET @PageSize = 10;
                                                                                                                                                                                                                     
    IF @PageSize > 100 SET @PageSize = 100;
                                                                                                                                                                                                                  

                                                                                                                                                                                                                                                             
    DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
                                                                                                                                                                                                     

                                                                                                                                                                                                                                                             
    WITH FilteredProducts AS (
                                                                                                                                                                                                                               
        SELECT 
                                                                                                                                                                                                                                              
            p.ProductID,
                                                                                                                                                                                                                                     
            p.CategoryID,
                                                                                                                                                                                                                                    
            c.CategoryName,
                                                                                                                                                                                                                                  
            p.BrandID,
                                                                                                                                                                                                                                       
            b.BrandName,
                                                                                                                                                                                                                                     
            p.SKU,
                                                                                                                                                                                                                                           
            p.ProductName,
                                                                                                                                                                                                                                   
            p.Price,
                                                                                                                                                                                                                                         
            p.DiscountPrice,
                                                                                                                                                                                                                                 
            p.CostPrice,
                                                                                                                                                                                                                                     
            CAST(
                                                                                                                                                                                                                                            
                CASE 
                                                                                                                                                                                                                                        
                    WHEN activePromo.DiscountType = 'Percentage' THEN p.Price * (1.0 - activePromo.DiscountValue / 100.0)
                                                                                                                                    
                    WHEN activePromo.DiscountType = 'FixedAmount' THEN CASE WHEN p.Price - activePromo.DiscountValue < 0 THEN 0 ELSE p.Price - activePromo.DiscountValue END
                                                                                 
                    ELSE COALESCE(NULLIF(p.DiscountPrice, 0), p.Price)
                                                                                                                                                                                       
                END AS DECIMAL(18,2)
                                                                                                                                                                                                                         
            ) AS EffectivePrice,
                                                                                                                                                                                                                             
            p.StockQuantity,
                                                                                                                                                                                                                                 
            p.SoldCount,
                                                                                                                                                                                                                                     
            p.Description,
                                                                                                                                                                                                                                   
            p.IsActive,
                                                                                                                                                                                                                                      
            p.WarrantyMonths,
                                                                                                                                                                                                                                
            p.Slug,
                                                                                                                                                                                                                                          
            p.CreatedAt,
                                                                                                                                                                                                                                     
            p.UpdatedAt,
                                                                                                                                                                                                                                     
            (SELECT TOP 1 ImageUrl FROM ProductImages pi WHERE pi.ProductID = p.ProductID AND pi.IsDefault = 1) AS DefaultImageUrl,
                                                                                                                          
            ISNULL((SELECT AVG(CAST(Rating AS DECIMAL(3,1))) FROM Reviews r WHERE r.ProductID = p.ProductID AND r.IsApproved = 1), 0) AS AvgRating,
                                                                                                          
            ISNULL((SELECT COUNT(*) FROM Reviews r WHERE r.ProductID = p.ProductID AND r.IsApproved = 1), 0) AS ReviewCount,
                                                                                                                                 
            COUNT(*) OVER() AS TotalRecords
                                                                                                                                                                                                                  
        FROM Products p
                                                                                                                                                                                                                                      
        LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
                                                                                                                                                                                                
        LEFT JOIN Brands b ON p.BrandID = b.BrandID
                                                                                                                                                                                                          
        OUTER APPLY (
                                                                                                                                                                                                                                        
            SELECT TOP 1 pp.DiscountType, pp.DiscountValue
                                                                                                                                                                                                   
            FROM ProductPromotions pp
                                                                                                                                                                                                                        
            WHERE pp.ProductID = p.ProductID
                                                                                                                                                                                                                 
              AND pp.Status = 'Active'
                                                                                                                                                                                                                       
              AND pp.StartDate <= GETDATE()
                                                                                                                                                                                                                  
              AND pp.EndDate >= GETDATE()
                                                                                                                                                                                                                    
            ORDER BY pp.CreatedAt DESC
                                                                                                                                                                                                                       
        ) activePromo
                                                                                                                                                                                                                                        
        WHERE 
                                                                                                                                                                                                                                               
            (@CategoryId IS NULL OR p.CategoryID = @CategoryId)
                                                                                                                                                                                              
            AND (@BrandId IS NULL OR p.BrandID = @BrandId)
                                                                                                                                                                                                   
            AND (@Keyword IS NULL OR p.ProductName LIKE '%' + @Keyword + '%' OR p.SKU LIKE '%' + @Keyword + '%')
                                                                                                                                             
            AND (@MinPrice IS NULL OR 
                                                                                                                                                                                                                       
                 CAST(
                                                                                                                                                                                                                                       
                    CASE 
                                                                                                                                                                                                                                    
                        WHEN activePromo.DiscountType = 'Percentage' THEN p.Price * (1.0 - activePromo.DiscountValue / 100.0)
                                                                                                                                
                        WHEN activePromo.DiscountType = 'FixedAmount' THEN CASE WHEN p.Price - activePromo.DiscountValue < 0 THEN 0 ELSE p.Price - activePromo.DiscountValue END
                                                                             
                        ELSE COALESCE(NULLIF(p.DiscountPrice, 0), p.Price)
                                                                                                                                                                                   
                    END AS DECIMAL(18,2)
                                                                                                                                                                                                                     
                 ) >= @MinPrice)
                                                                                                                                                                                                                             
            AND (@MaxPrice IS NULL OR 
                                                                                                                                                                                                                       
                 CAST(
                                                                                                                                                                                                                                       
                    CASE 
                                                                                                                                                                                                                                    
                        WHEN activePromo.DiscountType = 'Percentage' THEN p.Price * (1.0 - activePromo.DiscountValue / 100.0)
                                                                                                                                
                        WHEN activePromo.DiscountType = 'FixedAmount' THEN CASE WHEN p.Price - activePromo.DiscountValue < 0 THEN 0 ELSE p.Price - activePromo.DiscountValue END
                                                                             
                        ELSE COALESCE(NULLIF(p.DiscountPrice, 0), p.Price)
                                                                                                                                                                                   
                    END AS DECIMAL(18,2)
                                                                                                                                                                                                                     
                 ) <= @MaxPrice)
                                                                                                                                                                                                                             
            AND (@OnlyActive = 0 OR p.IsActive = 1)
                                                                                                                                                                                                          
    )
                                                                                                                                                                                                                                                        
    SELECT 
                                                                                                                                                                                                                                                  
        ProductID,
                                                                                                                                                                                                                                           
        CategoryID,
                                                                                                                                                                                                                                          
        CategoryName,
                                                                                                                                                                                                                                        
        BrandID,
                                                                                                                                                                                                                                             
        BrandName,
                                                                                                                                                                                                                                           
        SKU,
                                                                                                                                                                                                                                                 
        ProductName,
                                                                                                                                                                                                                                         
        Price,
                                                                                                                                                                                                                                               
        DiscountPrice,
                                                                                                                                                                                                                                       
        CostPrice,
                                                                                                                                                                                                                                           
        EffectivePrice,
                                                                                                                                                                                                                                      
        StockQuantity,
                                                                                                                                                                                                                                       
        SoldCount,
                                                                                                                                                                                                                                           
        Description,
                                                                                                                                                                                                                                         
        IsActive,
                                                                                                                                                                                                                                            
        WarrantyMonths,
                                                                                                                                                                                                                                      
        Slug,
                                                                                                                                                                                                                                                
        CreatedAt,
                                                                                                                                                                                                                                           
        UpdatedAt,
                                                                                                                                                                                                                                           
        DefaultImageUrl,
                                                                                                                                                                                                                                     
        AvgRating,
                                                                                                                                                                                                                                           
        ReviewCount,
                                                                                                                                                                                                                                         
        TotalRecords
                                                                                                                                                                                                                                         
    FROM FilteredProducts
                                                                                                                                                                                                                                    
    ORDER BY 
                                                                                                                                                                                                                                                
        CASE WHEN @SortBy = 'PriceAsc' THEN EffectivePrice END ASC,
                                                                                                                                                                                          
        CASE WHEN @SortBy = 'PriceDesc' THEN EffectivePrice END DESC,
                                                                                                                                                                                        
        CASE WHEN @SortBy = 'Popular' THEN SoldCount END DESC,
                                                                                                                                                                                               
        CASE WHEN @SortBy = 'Rating' THEN AvgRating END DESC,
                                                                                                                                                                                                
        CASE WHEN @SortBy = 'Newest' OR @SortBy IS NULL THEN CreatedAt END DESC
                                                                                                                                                                              
    OFFSET @Offset ROWS
                                                                                                                                                                                                                                      
    FETCH NEXT @PageSize ROWS ONLY;
                                                                                                                                                                                                                          
END;
                                                                                                                                                                                                                                                         

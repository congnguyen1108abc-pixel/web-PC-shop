-- =================================================================
-- UPDATE BANNERS TABLE TO SUPPORT VIDEO CLIPS
-- =================================================================

-- 1. Add VideoURL column to Banners table (if not exists)
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'Banners' AND COLUMN_NAME = 'VideoURL')
BEGIN
    ALTER TABLE Banners
    ADD VideoURL NVARCHAR(500) NULL;
END
GO

-- 2. Add VideoThumbnail column to store thumbnail image
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'Banners' AND COLUMN_NAME = 'VideoThumbnail')
BEGIN
    ALTER TABLE Banners
    ADD VideoThumbnail NVARCHAR(500) NULL;
END
GO

-- 3. Add BannerType column to distinguish between image and video banners
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'Banners' AND COLUMN_NAME = 'BannerType')
BEGIN
    ALTER TABLE Banners
    ADD BannerType NVARCHAR(50) DEFAULT N'Image' 
        CHECK (BannerType IN (N'Image', N'Video'));
END
GO

-- 4. Sample data: Insert banner with video clip for homepage hero
INSERT INTO Banners (Title, ImageURL, VideoURL, VideoThumbnail, LinkURL, DisplayOrder, BannerType, IsActive, CreatedAt)
VALUES 
    (
        N'ROG Astral GeForce RTX 5090 Banner',
        N'/assets/image/home_hero_video_63920634971807903.mp4',
        N'/assets/image/ROGAstralGeForceRTX5090_clip.mp4',
        N'/assets/image/home_hero_video_63920634971807903_thumb.jpg',
        NULL,
        1,
        N'Video',
        1,
        GETDATE()
    ),
    (
        N'PC Gaming Setup Banner',
        N'/assets/image/PCGaming_clip.mp4',
        N'/assets/image/PCGaming_clip.mp4',
        N'/assets/image/PCGaming_clip_thumb.jpg',
        NULL,
        2,
        N'Video',
        1,
        GETDATE()
    );
GO

-- 5. View to get active banners
CREATE OR ALTER VIEW vw_ActiveBanners AS
SELECT 
    BannerID,
    Title,
    ImageURL,
    VideoURL,
    VideoThumbnail,
    LinkURL,
    DisplayOrder,
    BannerType,
    IsActive,
    CreatedAt,
    StartDate,
    EndDate
FROM Banners
WHERE IsActive = 1
  AND (StartDate IS NULL OR StartDate <= GETDATE())
  AND (EndDate IS NULL OR EndDate >= GETDATE())
ORDER BY DisplayOrder ASC;
GO

-- 6. Stored Procedure to get banners for homepage
CREATE OR ALTER PROCEDURE sp_GetHomepageBanners
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP 1
        BannerID,
        Title,
        ImageURL,
        VideoURL,
        VideoThumbnail,
        BannerType,
        LinkURL
    FROM vw_ActiveBanners
    WHERE BannerType = N'Video'
    ORDER BY DisplayOrder ASC;
END
GO

-- 7. Stored Procedure to update or insert banner
CREATE OR ALTER PROCEDURE sp_UpsertBanner
    @BannerID INT = NULL,
    @Title NVARCHAR(200),
    @ImageURL NVARCHAR(500),
    @VideoURL NVARCHAR(500) = NULL,
    @VideoThumbnail NVARCHAR(500) = NULL,
    @LinkURL NVARCHAR(500) = NULL,
    @DisplayOrder INT = 0,
    @BannerType NVARCHAR(50) = N'Image',
    @IsActive BIT = 1,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @BannerID IS NULL OR @BannerID = 0
    BEGIN
        -- Insert new banner
        INSERT INTO Banners (Title, ImageURL, VideoURL, VideoThumbnail, LinkURL, DisplayOrder, BannerType, IsActive, StartDate, EndDate)
        VALUES (@Title, @ImageURL, @VideoURL, @VideoThumbnail, @LinkURL, @DisplayOrder, @BannerType, @IsActive, @StartDate, @EndDate);
        
        SELECT SCOPE_IDENTITY() AS BannerID;
    END
    ELSE
    BEGIN
        -- Update existing banner
        UPDATE Banners
        SET 
            Title = @Title,
            ImageURL = @ImageURL,
            VideoURL = @VideoURL,
            VideoThumbnail = @VideoThumbnail,
            LinkURL = @LinkURL,
            DisplayOrder = @DisplayOrder,
            BannerType = @BannerType,
            IsActive = @IsActive,
            StartDate = @StartDate,
            EndDate = @EndDate
        WHERE BannerID = @BannerID;
        
        SELECT @BannerID AS BannerID;
    END
END
GO

PRINT 'Banner table updated successfully with video support!';
GO

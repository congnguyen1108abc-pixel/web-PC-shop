-- 1. Insert Categories if they don't exist
SET IDENTITY_INSERT dbo.Categories ON;
IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE CategoryID = 7)
    INSERT INTO dbo.Categories (CategoryID, CategoryName, SortOrder, IsActive) VALUES (7, N'Gaming Gear', 7, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE CategoryID = 8)
    INSERT INTO dbo.Categories (CategoryID, CategoryName, SortOrder, IsActive) VALUES (8, N'Vỏ máy tính (Case)', 8, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.Categories WHERE CategoryID = 9)
    INSERT INTO dbo.Categories (CategoryID, CategoryName, SortOrder, IsActive) VALUES (9, N'Tản nhiệt PC', 9, 1);
SET IDENTITY_INSERT dbo.Categories OFF;

-- 2. Insert Brands if they don't exist
SET IDENTITY_INSERT dbo.Brands ON;
IF NOT EXISTS (SELECT 1 FROM dbo.Brands WHERE BrandID = 8)
    INSERT INTO dbo.Brands (BrandID, BrandName, IsActive) VALUES (8, N'HYPER CORE', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.Brands WHERE BrandID = 9)
    INSERT INTO dbo.Brands (BrandID, BrandName, IsActive) VALUES (9, N'G.Skill', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.Brands WHERE BrandID = 10)
    INSERT INTO dbo.Brands (BrandID, BrandName, IsActive) VALUES (10, N'Lian Li', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.Brands WHERE BrandID = 11)
    INSERT INTO dbo.Brands (BrandID, BrandName, IsActive) VALUES (11, N'NZXT', 1);
IF NOT EXISTS (SELECT 1 FROM dbo.Brands WHERE BrandID = 12)
    INSERT INTO dbo.Brands (BrandID, BrandName, IsActive) VALUES (12, N'Kingston', 1);
SET IDENTITY_INSERT dbo.Brands OFF;

-- 3. Insert Products
SET IDENTITY_INSERT dbo.Products ON;

-- 3.1. Gaming Gear (Category 7, Brand 8)
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 41)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (41, 7, 8, 'GG-MOUSE-01', N'CORE M-PRO', 2450000, 0, 100, N'Chuột Esports không dây hiệu năng cao', 1, 24, dbo.fn_GenerateSlug(N'CORE M-PRO'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 42)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (42, 7, 8, 'GG-KB-01', N'CORE K-ELITE', 3890000, 0, 100, N'Bàn phím cơ cao cấp Ceramic switch', 1, 24, dbo.fn_GenerateSlug(N'CORE K-ELITE'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 43)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (43, 7, 8, 'GG-HS-01', N'CORE H-SOUND', 2890000, 0, 100, N'Tai nghe Gaming âm thanh vòm không dây', 1, 24, dbo.fn_GenerateSlug(N'CORE H-SOUND'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 44)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (44, 7, 8, 'GG-MIC-01', N'CORE STUDIO', 3100000, 0, 100, N'Microphone thu âm chuyên nghiệp cho Streamer', 1, 12, dbo.fn_GenerateSlug(N'CORE STUDIO'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 45)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (45, 7, 8, 'GG-PAD-01', N'CORE G-CMD', 4500000, 0, 100, N'Tay cầm chơi game không dây cao cấp', 1, 12, dbo.fn_GenerateSlug(N'CORE G-CMD'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 46)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (46, 7, 8, 'GG-MPAD-01', N'CORE PAD PRO', 1800000, 0, 200, N'Lót chuột RGB kích thước lớn', 1, 6, dbo.fn_GenerateSlug(N'CORE PAD PRO'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 47)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (47, 7, 8, 'GG-ACC-01', N'CORE BASE RGB', 1200000, 0, 100, N'Giá treo tai nghe RGB cao cấp', 1, 12, dbo.fn_GenerateSlug(N'CORE BASE RGB'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 48)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (48, 7, 8, 'GG-RC-01', N'CORE WHEEL', 9500000, 0, 50, N'Vô lăng chơi game phản hồi lực TrueForce', 1, 24, dbo.fn_GenerateSlug(N'CORE WHEEL'));

-- 3.2. PC Build Components
-- CPUs (Category 2)
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 49)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (49, 2, 6, 'CPU-INTEL-12400F', N'Intel Core i5-12400F', 3500000, 0, 100, N'6 Nhân 12 Luồng | 2.5GHz up to 4.4GHz', 1, 36, dbo.fn_GenerateSlug(N'Intel Core i5-12400F'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 50)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (50, 2, 5, 'CPU-AMD-5700X', N'AMD Ryzen 7 5700X', 6000000, 0, 100, N'8 Nhân 16 Luồng | 3.4GHz up to 4.6GHz', 1, 36, dbo.fn_GenerateSlug(N'AMD Ryzen 7 5700X'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 51)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (51, 2, 5, 'CPU-AMD-7600X', N'AMD Ryzen 5 7600X', 5500000, 0, 100, N'6 Nhân 12 Luồng | 4.7GHz up to 5.3GHz', 1, 36, dbo.fn_GenerateSlug(N'AMD Ryzen 5 7600X'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 52)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (52, 2, 6, 'CPU-INTEL-14700K', N'Intel Core i7-14700K', 9500000, 0, 100, N'20 Nhân 28 Luồng | 3.4GHz up to 5.6GHz', 1, 36, dbo.fn_GenerateSlug(N'Intel Core i7-14700K'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 53)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (53, 2, 5, 'CPU-AMD-7900X', N'AMD Ryzen 9 7900X', 11500000, 0, 100, N'12 Nhân 24 Luồng | 4.7GHz up to 5.6GHz', 1, 36, dbo.fn_GenerateSlug(N'AMD Ryzen 9 7900X'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 54)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (54, 2, 6, 'CPU-INTEL-13600K', N'Intel Core i5-13600K', 7500000, 0, 100, N'14 Nhân 20 Luồng | 3.5GHz up to 5.1GHz', 1, 36, dbo.fn_GenerateSlug(N'Intel Core i5-13600K'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 55)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (55, 2, 5, 'CPU-AMD-7700X', N'AMD Ryzen 7 7700X', 8900000, 0, 100, N'8 Nhân 16 Luồng | 4.5GHz up to 5.4GHz', 1, 36, dbo.fn_GenerateSlug(N'AMD Ryzen 7 7700X'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 56)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (56, 2, 6, 'CPU-INTEL-14900K', N'Intel Core i9-14900K', 14500000, 0, 100, N'24 Nhân 32 Luồng | 3.2GHz up to 6.0GHz', 1, 36, dbo.fn_GenerateSlug(N'Intel Core i9-14900K'));

-- VGAs (Category 1)
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 57)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (57, 1, 2, 'VGA-MSI-3060', N'RTX 3060 12GB', 8000000, 0, 100, N'12GB GDDR6 | 192-bit', 1, 36, dbo.fn_GenerateSlug(N'RTX 3060 12GB'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 58)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (58, 1, 1, 'VGA-ASUS-4060TI', N'RTX 4060 Ti 8GB', 13500000, 0, 100, N'8GB GDDR6 | DLSS 3', 1, 36, dbo.fn_GenerateSlug(N'RTX 4060 Ti 8GB'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 59)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (59, 1, 3, 'VGA-GIGA-4080S', N'GeForce RTX 4080 Super 16GB', 27500000, 0, 100, N'16GB GDDR6X | 256-bit', 1, 36, dbo.fn_GenerateSlug(N'GeForce RTX 4080 Super 16GB'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 60)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (60, 1, 2, 'VGA-MSI-4070', N'RTX 4070 12GB', 12000000, 0, 100, N'12GB GDDR6X | DLSS 3', 1, 36, dbo.fn_GenerateSlug(N'RTX 4070 12GB'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 61)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (61, 1, 1, 'VGA-ASUS-4070TIS', N'RTX 4070 Ti Super 16GB', 22000000, 0, 100, N'16GB GDDR6X | 256-bit', 1, 36, dbo.fn_GenerateSlug(N'RTX 4070 Ti Super 16GB'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 62)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (62, 1, 2, 'VGA-MSI-4080', N'RTX 4080 16GB', 26500000, 0, 100, N'16GB GDDR6X | DLSS 3', 1, 36, dbo.fn_GenerateSlug(N'RTX 4080 16GB'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 63)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (63, 1, 1, 'VGA-ASUS-4070TIS-ROG', N'ASUS ROG Strix RTX 4070 Ti Super 16GB', 26900000, 0, 100, N'ROG Premium Custom | AURA Sync', 1, 36, dbo.fn_GenerateSlug(N'ASUS ROG Strix RTX 4070 Ti Super 16GB'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 64)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (64, 1, 2, 'VGA-MSI-4060TI-SLIM', N'MSI Gaming X Slim RTX 4060 Ti 8GB', 11500000, 0, 100, N'Slim Style | Twin Frozr 9', 1, 36, dbo.fn_GenerateSlug(N'MSI Gaming X Slim RTX 4060 Ti 8GB'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 65)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (65, 1, 3, 'VGA-GIGA-4080S-WF', N'Gigabyte GeForce RTX 4080 Super Windforce 16GB', 32500000, 0, 100, N'WindForce 3X Cooling | Metal Backplate', 1, 36, dbo.fn_GenerateSlug(N'Gigabyte GeForce RTX 4080 Super Windforce 16GB'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 66)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (66, 1, 1, 'VGA-NV-4090FE', N'NVIDIA GeForce RTX 4090 Founders Edition 24GB', 48900000, 0, 50, N'The ultimate GeForce GPU | 24GB G6X', 1, 36, dbo.fn_GenerateSlug(N'NVIDIA GeForce RTX 4090 Founders Edition 24GB'));

-- Mainboards (Category 3)
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 67)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (67, 3, 2, 'MB-MSI-H610', N'MSI PRO H610M-E DDR4', 2200000, 0, 100, N'Intel LGA1700 | Micro-ATX | DDR4', 1, 36, dbo.fn_GenerateSlug(N'MSI PRO H610M-E DDR4'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 68)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (68, 3, 3, 'MB-GIGA-B550', N'Gigabyte B550M AORUS ELITE', 3800000, 0, 100, N'AMD AM4 | Micro-ATX | DDR4', 1, 36, dbo.fn_GenerateSlug(N'Gigabyte B550M AORUS ELITE'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 69)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (69, 3, 1, 'MB-ASUS-Z790F', N'ASUS ROG Strix Z790-F', 8500000, 0, 100, N'Intel LGA1700 | ATX | DDR5', 1, 36, dbo.fn_GenerateSlug(N'ASUS ROG Strix Z790-F'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 70)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (70, 3, 2, 'MB-MSI-B650', N'MSI PRO B650M-A WIFI', 3000000, 0, 100, N'AMD AM5 | Micro-ATX | DDR5', 1, 36, dbo.fn_GenerateSlug(N'MSI PRO B650M-A WIFI'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 71)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (71, 3, 2, 'MB-MSI-Z790', N'MSI MAG Z790 Tomahawk', 6000000, 0, 100, N'Intel LGA1700 | ATX | DDR5', 1, 36, dbo.fn_GenerateSlug(N'MSI MAG Z790 Tomahawk'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 72)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (72, 3, 3, 'MB-GIGA-X670', N'Gigabyte X670 Gaming X', 6000000, 0, 100, N'AMD AM5 | ATX | DDR5', 1, 36, dbo.fn_GenerateSlug(N'Gigabyte X670 Gaming X'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 73)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (73, 3, 1, 'MB-ASUS-Z790F-WIFI', N'ASUS ROG Strix Z790-F Gaming Wifi', 9200000, 0, 100, N'Premium Intel Board | AURA Sync', 1, 36, dbo.fn_GenerateSlug(N'ASUS ROG Strix Z790-F Gaming Wifi'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 74)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (74, 3, 2, 'MB-MSI-B650-TOMAHAWK', N'MSI MAG B650 Tomahawk Wi-Fi', 5500000, 0, 100, N'AM5 Gaming mainboard | DDR5', 1, 36, dbo.fn_GenerateSlug(N'MSI MAG B650 Tomahawk Wi-Fi'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 75)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (75, 3, 3, 'MB-GIGA-Z790-AORUS', N'Gigabyte Z790 AORUS Elite AX', 6800000, 0, 100, N'LGA1700 Aorus Elite | DDR5', 1, 36, dbo.fn_GenerateSlug(N'Gigabyte Z790 AORUS Elite AX'));

-- RAMs (Category 4)
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 76)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (76, 4, 4, 'RAM-CORSAIR-16', N'16GB RAM DDR4', 1500000, 0, 200, N'Corsair Vengeance 16GB DDR4 3200MHz', 1, 36, dbo.fn_GenerateSlug(N'16GB RAM DDR4'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 77)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (77, 4, 4, 'RAM-CORSAIR-32', N'32GB RAM DDR4', 3000000, 0, 200, N'Corsair Vengeance 32GB DDR4 3600MHz', 1, 36, dbo.fn_GenerateSlug(N'32GB RAM DDR4'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 78)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (78, 4, 4, 'RAM-CORSAIR-64', N'64GB DDR5 RAM', 6000000, 0, 100, N'Corsair Vengeance RGB 64GB DDR5 5600MHz', 1, 36, dbo.fn_GenerateSlug(N'64GB DDR5 RAM'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 79)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (79, 4, 4, 'RAM-CORSAIR-32-D5', N'32GB DDR5', 3000000, 0, 200, N'Corsair Vengeance 32GB DDR5 5600MHz', 1, 36, dbo.fn_GenerateSlug(N'32GB DDR5'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 80)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (80, 4, 4, 'RAM-CORSAIR-VENGEANCE-D5', N'Corsair Vengeance RGB 32GB (2x16GB) 6000MHz', 3200000, 0, 200, N'Dual Channel DDR5 6000MHz | CL36', 1, 36, dbo.fn_GenerateSlug(N'Corsair Vengeance RGB 32GB (2x16GB) 6000MHz'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 81)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (81, 4, 9, 'RAM-GSKILL-TRIDENTZ-D5', N'G.Skill Trident Z5 Neo RGB 32GB (2x16GB) 6000MHz', 3500000, 0, 200, N'Trident Z5 Neo RGB | AMD Expo CL30', 1, 36, dbo.fn_GenerateSlug(N'G.Skill Trident Z5 Neo RGB 32GB (2x16GB) 6000MHz'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 82)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (82, 4, 12, 'RAM-KINGSTON-BEAST-D5', N'Kingston FURY Beast 16GB (2x8GB) 5200MHz', 1600000, 0, 200, N'Fury Beast DDR5 Dual Kit | CL40', 1, 36, dbo.fn_GenerateSlug(N'Kingston FURY Beast 16GB (2x8GB) 5200MHz'));

-- PSUs (Category 6)
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 83)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (83, 6, 8, 'PSU-DEEPCOOL-650', N'Deepcool PF650 650W', 1500000, 0, 150, N'650W Power Supply | 80 Plus Standard', 1, 36, dbo.fn_GenerateSlug(N'Deepcool PF650 650W'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 84)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (84, 6, 4, 'PSU-CORSAIR-750', N'Corsair CV750 750W', 2500000, 0, 150, N'750W Power Supply | 80 Plus Bronze', 1, 36, dbo.fn_GenerateSlug(N'Corsair CV750 750W'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 85)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (85, 6, 4, 'PSU-CORSAIR-1000', N'Corsair RM1000x 1000W', 4500000, 0, 100, N'1000W Power Supply | 80 Plus Gold Full Modular', 1, 36, dbo.fn_GenerateSlug(N'Corsair RM1000x 1000W'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 86)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (86, 6, 4, 'PSU-CORSAIR-850', N'Corsair RM850x 850W', 3600000, 0, 150, N'850W Gold Rated Full Modular PSU', 1, 36, dbo.fn_GenerateSlug(N'Corsair RM850x 850W'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 87)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (87, 6, 2, 'PSU-MSI-A750GL', N'MSI MAG A750GL 750W', 2400000, 0, 150, N'750W Gold PSU | ATX 3.0 PCIe 5.0 Ready', 1, 36, dbo.fn_GenerateSlug(N'MSI MAG A750GL 750W'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 88)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (88, 6, 1, 'PSU-ASUS-THOR-1000', N'ASUS ROG Thor 1000W Platinum II', 8900000, 0, 50, N'1000W Platinum Rating | OLED Screen Live Wattage', 1, 60, dbo.fn_GenerateSlug(N'ASUS ROG Thor 1000W Platinum II'));

-- Cases (Category 8)
IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 89)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (89, 8, 8, 'CASE-XIGMATEK-NYX', N'Xigmatek NYX Premium', 1800000, 0, 100, N'Mid Tower Glass Case | 3 Fan RGB Pre-installed', 1, 12, dbo.fn_GenerateSlug(N'Xigmatek NYX Premium'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 90)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (90, 8, 11, 'CASE-NZXT-H5FLOW', N'NZXT H5 Flow', 3200000, 0, 100, N'Premium Airflow Case | Matte Black', 1, 24, dbo.fn_GenerateSlug(N'NZXT H5 Flow'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 91)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (91, 8, 10, 'CASE-LIANLI-O11D', N'Lian Li O11 Dynamic EVO', 4500000, 0, 100, N'Dual Chamber Tempered Glass Case', 1, 12, dbo.fn_GenerateSlug(N'Lian Li O11 Dynamic EVO'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 92)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (92, 8, 11, 'CASE-NZXT-H9FLOW', N'NZXT H9 Flow Matte White', 3800000, 0, 100, N'Matte White Panoramic Dual Chamber Case', 1, 24, dbo.fn_GenerateSlug(N'NZXT H9 Flow Matte White'));

IF NOT EXISTS (SELECT 1 FROM dbo.Products WHERE ProductID = 93)
    INSERT INTO dbo.Products (ProductID, CategoryID, BrandID, SKU, ProductName, Price, DiscountPrice, StockQuantity, Description, IsActive, WarrantyMonths, Slug)
    VALUES (93, 8, 4, 'CASE-CORSAIR-4000D', N'Corsair 4000D Airflow Tempered Glass', 2200000, 0, 100, N'Minimalist Black Airflow Case', 1, 24, dbo.fn_GenerateSlug(N'Corsair 4000D Airflow Tempered Glass'));

SET IDENTITY_INSERT dbo.Products OFF;

-- 4. Insert Default Images
-- Gaming Gear
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 41)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (41, 'https://cdn.shopify.com/s/files/1/0268/7342/1898/products/GProXSuperlight_Black_1024x1024.png', 'CORE M-PRO', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 42)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (42, 'https://assets.corsair.com/image/upload/c_pad,q_auto,h_1024,w_1024,f_auto/products/Keyboards/K70_RGB_PRO_PBT/CH-9109410-NA/Gallery/K70_RGB_PRO_PBT_01.png', 'CORE K-ELITE', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 43)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (43, 'https://cdn.shopify.com/s/files/1/0556/2643/2691/products/hyperx_cloud_ii_wireless_1_1024x1024.png', 'CORE H-SOUND', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 44)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (44, 'https://cdn.shopify.com/s/files/1/0073/3288/8687/products/Yeti-Black-Front_1024x1024.png', 'CORE STUDIO', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 45)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (45, 'https://compass-ssl.xbox.com/assets/80/75/807530ce-2e8f-4d32-8ea7-a3aa7ccb68fc.png?n=Elite-Series-2_Gallery_1084x794_02.png', 'CORE G-CMD', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 46)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (46, 'https://assets.corsair.com/image/upload/c_pad,q_auto,h_1024,w_1024,f_auto/products/Mousepads/MM700_RGB_Extended/Gallery/MM700_RGB_EXTENDED_01.png', 'CORE PAD PRO', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 47)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (47, 'https://assets.corsair.com/image/upload/c_pad,q_auto,h_1024,w_1024,f_auto/products/Accessories/ST100/Gallery/ST100_01.png', 'CORE BASE RGB', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 48)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (48, 'https://resource.logitechg.com/w_692,c_limit,q_auto,f_auto,dpr_1.0/d_transparent.gif/content/dam/gaming/en/products/g923-and-trueforce/g923-gallery-1.png?v=1', 'CORE WHEEL', 0, 1);

-- Cases
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 89)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (89, 'https://placehold.co/300x300/0f172a/7dd3fc?text=Xigmatek+NYX', 'Xigmatek NYX Premium', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 90)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (90, 'https://placehold.co/300x300/0f172a/7dd3fc?text=NZXT+H5+Flow', 'NZXT H5 Flow', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 91)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (91, 'https://placehold.co/300x300/0f172a/7dd3fc?text=Lian+Li+O11', 'Lian Li O11 Dynamic EVO', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 92)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (92, 'https://placehold.co/300x300/0f172a/7dd3fc?text=NZXT+H9+Flow', 'NZXT H9 Flow Matte White', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 93)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (93, 'https://placehold.co/300x300/0f172a/7dd3fc?text=Corsair+4000D', 'Corsair 4000D Airflow Tempered Glass', 0, 1);

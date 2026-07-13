-- Seed Product Images for PC Build components (Product IDs 49 to 88)
-- Category 2 (CPUs)
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 49)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (49, 'https://placehold.co/300x300/111827/ffffff?text=Intel+i5-12400F', 'Intel Core i5-12400F', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 50)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (50, 'https://placehold.co/300x300/111827/ffffff?text=Ryzen+7+5700X', 'AMD Ryzen 7 5700X', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 51)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (51, 'https://placehold.co/300x300/111827/ffffff?text=Ryzen+5+7600X', 'AMD Ryzen 5 7600X', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 52)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (52, 'https://placehold.co/300x300/111827/ffffff?text=Intel+i7-14700K', 'Intel Core i7-14700K', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 53)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (53, 'https://placehold.co/300x300/111827/ffffff?text=Ryzen+9+7900X', 'AMD Ryzen 9 7900X', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 54)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (54, 'https://placehold.co/300x300/111827/ffffff?text=Intel+i5-13600K', 'Intel Core i5-13600K', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 55)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (55, 'https://placehold.co/300x300/111827/ffffff?text=Ryzen+7+7700X', 'AMD Ryzen 7 7700X', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 56)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (56, 'https://placehold.co/300x300/111827/ffffff?text=Intel+i9-14900K', 'Intel Core i9-14900K', 0, 1);

-- Category 1 (VGAs)
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 57)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (57, 'https://placehold.co/300x300/111827/ffffff?text=RTX+3060+12GB', 'RTX 3060 12GB', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 58)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (58, 'https://placehold.co/300x300/111827/ffffff?text=RTX+4060+8GB', 'RTX 4060 8GB', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 59)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (59, 'https://placehold.co/300x300/111827/ffffff?text=RTX+4070+Super', 'RTX 4070 Super 12GB', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 60)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (60, 'https://placehold.co/300x300/111827/ffffff?text=RTX+4070Ti+Super', 'RTX 4070 Ti Super 16GB', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 61)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (61, 'https://placehold.co/300x300/111827/ffffff?text=RX+7600+8GB', 'RX 7600 8GB', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 62)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (62, 'https://placehold.co/300x300/111827/ffffff?text=RX+7800+XT', 'RX 7800 XT 16GB', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 63)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (63, 'https://placehold.co/300x300/111827/ffffff?text=RX+7900+XTX', 'RX 7900 XTX 24GB', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 64)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (64, 'https://placehold.co/300x300/111827/ffffff?text=RTX+4060Ti+8GB', 'RTX 4060 Ti 8GB', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 65)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (65, 'https://placehold.co/300x300/111827/ffffff?text=RTX+4080+Super', 'Gigabyte GeForce RTX 4080 Super Windforce 16GB', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 66)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (66, 'https://placehold.co/300x300/111827/ffffff?text=RTX+4090+FE', 'NVIDIA GeForce RTX 4090 Founders Edition 24GB', 0, 1);

-- Category 3 (Mainboards)
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 67)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (67, 'https://placehold.co/300x300/111827/ffffff?text=MSI+H610M-E', 'MSI PRO H610M-E DDR4', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 68)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (68, 'https://placehold.co/300x300/111827/ffffff?text=Giga+B550M', 'Gigabyte B550M AORUS ELITE', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 69)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (69, 'https://placehold.co/300x300/111827/ffffff?text=ASUS+Z790-F', 'ASUS ROG Strix Z790-F', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 70)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (70, 'https://placehold.co/300x300/111827/ffffff?text=MSI+B650M-A', 'MSI PRO B650M-A WIFI', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 71)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (71, 'https://placehold.co/300x300/111827/ffffff?text=MSI+Z790+Tomahawk', 'MSI MAG Z790 Tomahawk', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 72)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (72, 'https://placehold.co/300x300/111827/ffffff?text=Giga+X670', 'Gigabyte X670 Gaming X', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 73)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (73, 'https://placehold.co/300x300/111827/ffffff?text=ASUS+Z790-F+Wifi', 'ASUS ROG Strix Z790-F Gaming Wifi', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 74)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (74, 'https://placehold.co/300x300/111827/ffffff?text=MSI+B650+Tomahawk', 'MSI MAG B650 Tomahawk Wi-Fi', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 75)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (75, 'https://placehold.co/300x300/111827/ffffff?text=Giga+Z790+AORUS', 'Gigabyte Z790 AORUS Elite AX', 0, 1);

-- Category 4 (RAMs)
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 76)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (76, 'https://placehold.co/300x300/111827/ffffff?text=16GB+RAM+DDR4', '16GB RAM DDR4', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 77)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (77, 'https://placehold.co/300x300/111827/ffffff?text=32GB+RAM+DDR4', '32GB RAM DDR4', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 78)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (78, 'https://placehold.co/300x300/111827/ffffff?text=64GB+DDR5+RAM', '64GB DDR5 RAM', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 79)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (79, 'https://placehold.co/300x300/111827/ffffff?text=32GB+DDR5', '32GB DDR5', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 80)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (80, 'https://placehold.co/300x300/111827/ffffff?text=Corsair+32GB+6000', 'Corsair Vengeance RGB 32GB (2x16GB) 6000MHz', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 81)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (81, 'https://placehold.co/300x300/111827/ffffff?text=TridentZ5+32GB', 'G.Skill Trident Z5 Neo RGB 32GB (2x16GB) 6000MHz', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 82)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (82, 'https://placehold.co/300x300/111827/ffffff?text=Kingston+16GB', 'Kingston FURY Beast 16GB (2x8GB) 5200MHz', 0, 1);

-- Category 6 (PSUs)
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 83)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (83, 'https://placehold.co/300x300/111827/ffffff?text=Deepcool+650W', 'Deepcool PF650 650W', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 84)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (84, 'https://placehold.co/300x300/111827/ffffff?text=Corsair+750W', 'Corsair CV750 750W', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 85)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (85, 'https://placehold.co/300x300/111827/ffffff?text=Corsair+1000W', 'Corsair RM1000x 1000W', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 86)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (86, 'https://placehold.co/300x300/111827/ffffff?text=Corsair+850W', 'Corsair RM850x 850W', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 87)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (87, 'https://placehold.co/300x300/111827/ffffff?text=MSI+A750GL', 'MSI MAG A750GL 750W', 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.ProductImages WHERE ProductID = 88)
    INSERT INTO dbo.ProductImages (ProductID, ImageURL, AltText, SortOrder, IsDefault) VALUES (88, 'https://placehold.co/300x300/111827/ffffff?text=ASUS+Thor+1000W', 'ASUS ROG Thor 1000W Platinum II', 0, 1);

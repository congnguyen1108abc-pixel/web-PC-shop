-- Fix category names
UPDATE Categories SET CategoryName = N'VGA / Card Đồ Họa' WHERE CategoryID = 1;
UPDATE Categories SET CategoryName = N'CPU / Bộ Vi Xử Lý' WHERE CategoryID = 2;
UPDATE Categories SET CategoryName = N'SSD / Ổ Cứng' WHERE CategoryID = 5;
UPDATE Categories SET CategoryName = N'Nguồn / PSU' WHERE CategoryID = 6;
UPDATE Categories SET CategoryName = N'Vỏ máy tính (Case)' WHERE CategoryID = 8;
UPDATE Categories SET CategoryName = N'Tản nhiệt PC' WHERE CategoryID = 9;

-- Fix product descriptions
UPDATE Products SET Description = N'Card đồ họa ASUS RTX 3060 dùng test' WHERE ProductID = 21;
UPDATE Products SET Description = N'Card đồ họa MSI RTX 4060 dùng test' WHERE ProductID = 22;
UPDATE Products SET Description = N'CPU Intel Core i5 phiên bản test' WHERE ProductID = 23;
UPDATE Products SET Description = N'CPU AMD Ryzen 5 phiên bản test' WHERE ProductID = 24;
UPDATE Products SET Description = N'Nguồn Corsair 650W test' WHERE ProductID = 30;
UPDATE Products SET Description = N'Card đồ họa ASUS RTX 4070 phiên bản demo' WHERE ProductID = 31;
UPDATE Products SET Description = N'Card đồ họa MSI RTX 4060 Ti demo' WHERE ProductID = 32;
UPDATE Products SET Description = N'CPU Intel Core i7 phiên bản demo' WHERE ProductID = 33;
UPDATE Products SET Description = N'CPU AMD Ryzen 7 phiên bản demo' WHERE ProductID = 34;
UPDATE Products SET Description = N'Nguồn Corsair 750W demo' WHERE ProductID = 40;

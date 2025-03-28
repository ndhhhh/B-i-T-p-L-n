--1. Xóa & Tạo mới Database

USE master;
GO

-- Kiểm tra & xóa database cũ nếu tồn tại
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'QuanLyDangKyChuyenDe')
BEGIN
    ALTER DATABASE QuanLyDangKyChuyenDe SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE QuanLyDangKyChuyenDe;
END;
GO

-- Tạo mới database
CREATE DATABASE QuanLyDangKyChuyenDe;
GO

-- Chọn database để sử dụng
USE QuanLyDangKyChuyenDe;
GO



--2. Tạo Bảng

-- Bảng Ngành học
CREATE TABLE NganhHoc (
    MaNganh INT PRIMARY KEY IDENTITY(1,1),
    TenNganh NVARCHAR(100) UNIQUE NOT NULL,
    SoChuyenDePhaiHoc INT CHECK (SoChuyenDePhaiHoc > 0),
    TongSoSinhVien INT DEFAULT 0
);

-- Bảng Sinh viên
CREATE TABLE SinhVien (
    MaSV INT PRIMARY KEY IDENTITY(1001,1),
    HoTen NVARCHAR(100) NOT NULL,
    GioiTinh NVARCHAR(10) CHECK (GioiTinh IN ('Nam', 'Nữ')),
    NgaySinh DATE CHECK (NgaySinh <= GETDATE()),
    DiaChi NVARCHAR(100),
    MaNganh INT NOT NULL,
    FOREIGN KEY (MaNganh) REFERENCES NganhHoc(MaNganh) ON DELETE CASCADE
);

-- Bảng Chuyên đề
CREATE TABLE ChuyenDe (
    MaCD INT PRIMARY KEY IDENTITY(101,1),
    TenCD NVARCHAR(100) UNIQUE NOT NULL,
    SoSVMoiLop INT CHECK (SoSVMoiLop > 0)
);

-- Bảng Học kỳ
CREATE TABLE HocKy (
    MaHK INT PRIMARY KEY IDENTITY(20241,1),
    NamHoc INT CHECK (NamHoc >= 2000),
    Ky INT CHECK (Ky IN (1,2))
);

-- Bảng Mở chuyên đề theo học kỳ
CREATE TABLE ChuyenDe_HocKy (
    MaCD INT,
    MaHK INT,
    PRIMARY KEY (MaCD, MaHK),
    FOREIGN KEY (MaCD) REFERENCES ChuyenDe(MaCD) ON DELETE CASCADE,
    FOREIGN KEY (MaHK) REFERENCES HocKy(MaHK) ON DELETE CASCADE
);

-- Bảng Đăng ký học
CREATE TABLE DangKy (
    MaSV INT,
    MaCD INT,
    MaHK INT,
    PRIMARY KEY (MaSV, MaCD, MaHK),
    FOREIGN KEY (MaSV) REFERENCES SinhVien(MaSV) ON DELETE CASCADE,
    FOREIGN KEY (MaCD) REFERENCES ChuyenDe(MaCD) ON DELETE CASCADE,
    FOREIGN KEY (MaHK) REFERENCES HocKy(MaHK) ON DELETE CASCADE
);



--3. Thêm Dữ Liệu Mẫu

-- Thêm ngành học
INSERT INTO NganhHoc (TenNganh, SoChuyenDePhaiHoc) VALUES 
('Cong nghe thong tin', 6),
('Ky thuat phan mem', 5),
('He thong thong tin', 5),
('Khoa hoc du lieu', 6),
('An toan thong tin', 4),
('Tri tue nhan tao', 6);

-- Thêm sinh viên
INSERT INTO SinhVien (HoTen, GioiTinh, NgaySinh, DiaChi, MaNganh) VALUES 
('Vu Son Hai', 'Nam', '2002-01-31', 'Ha Noi', 1),
('Nguyen Duy Hung', 'Nam', '2003-08-12', 'Thai Nguyen', 1),
('Ha tuan Anh', 'Nam', '2001-09-10', 'Đa Nang', 2),
('Le Minh Tu', 'Nam', '2002-05-15', 'Ha Noi', 1),
('Pham Thanh Huong', 'Nữ', '2001-07-21', 'Ho Chi Minh', 2),
('Nguyen Van An', 'Nam', '2003-03-10', 'Đa Nang', 3),
('Tran Thi Mai', 'Nữ', '2004-09-25', 'Can Tho', 4),
('Đo Đuc Binh', 'Nam', '2000-12-30', 'Hue', 5);

-- Thêm chuyên đề
INSERT INTO ChuyenDe (TenCD, SoSVMoiLop) VALUES 
('Lap trinh Java', 50),
('Co so du lieu nang cao', 40),
('Phat trien Web', 30),
('Lap trinh Python', 40),
('Lap trinh C++', 35),
('Phan tich du lieu', 30);

-- Thêm học kỳ
INSERT INTO HocKy (NamHoc, Ky) VALUES 
(2024, 1),
(2024, 2);

-- Thêm chuyên đề vào học kỳ
INSERT INTO ChuyenDe_HocKy (MaCD, MaHK) VALUES 
(101, 20241),
(102, 20241),
(103, 20242),
(104, 20241),
(105, 20242),
(106, 20242);


-- Đăng ký học
INSERT INTO DangKy (MaSV, MaCD, MaHK) VALUES 
('1001', '101', '20241'),
('1002', '102', '20241'),
('1003', '103', '20242'),
('1004', '105', '20242'),
('1005', '106', '20242'),
('1006', '102', '20241'),
('1007', '104', '20241'),
('1008', '106', '20242');


--4. Tạo View (Báo cáo tổng hợp)

CREATE VIEW V_DanhSachDangKy AS
SELECT SV.MaSV, SV.HoTen, CD.TenCD, HK.NamHoc, HK.Ky
FROM DangKy DK
JOIN SinhVien SV ON DK.MaSV = SV.MaSV
JOIN ChuyenDe CD ON DK.MaCD = CD.MaCD
JOIN HocKy HK ON DK.MaHK = HK.MaHK;


--5. Stored Procedure (Thêm đăng ký học)

CREATE PROCEDURE sp_DangKyChuyenDe
    @MaSV INT, @MaCD INT, @MaHK INT
AS
BEGIN
    -- Kiểm tra số lượng chuyên đề đã đăng ký trong học kỳ
    IF (SELECT COUNT(*) FROM DangKy WHERE MaSV = @MaSV AND MaHK = @MaHK) >= 3
    BEGIN
        RAISERROR ('Sinh viên đã đăng ký tối đa 3 chuyên đề!', 16, 1);
        RETURN;
    END

    -- Kiểm tra số lượng sinh viên tối đa trong chuyên đề
    IF (SELECT COUNT(*) FROM DangKy WHERE MaCD = @MaCD) >= 
       (SELECT SoSVMoiLop FROM ChuyenDe WHERE MaCD = @MaCD)
    BEGIN
        RAISERROR ('Chuyên đề đã đủ số lượng sinh viên!', 16, 1);
        RETURN;
    END

    -- Kiểm tra nếu bản ghi đã tồn tại
    IF EXISTS (SELECT 1 FROM DangKy WHERE MaSV = @MaSV AND MaCD = @MaCD AND MaHK = @MaHK)
    BEGIN
        RAISERROR ('Sinh viên đã đăng ký chuyên đề này trong học kỳ!', 16, 1);
        RETURN;
    END

    -- Nếu hợp lệ, thêm đăng ký
    INSERT INTO DangKy VALUES (@MaSV, @MaCD, @MaHK);
    PRINT 'Đăng ký thành công!';
END;

--6. Trigger Kiểm Tra Số Lượng SV

CREATE TRIGGER trg_KiemTraSoLuongSV
ON DangKy
AFTER INSERT
AS
BEGIN
    IF (SELECT COUNT(*) FROM DangKy WHERE MaCD = (SELECT MaCD FROM inserted)) > 
       (SELECT SoSVMoiLop FROM ChuyenDe WHERE MaCD = (SELECT MaCD FROM inserted))
    BEGIN
        PRINT 'Số lượng sinh viên đăng ký vượt quá giới hạn!';
        ROLLBACK;
    END
END;


--7.  Tạo User & Phân quyền

-- Tạo user sinh viên
CREATE LOGIN user_sv WITH PASSWORD = 'Password123';
CREATE USER user_sv FOR LOGIN user_sv;

-- Chỉ cho phép sinh viên xem danh sách chuyên đề
GRANT SELECT ON ChuyenDe TO user_sv;
-- Cấp quyền đọc, ghi và cập nhật trên bảng DangKy
GRANT SELECT, INSERT, UPDATE ON DangKy TO user_sv;

--8. Kiểm tra dữ liệu đã nhập

SELECT * FROM SinhVien;
SELECT * FROM ChuyenDe;
SELECT * FROM HocKy;
SELECT * FROM DangKy;
SELECT * FROM V_DanhSachDangKy;

--9. function

CREATE FUNCTION fn_DemSoChuyenDe (@MaSV INT)
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM DangKy WHERE MaSV = @MaSV);
END;
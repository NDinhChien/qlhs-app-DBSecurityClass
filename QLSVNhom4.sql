create database QLSVNhom4 
GO
use QLSVNhom4 
GO
-- NHANVIEN
create table NHANVIEN (
  MANV varchar(20) not null,
  HOTEN nvarchar(100) not null,
  EMAIL varchar(100) unique,
  LUONG varbinary(max),
  TENDN nvarchar(100) not null unique,
  MATKHAU varbinary(max) not null,
  PUBKEY varchar(20)
)
GO
alter table NHANVIEN add
  constraint PK_NHANVIEN primary key (MANV)
GO
-- LOP
create table LOP (
  MALOP varchar(20) not null,
  TENLOP nvarchar(100) not null,
  MANV varchar(20)
)
GO
alter table LOP add
  constraint PK_LOP primary key (MALOP),
  constraint FK_LOP_NHANVIEN foreign key (MANV) references NHANVIEN(MANV)

-- SINHVIEN
GO
create table SINHVIEN (
  MASV varchar(20) not null,
  HOTEN nvarchar(100) not null,
  NGAYSINH datetime,
  DIACHI nvarchar(200),
  MALOP varchar(20),
  TENDN nvarchar(100) not null unique,
  MATKHAU varbinary(max) not null
)
GO
alter table SINHVIEN add
  constraint PK_SINHVIEN primary key (MASV),
  constraint FK_SINHVIEN_LOP foreign key (MALOP) references LOP(MALOP)

-- HOCPHAN
GO
create table HOCPHAN(
  MAHP varchar(20) not null,
  TENHP nvarchar(100) not null,
  SOTC int
)
GO
alter table HOCPHAN add 
  constraint PK_HOCPHAN primary key (MAHP)

-- BANGDIEM
GO
create table BANGDIEM(
  MASV varchar(20) not null,
  MAHP varchar(20) not null,
  DIEMTHI varbinary(max)
)
GO 
alter table BANGDIEM add 
  constraint PK_BANGDIEM primary key(MASV, MAHP),
  constraint FK_BANGDIEM_SINHVIEN foreign key (MASV) references SINHVIEN(MASV),
  constraint FK_BANGDIEM_HOCPHAN foreign key (MAHP) references HOCPHAN(MAHP)


-- Đăng nhập
GO
CREATE PROCEDURE SP_DangNhap
@TenDN nvarchar(100),
@MK nvarchar(30)
AS
BEGIN
  IF EXISTS (SELECT* FROM SINHVIEN WHERE TENDN=@TenDN AND MATKHAU = HASHBYTES('MD5', @MK))
    SELECT 0;
  ELSE IF EXISTS (SELECT* FROM NHANVIEN WHERE TENDN=@TenDN AND MATKHAU = HASHBYTES('SHA1', @MK))
    SELECT 1;
END
-- insert into NHANVIEN
-- trigger: after delete NHANVIEN
GO
CREATE TRIGGER TRG_AFTER_DEL_NHANVIEN
ON NHANVIEN AFTER DELETE
AS
BEGIN
  DECLARE @MaNV varchar(20);
  SET @MaNV = (SELECT MANV FROM deleted);
  IF EXISTS( SELECT *  FROM sys.asymmetric_keys WHERE name = @MaNV)
  EXEC('DROP ASYMMETRIC KEY ' + @MaNV +'')
END

-- insert into NHANVIEN
GO
CREATE PROCEDURE SP_INS_PUBLIC_NHANVIEN 
@MaNV varchar(20), 
@HoTen nvarchar(100),
@Email varchar(100),
@LuongCB int,
@TenDN nvarchar(100),
@MK nvarchar(30)
AS 
BEGIN 
  IF @LuongCB < 0 THROW 50005, N'Salary must be greater than 0.', 1;
  INSERT INTO NHANVIEN (MANV, HOTEN, EMAIL, TENDN, MATKHAU) VALUES
    (@MaNV, @HoTen, @Email, @TenDN, HASHBYTES('SHA1', @MK))
  
  DECLARE @q varchar(max);
  SET @q = 'CREATE ASYMMETRIC KEY ' + @MaNV
    +' WITH ALGORITHM = RSA_2048 ENCRYPTION BY PASSWORD = ''' + @MK +'''';
  EXEC(@q)
  
  SET @q = 'UPDATE NHANVIEN SET LUONG = EncryptByAsymKey( AsymKey_ID('''+@MaNV+'''), convert(varbinary, ''' + convert(varchar, @LuongCB) +''') ), PUBKEY = ''' + @MaNV +
  ''' WHERE MANV = ''' + @MaNV + '''';
  EXEC(@q)
END
--
GO
EXEC SP_INS_PUBLIC_NHANVIEN 'NV001', N'Huỳnh Hoàng Quỳnh Anh', 'quynhanhhuynh@gmail.com', 15000000, N'quynhanh3', N'ctl1wiw1d'
EXEC SP_INS_PUBLIC_NHANVIEN 'NV002', N'Phạm Thị Linh', 'thilinhpham@gmail.com', 15000000, N'thilinhv', N'kre054njze6i'
EXEC SP_INS_PUBLIC_NHANVIEN 'NV003', N'Trần Lê Vy', 'levytran@gmail.com', 20000000, N'levy7', N'zf2mhwej'
EXEC SP_INS_PUBLIC_NHANVIEN 'NV004', N'Trương Trung Bảo', 'trungbaotruong@gmail.com', 10000000, N'trungbao6', N'hc4gcwodcv'
EXEC SP_INS_PUBLIC_NHANVIEN 'NV005', N'Phạm Kim Thanh Linh', 'thanhlinhpham@gmail.com', 25000000, N'thanhlinh1', N'7aoymrvdtsp'

-- select * from NHANVIEN
GO
CREATE PROCEDURE SP_SEL_PUBLIC_NHANVIEN
@TenDN nvarchar(100),
@MK nvarchar(30)
AS 
BEGIN 
  SELECT MANV, HOTEN, EMAIL, convert(varchar, DecryptByAsymKey(AsymKey_Id(MANV), LUONG, @MK)) AS LUONGCB
  FROM NHANVIEN 
  WHERE TENDN=@TenDN AND MATKHAU= HASHBYTES('SHA1', @MK);
END
--EXEC SP_SEL_PUBLIC_NHANVIEN N'thilinhv', N'kre054njze6i'
--EXEC SP_SEL_PUBLIC_NHANVIEN N'quynhanh3', N'ctl1wiw1d'

-- insert into LOP
GO
insert into LOP values
('LP001', N'20CTT1', 'NV001'),
('LP002', N'20CTT2', 'NV002'),
('LP003', N'20CTT3', 'NV003'),
('LP004', N'20CTT4', 'NV004'),
('LP005', N'20CTT5', 'NV005')

-- insert into HOCPHAN
GO
INSERT INTO HOCPHAN VALUES
('CSC10004', N'Cấu trúc dữ liệu và Giải thuật', 4),
('CSC10006', N'Cơ sở dữ liệu', 4),
('CSC13002', N'Nhập môn Công nghệ phần mềm', 4),
('CSC14003', N'Cơ sở Trí tuệ nhân tạo', 4),
('CSC10003', N'Phương pháp lập trình Hướng đối tượng', 4)

-- insert into BANGDIEM
GO
CREATE PROCEDURE SP_INS_BANGDIEM
@MaSV varchar(20),
@MaHP varchar(20)
AS
BEGIN
  INSERT INTO BANGDIEM (MASV, MAHP) VALUES (@MaSV, @MaHP);
END
GO
-- trigger: after insert into BANGDIEM
GO
CREATE TRIGGER TRG_AFTER_INS_SINHVIEN
ON SINHVIEN AFTER INSERT
AS
BEGIN
    DECLARE @MaSV varchar(20);
	SET @MaSV = (SELECT MASV FROM inserted);
	DECLARE @q varchar(max);
	SET @q = '';
	SELECT @q = @q + 'EXEC SP_INS_BANGDIEM ''' + @MaSV+''', ''' + HP.MAHP + '''; '
	FROM (SELECT MAHP FROM HOCPHAN) AS HP
    EXEC (@q);
END
-- select * FROM BANGDIEM
-- select * FROM SINHVIEN

-- trigger: after delete form BANGDIEM
GO
CREATE TRIGGER TRG_AFTER_DEL_SINHVIEN
ON SINHVIEN AFTER INSERT
AS
BEGIN
	DELETE FROM BANGDIEM 
	WHERE MASV IN (SELECT MASV FROM deleted) 
END

-- SINHVIEN xem thong tin, thay doi mat khau
GO
CREATE PROCEDURE SP_SINHVIEN_INFO
@TenDN nvarchar(100),
@MK nvarchar(30)
AS 
BEGIN
  SELECT * FROM SINHVIEN WHERE TENDN=@TenDN AND MATKHAU = HASHBYTES('MD5', @MK);
END
-- EXEC SP_SINHVIEN_INFO N'quochuyp', N'mypassword'
-- SINHVIEN Doi MK
GO
CREATE PROCEDURE SP_DOI_MK 
@TenDN nvarchar(100),
@OldMK nvarchar(30),
@NewMK nvarchar(30)
AS
BEGIN
 UPDATE SINHVIEN SET MATKHAU = HASHBYTES('MD5', @NewMK) WHERE TENDN=@TenDN AND MATKHAU = HASHBYTES('MD5', @OldMK);
END
-- EXEC SP_DOI_MK N'quochuyp', N'shtsedvnrenu', N'mypassword'

-- insert into SINHVIEN 
GO
CREATE PROCEDURE SP_INS_SINHVIEN 
@MaSV varchar(20), @HoTen nvarchar(100), @NgaySinh datetime, @DiaChi nvarchar(200), @MaLop varchar(20), @TenDN nvarchar(100), @MatKhau nvarchar(30) 
AS 
BEGIN 
	insert into SINHVIEN VALUES 
	(@MaSV, @HoTen, @NgaySinh, @DiaChi, @MaLop, @TenDN, HASHBYTES('MD5', @MatKhau))  
END 

-- insert into SINHVIEN 
GO
EXEC SP_INS_SINHVIEN 'SV001', N'Trần Kim Quỳnh Thư', '2002-7-2', N'Bắc Kạn', 'LP001', N'quynhthux', N'8w7pb8dzje'
EXEC SP_INS_SINHVIEN 'SV002', N'Trần Hoàng Gia Phương', '2002-11-11', N'Hải Dương', 'LP001', N'giaphuong8', N'76df5iuy'
EXEC SP_INS_SINHVIEN 'SV003', N'Lê Ngọc Kim Vy', '2002-9-27', N'Bến Tre', 'LP001', N'kimvyu', N'o8vbykw6e'
EXEC SP_INS_SINHVIEN 'SV004', N'Lê Quỳnh Thùy Nhi', '2002-1-12', N'Bắc Kạn', 'LP001', N'thuynhi8', N'53zxld5lqk'
EXEC SP_INS_SINHVIEN 'SV005', N'Nguyễn Minh Vy', '2002-3-27', N'Hà Nội', 'LP001', N'minhvym', N'uubm2yxsndv'
EXEC SP_INS_SINHVIEN 'SV006', N'Lê Huỳnh Anh', '2002-11-2', N'Hà Giang', 'LP001', N'huynhanhr', N's2gpg455xlje'
EXEC SP_INS_SINHVIEN 'SV007', N'Bùi Đức Anh', '2002-1-17', N'Bà Rịa – Vũng Tàu', 'LP001', N'ducanhh', N'mv84ahgqqi'
EXEC SP_INS_SINHVIEN 'SV008', N'Vũ Thành Huy', '2002-6-26', N'Bắc Kạn', 'LP001', N'thanhhuyt', N'vd2e27u72w'
EXEC SP_INS_SINHVIEN 'SV009', N'Phan Tấn Khoa', '2002-12-13', N'Bình Thuận', 'LP001', N'tankhoa8', N'4s1jhgn6fsro'
EXEC SP_INS_SINHVIEN 'SV010', N'Trương Tuấn Phát', '2002-10-9', N'Bình Phước', 'LP001', N'tuanphat2', N'welksbfjop'
EXEC SP_INS_SINHVIEN 'SV011', N'Trần Quỳnh Ngọc Trân', '2002-12-27', N'Đồng Nai', 'LP001', N'ngoctrant', N'nlqgn9mup'
EXEC SP_INS_SINHVIEN 'SV012', N'Nguyễn Tuấn Khoa', '2002-4-25', N'Hải Dương', 'LP001', N'tuankhoau', N'xbp4wnugmsd'
EXEC SP_INS_SINHVIEN 'SV013', N'Đặng Bảo Thùy Ngân', '2002-11-12', N'Hòa Bình', 'LP001', N'thuynganh', N'twtcwsbme'
EXEC SP_INS_SINHVIEN 'SV014', N'Hoàng Tuấn Đạt', '2002-12-8', N'Cần Thơ', 'LP001', N'tuandatp', N's2js7usdeln'
EXEC SP_INS_SINHVIEN 'SV015', N'Huỳnh Quỳnh Ngân', '2002-4-28', N'Hà Nam', 'LP001', N'quynhnganv', N'ogy8i7obb'
EXEC SP_INS_SINHVIEN 'SV016', N'Nguyễn Đăng Kiệt', '2002-12-4', N'Đắk Nông', 'LP001', N'dangkietr', N'ujibneegl7'
EXEC SP_INS_SINHVIEN 'SV017', N'Võ Quốc Phát', '2002-2-3', N'Đà Nẵng', 'LP001', N'quocphaty', N'tvamte4v0cnf'
EXEC SP_INS_SINHVIEN 'SV018', N'Nguyễn Tuấn Phát', '2002-3-16', N'Hải Dương', 'LP001', N'tuanphat5', N'oykwjlngwwp'
EXEC SP_INS_SINHVIEN 'SV019', N'Phan Đăng Huy', '2002-10-26', N'Bình Định', 'LP001', N'danghuyf', N'948q8vgldab'
EXEC SP_INS_SINHVIEN 'SV020', N'Lê Trung Khoa', '2002-3-26', N'Bình Phước', 'LP001', N'trungkhoak', N'ejvpggdj3sq'
EXEC SP_INS_SINHVIEN 'SV021', N'Huỳnh Thành Duy', '2002-12-22', N'Điện Biên', 'LP0002', N'thanhduy2', N'e5gjqsez'
EXEC SP_INS_SINHVIEN 'SV022', N'Trần Tấn Quân', '2002-7-4', N'Điện Biên', 'LP0002', N'tanquan3', N'qlbfwqxc'
EXEC SP_INS_SINHVIEN 'SV023', N'Hoàng Trần Thanh Như', '2002-7-9', N'Bắc Kạn', 'LP0002', N'thanhnhup', N'n1dqqx1xf7dv'
EXEC SP_INS_SINHVIEN 'SV024', N'Lê Gia Nhi', '2002-11-7', N'Thành phố Hồ Chí Minh', 'LP0002', N'gianhiu', N'jz59hst1r'
EXEC SP_INS_SINHVIEN 'SV025', N'Bùi Quỳnh Gia Thư', '2002-12-2', N'Bạc Liêu', 'LP0002', N'giathul', N'uhn6sibaw'
EXEC SP_INS_SINHVIEN 'SV026', N'Lê Đăng Nam', '2002-9-26', N'Hòa Bình', 'LP0002', N'dangnamg', N'gkc1blf1sn2u'
EXEC SP_INS_SINHVIEN 'SV027', N'Nguyễn Quỳnh Ngân', '2002-9-2', N'Hà Nội', 'LP0002', N'quynhngan6', N'hdgehfadvotm'
EXEC SP_INS_SINHVIEN 'SV028', N'Lê Thanh Phương Trân', '2002-5-4', N'Cà Mau', 'LP0002', N'phuongtranq', N'lvtpbicocx'
EXEC SP_INS_SINHVIEN 'SV029', N'Vũ Thành Huy', '2002-5-2', N'Hòa Bình', 'LP0002', N'thanhhuyw', N'eg0d99stcy'
EXEC SP_INS_SINHVIEN 'SV030', N'Hoàng Nguyễn Bảo Anh', '2002-7-27', N'Hòa Bình', 'LP0002', N'baoanhd', N'btodlrpvoi06'
EXEC SP_INS_SINHVIEN 'SV031', N'Nguyễn Lê Kim Linh', '2002-4-15', N'Hà Tĩnh', 'LP0002', N'kimlinhs', N'szpsymn3rnrx'
EXEC SP_INS_SINHVIEN 'SV032', N'Huỳnh Phương Phương', '2002-5-8', N'Hậu Giang', 'LP0002', N'phuongphuongl', N'akdfiqilap'
EXEC SP_INS_SINHVIEN 'SV033', N'Nguyễn Nguyễn Minh Linh', '2002-1-27', N'Cà Mau', 'LP0002', N'minhlinhi', N'y2l5dpbg8'
EXEC SP_INS_SINHVIEN 'SV034', N'Lê Phương Anh Thư', '2002-9-26', N'Hải Phòng', 'LP0002', N'anhthuv', N'j7tguso65'
EXEC SP_INS_SINHVIEN 'SV035', N'Trương Huỳnh Bảo Ngọc', '2002-7-6', N'Đắk Nông', 'LP0002', N'baongocl', N'fzu2aror4uq'
EXEC SP_INS_SINHVIEN 'SV036', N'Trần Minh Quỳnh Vy', '2002-5-1', N'Hòa Bình', 'LP0002', N'quynhvyj', N'gqu98v50'
EXEC SP_INS_SINHVIEN 'SV037', N'Vũ Đăng Bảo', '2002-8-11', N'Điện Biên', 'LP0002', N'dangbaoe', N'olbcmwxr'
EXEC SP_INS_SINHVIEN 'SV038', N'Phạm Thị Minh Quỳnh', '2002-2-4', N'Bắc Giang', 'LP0002', N'minhquynhk', N'z0dvqe3uf'
EXEC SP_INS_SINHVIEN 'SV039', N'Vũ Văn Nam', '2002-3-6', N'Hải Phòng', 'LP0002', N'vannamx', N'nlqfyhryh158'
EXEC SP_INS_SINHVIEN 'SV040', N'Hoàng Tấn Phát', '2002-12-24', N'Hà Nam', 'LP0002', N'tanphatd', N'3a5jr1bpr'
EXEC SP_INS_SINHVIEN 'SV041', N'Võ Tấn Duy', '2002-7-20', N'Đắk Lắk', 'LP0003', N'tanduy0', N'a2txebyeeio'
EXEC SP_INS_SINHVIEN 'SV042', N'Lê Hoàng Bảo Anh', '2002-2-10', N'Bình Định', 'LP0003', N'baoanhl', N'n8oufvhdy'
EXEC SP_INS_SINHVIEN 'SV043', N'Đặng Quốc Long', '2002-12-13', N'Hà Giang', 'LP0003', N'quoclongs', N'a9sohmx98b'
EXEC SP_INS_SINHVIEN 'SV044', N'Nguyễn Quốc Nam', '2002-2-27', N'Gia Lai', 'LP0003', N'quocnamb', N'o4z4x2zcgj'
EXEC SP_INS_SINHVIEN 'SV045', N'Đặng Đăng Phát', '2002-6-15', N'Đồng Nai', 'LP0003', N'dangphats', N'iozfqolw1n'
EXEC SP_INS_SINHVIEN 'SV046', N'Vũ Trung Phúc', '2002-12-14', N'Bạc Liêu', 'LP0003', N'trungphucc', N'yzmuvn6gfh'
EXEC SP_INS_SINHVIEN 'SV047', N'Hoàng Tuấn Phát', '2002-9-15', N'Hải Phòng', 'LP0003', N'tuanphatb', N'2xslyzlup'
EXEC SP_INS_SINHVIEN 'SV048', N'Nguyễn Thanh Thảo Linh', '2002-6-26', N'Hậu Giang', 'LP0003', N'thaolinhh', N'4pf9wwva'
EXEC SP_INS_SINHVIEN 'SV049', N'Trần Phương My', '2002-5-18', N'Bạc Liêu', 'LP0003', N'phuongmyk', N'296ei02evull'
EXEC SP_INS_SINHVIEN 'SV050', N'Đặng Quốc Bảo', '2002-8-19', N'Hà Nam', 'LP0003', N'quocbao2', N'dfwzzvye'
EXEC SP_INS_SINHVIEN 'SV051', N'Phan Đức Đạt', '2002-12-4', N'Đắk Lắk', 'LP0003', N'ducdatz', N'yzrupxlc'
EXEC SP_INS_SINHVIEN 'SV052', N'Trương Ngọc Yến Thư', '2002-2-19', N'Bình Thuận', 'LP0003', N'yenthuz', N'aky5d42b'
EXEC SP_INS_SINHVIEN 'SV053', N'Trần Phương Như Thư', '2002-5-23', N'Bến Tre', 'LP0003', N'nhuthuh', N'04mzb0kipu'
EXEC SP_INS_SINHVIEN 'SV054', N'Nguyễn Nguyễn Quỳnh My', '2002-10-1', N'Hòa Bình', 'LP0003', N'quynhmyy', N'lxf17qzo3d'
EXEC SP_INS_SINHVIEN 'SV055', N'Lê Bảo Kim Nghi', '2002-4-1', N'Cà Mau', 'LP0003', N'kimnghi9', N'91dji6rxch'
EXEC SP_INS_SINHVIEN 'SV056', N'Lê Duy Quân', '2002-12-22', N'Bà Rịa – Vũng Tàu', 'LP0003', N'duyquanp', N'afq4aawo'
EXEC SP_INS_SINHVIEN 'SV057', N'Nguyễn Trần Linh', '2002-2-25', N'Bắc Kạn', 'LP0003', N'tranlinhb', N'jgatjxn1bp'
EXEC SP_INS_SINHVIEN 'SV058', N'Võ Đăng Duy', '2002-9-21', N'Đắk Nông', 'LP0003', N'dangduyx', N'clm5t8mk3d'
EXEC SP_INS_SINHVIEN 'SV059', N'Lê Quốc Duy', '2002-6-14', N'Hải Dương', 'LP0003', N'quocduyb', N'eqjbnb6zb'
EXEC SP_INS_SINHVIEN 'SV060', N'Vũ Nguyễn Kim Linh', '2002-8-1', N'Bến Tre', 'LP0003', N'kimlinh4', N'9448rrkd9kj'
EXEC SP_INS_SINHVIEN 'SV061', N'Hoàng Ngọc Bảo Linh', '2002-9-16', N'An Giang', 'LP0004', N'baolinhz', N'swd48dbj'
EXEC SP_INS_SINHVIEN 'SV062', N'Võ Huỳnh Phương Linh', '2002-12-4', N'Bắc Ninh', 'LP0004', N'phuonglinhr', N'0es4d5zi'
EXEC SP_INS_SINHVIEN 'SV063', N'Phan Tấn Khôi', '2002-12-1', N'Bình Phước', 'LP0004', N'tankhoio', N'1g3xsvzl'
EXEC SP_INS_SINHVIEN 'SV064', N'Huỳnh Nguyễn Khánh Anh', '2002-11-4', N'Hậu Giang', 'LP0004', N'khanhanh9', N'hjdhoapah5u'
EXEC SP_INS_SINHVIEN 'SV065', N'Phan Quốc Khôi', '2002-6-15', N'Hà Giang', 'LP0004', N'quockhoih', N'mpwudwu9dbwz'
EXEC SP_INS_SINHVIEN 'SV066', N'Võ Hoàng Thảo', '2002-7-5', N'Bình Thuận', 'LP0004', N'hoangthaor', N'adpn17lr'
EXEC SP_INS_SINHVIEN 'SV067', N'Trần Lê Thảo', '2002-8-13', N'Bắc Ninh', 'LP0004', N'lethao2', N'ynwkfwrfmn0t'
EXEC SP_INS_SINHVIEN 'SV068', N'Võ Đăng Bảo', '2002-4-4', N'Bạc Liêu', 'LP0004', N'dangbaon', N'w34sprvl8pjp'
EXEC SP_INS_SINHVIEN 'SV069', N'Phạm Tấn Kiệt', '2002-5-6', N'Bạc Liêu', 'LP0004', N'tankiet1', N'66aw0wo4'
EXEC SP_INS_SINHVIEN 'SV070', N'Trần Đức Đạt', '2002-5-5', N'Đắk Lắk', 'LP0004', N'ducdat1', N'korms3wvkrmo'
EXEC SP_INS_SINHVIEN 'SV071', N'Nguyễn Thành Huy', '2002-4-26', N'Hòa Bình', 'LP0004', N'thanhhuyq', N'0mxe8x6ngpk'
EXEC SP_INS_SINHVIEN 'SV072', N'Lê Quốc Duy', '2002-7-4', N'Cần Thơ', 'LP0004', N'quocduyt', N'ge3g0rta'
EXEC SP_INS_SINHVIEN 'SV073', N'Huỳnh Tuấn Phát', '2002-10-14', N'Thành phố Hồ Chí Minh', 'LP0004', N'tuanphat1', N'flllp8rdy8t'
EXEC SP_INS_SINHVIEN 'SV074', N'Hoàng Kim Anh My', '2002-7-24', N'Bắc Kạn', 'LP0004', N'anhmyc', N'fun8y6ge9n'
EXEC SP_INS_SINHVIEN 'SV075', N'Võ Văn Kiệt', '2002-6-23', N'Hòa Bình', 'LP0004', N'vankietc', N'zxcb8q1o'
EXEC SP_INS_SINHVIEN 'SV076', N'Trần Tuấn Long', '2002-3-21', N'Cao Bằng', 'LP0004', N'tuanlongv', N'duqzthr4'
EXEC SP_INS_SINHVIEN 'SV077', N'Trần Quốc Nam', '2002-1-22', N'Bắc Kạn', 'LP0004', N'quocnamh', N'dy0jnwrh4e9'
EXEC SP_INS_SINHVIEN 'SV078', N'Trần Thị Vy', '2002-7-5', N'Thành phố Hồ Chí Minh', 'LP0004', N'thivyx', N'g6k7vlc8fckm'
EXEC SP_INS_SINHVIEN 'SV079', N'Hoàng Thị Ngọc', '2002-9-21', N'Bến Tre', 'LP0004', N'thingoca', N'x4qk7m2tgckw'
EXEC SP_INS_SINHVIEN 'SV080', N'Hoàng Nguyễn Vy', '2002-7-15', N'Bình Phước', 'LP0004', N'nguyenvyz', N'vu72s3yc'
EXEC SP_INS_SINHVIEN 'SV081', N'Trần Quốc Khang', '2002-6-12', N'Đà Nẵng', 'LP0005', N'quockhangc', N'21bkuex66aiu'
EXEC SP_INS_SINHVIEN 'SV082', N'Phan Trần Như Quỳnh', '2002-11-28', N'Đắk Lắk', 'LP0005', N'nhuquynhv', N'rnwaazeioqz'
EXEC SP_INS_SINHVIEN 'SV083', N'Trần Tấn Phát', '2002-1-16', N'Bà Rịa – Vũng Tàu', 'LP0005', N'tanphatg', N'yceeompzibr'
EXEC SP_INS_SINHVIEN 'SV084', N'Lê Ngọc Anh', '2002-4-19', N'Đồng Nai', 'LP0005', N'ngocanhf', N'afyhqjz3o'
EXEC SP_INS_SINHVIEN 'SV085', N'Đặng Quỳnh Minh Linh', '2002-2-13', N'Bình Phước', 'LP0005', N'minhlinhc', N'cq09kcg5c06'
EXEC SP_INS_SINHVIEN 'SV086', N'Trương Bảo Bảo Anh', '2002-9-11', N'Hải Dương', 'LP0005', N'baoanh3', N'9n8r9il73x'
EXEC SP_INS_SINHVIEN 'SV087', N'Võ Phương Anh', '2002-10-15', N'Đắk Nông', 'LP0005', N'phuonganhu', N'e26nesjtr'
EXEC SP_INS_SINHVIEN 'SV088', N'Phạm Đăng Phát', '2002-12-23', N'Gia Lai', 'LP0005', N'dangphate', N'ybhn3cr73h'
EXEC SP_INS_SINHVIEN 'SV089', N'Vũ Đức Huy', '2002-5-6', N'Đà Nẵng', 'LP0005', N'duchuye', N'tblcbk0iq4'
EXEC SP_INS_SINHVIEN 'SV090', N'Phạm Quang Long', '2002-7-15', N'Bà Rịa – Vũng Tàu', 'LP0005', N'quanglongy', N'qvjromalw'
EXEC SP_INS_SINHVIEN 'SV091', N'Trần Trần Nghi', '2002-1-27', N'Bắc Kạn', 'LP0005', N'trannghi6', N'kmugwvayuz7'
EXEC SP_INS_SINHVIEN 'SV092', N'Phạm Đức Long', '2002-10-10', N'Hà Tĩnh', 'LP0005', N'duclongc', N'votwwtc4h'
EXEC SP_INS_SINHVIEN 'SV093', N'Trương Tấn Bảo', '2002-8-27', N'Cà Mau', 'LP0005', N'tanbao8', N'iaeg7ggya'
EXEC SP_INS_SINHVIEN 'SV094', N'Vũ Quốc Kiệt', '2002-5-1', N'Bình Dương', 'LP0005', N'quockiet2', N'zzl1y4t9aq3'
EXEC SP_INS_SINHVIEN 'SV095', N'Lê Đức Quân', '2002-12-16', N'Đồng Nai', 'LP0005', N'ducquanz', N'jfnnxwtmx'
EXEC SP_INS_SINHVIEN 'SV096', N'Nguyễn Hoàng Anh', '2002-7-13', N'Bình Dương', 'LP0005', N'hoanganhr', N'umknll5hndld'
EXEC SP_INS_SINHVIEN 'SV097', N'Trần Tuấn Anh', '2002-9-23', N'Bình Dương', 'LP0005', N'tuananh3', N'eu0vtqecw'
EXEC SP_INS_SINHVIEN 'SV098', N'Trần Quang Khôi', '2002-6-25', N'An Giang', 'LP0005', N'quangkhoim', N'kjm617eb'
EXEC SP_INS_SINHVIEN 'SV099', N'Đặng Phạm Kim Trân', '2002-2-11', N'Hà Nam', 'LP0005', N'kimtranu', N'ndk7t00b1dr'
EXEC SP_INS_SINHVIEN 'SV100', N'Phan Phương Thanh Linh', '2002-3-4', N'Bà Rịa – Vũng Tàu', 'LP0005', N'thanhlinhr', N'mjqxylpxx7a'

-- CREATE VIEW NV_LOP: MALOP, MANV, TENDN, MATKHAU
GO
CREATE VIEW NV_LOP 
AS
  SELECT L.MALOP, L.MANV, NV.TENDN, NV.MATKHAU
  FROM LOP AS L, NHANVIEN AS NV
  WHERE L.MANV = NV.MANV;

-- update DIEM 
GO
CREATE PROCEDURE SP_UPD_DIEM_SINHVIEN
@TenDN nvarchar(100),
@MK nvarchar(30),
@MaSV varchar(20),
@MaHP varchar(20),
@Diem float
AS
BEGIN
    IF (@Diem NOT BETWEEN 0 AND 10) THROW 50006, N'Score must be between 0 and 10.', 1; 
    -- kiem tra sinh vien thuoc lop nhan vien phu trach
	DECLARE @LPT varchar(20), @MaNV varchar(20);
	SET @LPT = '';
	SET @MaNV = '';
	SELECT @LPT=MALOP, @MaNV=MANV FROM NV_LOP WHERE TENDN = @TenDN AND MATKHAU = HASHBYTES('SHA1', @MK)
    -- neu nhan vien phụ trach sinh vien, cap nhat diem sinh vien do
	IF EXISTS (SELECT * FROM SINHVIEN WHERE MASV=@MaSV AND MALOP=@LPT)
	BEGIN
	    DECLARE @q varchar(max);
		SET @q = 'UPDATE BANGDIEM SET DIEMTHI = ' + 'EncryptByAsymKey( AsymKey_ID('''+ @MaNV +'''), convert(varbinary, ''' + convert(varchar, @Diem) 
		+ ''')) WHERE MASV = ''' + @MaSV+''' AND MAHP = '''+@MaHP+'''';
		EXEC(@q);   
	END
	ELSE THROW 50007, N'Failed to update student''s score', 1;
END

-- update BANGDIEM
GO
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV001','CSC10004',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV001','CSC10006',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV001','CSC13002',8
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV001','CSC14003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV001','CSC10003',8
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV002','CSC10004',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV002','CSC10006',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV002','CSC13002',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV002','CSC14003',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV002','CSC10003',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV003','CSC10004',5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV003','CSC10006',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV003','CSC13002',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV003','CSC14003',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV003','CSC10003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV004','CSC10004',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV004','CSC10006',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV004','CSC13002',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV004','CSC14003',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV004','CSC10003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV005','CSC10004',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV005','CSC10006',7
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV005','CSC13002',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV005','CSC14003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV005','CSC10003',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV006','CSC10004',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV006','CSC10006',7
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV006','CSC13002',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV006','CSC14003',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV006','CSC10003',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV007','CSC10004',7
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV007','CSC10006',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV007','CSC13002',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV007','CSC14003',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV007','CSC10003',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV008','CSC10004',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV008','CSC10006',5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV008','CSC13002',9
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV008','CSC14003',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV008','CSC10003',5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV009','CSC10004',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV009','CSC10006',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV009','CSC13002',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV009','CSC14003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV009','CSC10003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV010','CSC10004',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV010','CSC10006',6
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV010','CSC13002',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV010','CSC14003',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV010','CSC10003',6
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV011','CSC10004',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV011','CSC10006',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV011','CSC13002',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV011','CSC14003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV011','CSC10003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV012','CSC10004',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV012','CSC10006',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV012','CSC13002',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV012','CSC14003',4
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV012','CSC10003',6
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV013','CSC10004',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV013','CSC10006',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV013','CSC13002',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV013','CSC14003',8
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV013','CSC10003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV014','CSC10004',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV014','CSC10006',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV014','CSC13002',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV014','CSC14003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV014','CSC10003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV015','CSC10004',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV015','CSC10006',7
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV015','CSC13002',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV015','CSC14003',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV015','CSC10003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV016','CSC10004',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV016','CSC10006',5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV016','CSC13002',7
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV016','CSC14003',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV016','CSC10003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV017','CSC10004',4
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV017','CSC10006',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV017','CSC13002',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV017','CSC14003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV017','CSC10003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV018','CSC10004',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV018','CSC10006',6
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV018','CSC13002',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV018','CSC14003',5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV018','CSC10003',9
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV019','CSC10004',7
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV019','CSC10006',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV019','CSC13002',9
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV019','CSC14003',5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV019','CSC10003',6.25
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV020','CSC10004',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV020','CSC10006',5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV020','CSC13002',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV020','CSC14003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV020','CSC10003',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV021','CSC10004',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV021','CSC10006',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV021','CSC13002',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV021','CSC14003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV021','CSC10003',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV022','CSC10004',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV022','CSC10006',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV022','CSC13002',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV022','CSC14003',6.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV022','CSC10003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV023','CSC10004',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV023','CSC10006',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV023','CSC13002',4
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV023','CSC14003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV023','CSC10003',9
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV024','CSC10004',6.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV024','CSC10006',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV024','CSC13002',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV024','CSC14003',5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV024','CSC10003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV025','CSC10004',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV025','CSC10006',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV025','CSC13002',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV025','CSC14003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV025','CSC10003',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV026','CSC10004',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV026','CSC10006',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV026','CSC13002',4
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV026','CSC14003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV026','CSC10003',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV027','CSC10004',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV027','CSC10006',9
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV027','CSC13002',4
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV027','CSC14003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV027','CSC10003',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV028','CSC10004',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV028','CSC10006',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV028','CSC13002',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV028','CSC14003',9
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV028','CSC10003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV029','CSC10004',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV029','CSC10006',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV029','CSC13002',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV029','CSC14003',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV029','CSC10003',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV030','CSC10004',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV030','CSC10006',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV030','CSC13002',7
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV030','CSC14003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV030','CSC10003',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV031','CSC10004',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV031','CSC10006',9
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV031','CSC13002',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV031','CSC14003',8
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV031','CSC10003',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV032','CSC10004',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV032','CSC10006',4
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV032','CSC13002',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV032','CSC14003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV032','CSC10003',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV033','CSC10004',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV033','CSC10006',9
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV033','CSC13002',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV033','CSC14003',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV033','CSC10003',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV034','CSC10004',8
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV034','CSC10006',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV034','CSC13002',8
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV034','CSC14003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV034','CSC10003',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV035','CSC10004',5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV035','CSC10006',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV035','CSC13002',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV035','CSC14003',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV035','CSC10003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV036','CSC10004',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV036','CSC10006',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV036','CSC13002',9
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV036','CSC14003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV036','CSC10003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV037','CSC10004',7
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV037','CSC10006',9
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV037','CSC13002',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV037','CSC14003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV037','CSC10003',5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV038','CSC10004',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV038','CSC10006',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV038','CSC13002',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV038','CSC14003',4
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV038','CSC10003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV039','CSC10004',6
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV039','CSC10006',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV039','CSC13002',5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV039','CSC14003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV039','CSC10003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV040','CSC10004',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV040','CSC10006',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV040','CSC13002',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV040','CSC14003',6
EXEC SP_UPD_DIEM_SINHVIEN N'thilinhv', N'kre054njze6i', 'SV040','CSC10003',6.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV041','CSC10004',8
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV041','CSC10006',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV041','CSC13002',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV041','CSC14003',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV041','CSC10003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV042','CSC10004',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV042','CSC10006',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV042','CSC13002',5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV042','CSC14003',9
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV042','CSC10003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV043','CSC10004',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV043','CSC10006',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV043','CSC13002',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV043','CSC14003',6.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV043','CSC10003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV044','CSC10004',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV044','CSC10006',4
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV044','CSC13002',6
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV044','CSC14003',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV044','CSC10003',8
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV045','CSC10004',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV045','CSC10006',7
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV045','CSC13002',6.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV045','CSC14003',6
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV045','CSC10003',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV046','CSC10004',6
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV046','CSC10006',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV046','CSC13002',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV046','CSC14003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV046','CSC10003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV047','CSC10004',6
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV047','CSC10006',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV047','CSC13002',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV047','CSC14003',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV047','CSC10003',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV048','CSC10004',6
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV048','CSC10006',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV048','CSC13002',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV048','CSC14003',8
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV048','CSC10003',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV049','CSC10004',9
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV049','CSC10006',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV049','CSC13002',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV049','CSC14003',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV049','CSC10003',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV050','CSC10004',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV050','CSC10006',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV050','CSC13002',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV050','CSC14003',8
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV050','CSC10003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV051','CSC10004',5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV051','CSC10006',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV051','CSC13002',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV051','CSC14003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV051','CSC10003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV052','CSC10004',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV052','CSC10006',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV052','CSC13002',4
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV052','CSC14003',4
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV052','CSC10003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV053','CSC10004',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV053','CSC10006',6.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV053','CSC13002',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV053','CSC14003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV053','CSC10003',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV054','CSC10004',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV054','CSC10006',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV054','CSC13002',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV054','CSC14003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV054','CSC10003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV055','CSC10004',8
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV055','CSC10006',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV055','CSC13002',5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV055','CSC14003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV055','CSC10003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV056','CSC10004',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV056','CSC10006',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV056','CSC13002',5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV056','CSC14003',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV056','CSC10003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV057','CSC10004',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV057','CSC10006',6
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV057','CSC13002',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV057','CSC14003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV057','CSC10003',6
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV058','CSC10004',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV058','CSC10006',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV058','CSC13002',4
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV058','CSC14003',6.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV058','CSC10003',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV059','CSC10004',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV059','CSC10006',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV059','CSC13002',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV059','CSC14003',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV059','CSC10003',8
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV060','CSC10004',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV060','CSC10006',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV060','CSC13002',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV060','CSC14003',9
EXEC SP_UPD_DIEM_SINHVIEN N'levy7', N'zf2mhwej', 'SV060','CSC10003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV061','CSC10004',6
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV061','CSC10006',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV061','CSC13002',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV061','CSC14003',5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV061','CSC10003',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV062','CSC10004',5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV062','CSC10006',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV062','CSC13002',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV062','CSC14003',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV062','CSC10003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV063','CSC10004',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV063','CSC10006',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV063','CSC13002',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV063','CSC14003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV063','CSC10003',9
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV064','CSC10004',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV064','CSC10006',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV064','CSC13002',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV064','CSC14003',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV064','CSC10003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV065','CSC10004',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV065','CSC10006',8
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV065','CSC13002',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV065','CSC14003',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV065','CSC10003',9
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV066','CSC10004',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV066','CSC10006',8
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV066','CSC13002',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV066','CSC14003',7
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV066','CSC10003',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV067','CSC10004',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV067','CSC10006',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV067','CSC13002',5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV067','CSC14003',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV067','CSC10003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV068','CSC10004',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV068','CSC10006',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV068','CSC13002',5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV068','CSC14003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV068','CSC10003',6
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV069','CSC10004',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV069','CSC10006',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV069','CSC13002',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV069','CSC14003',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV069','CSC10003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV070','CSC10004',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV070','CSC10006',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV070','CSC13002',4
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV070','CSC14003',8
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV070','CSC10003',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV071','CSC10004',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV071','CSC10006',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV071','CSC13002',8
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV071','CSC14003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV071','CSC10003',4
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV072','CSC10004',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV072','CSC10006',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV072','CSC13002',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV072','CSC14003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV072','CSC10003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV073','CSC10004',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV073','CSC10006',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV073','CSC13002',8
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV073','CSC14003',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV073','CSC10003',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV074','CSC10004',6
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV074','CSC10006',6.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV074','CSC13002',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV074','CSC14003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV074','CSC10003',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV075','CSC10004',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV075','CSC10006',5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV075','CSC13002',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV075','CSC14003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV075','CSC10003',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV076','CSC10004',9.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV076','CSC10006',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV076','CSC13002',4
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV076','CSC14003',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV076','CSC10003',6
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV077','CSC10004',9
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV077','CSC10006',4
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV077','CSC13002',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV077','CSC14003',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV077','CSC10003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV078','CSC10004',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV078','CSC10006',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV078','CSC13002',5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV078','CSC14003',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV078','CSC10003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV079','CSC10004',4
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV079','CSC10006',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV079','CSC13002',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV079','CSC14003',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV079','CSC10003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV080','CSC10004',5
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV080','CSC10006',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV080','CSC13002',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV080','CSC14003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'trungbao6', N'hc4gcwodcv', 'SV080','CSC10003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV081','CSC10004',9
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV081','CSC10006',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV081','CSC13002',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV081','CSC14003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV081','CSC10003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV082','CSC10004',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV082','CSC10006',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV082','CSC13002',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV082','CSC14003',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV082','CSC10003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV083','CSC10004',8
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV083','CSC10006',9
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV083','CSC13002',5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV083','CSC14003',8
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV083','CSC10003',8
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV084','CSC10004',8
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV084','CSC10006',7
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV084','CSC13002',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV084','CSC14003',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV084','CSC10003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV085','CSC10004',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV085','CSC10006',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV085','CSC13002',7
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV085','CSC14003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV085','CSC10003',6
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV086','CSC10004',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV086','CSC10006',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV086','CSC13002',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV086','CSC14003',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV086','CSC10003',6
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV087','CSC10004',9
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV087','CSC10006',6
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV087','CSC13002',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV087','CSC14003',9
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV087','CSC10003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV088','CSC10004',5.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV088','CSC10006',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV088','CSC13002',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV088','CSC14003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV088','CSC10003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV089','CSC10004',9
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV089','CSC10006',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV089','CSC13002',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV089','CSC14003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV089','CSC10003',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV090','CSC10004',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV090','CSC10006',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV090','CSC13002',6
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV090','CSC14003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV090','CSC10003',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV091','CSC10004',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV091','CSC10006',4
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV091','CSC13002',6
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV091','CSC14003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV091','CSC10003',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV092','CSC10004',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV092','CSC10006',7.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV092','CSC13002',8.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV092','CSC14003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV092','CSC10003',5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV093','CSC10004',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV093','CSC10006',5.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV093','CSC13002',7.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV093','CSC14003',8.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV093','CSC10003',9
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV094','CSC10004',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV094','CSC10006',9
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV094','CSC13002',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV094','CSC14003',6.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV094','CSC10003',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV095','CSC10004',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV095','CSC10006',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV095','CSC13002',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV095','CSC14003',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV095','CSC10003',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV096','CSC10004',9.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV096','CSC10006',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV096','CSC13002',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV096','CSC14003',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV096','CSC10003',5.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV097','CSC10004',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV097','CSC10006',5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV097','CSC13002',7.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV097','CSC14003',4.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV097','CSC10003',4
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV098','CSC10004',6.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV098','CSC10006',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV098','CSC13002',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV098','CSC14003',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV098','CSC10003',4
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV099','CSC10004',6.25
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV099','CSC10006',6
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV099','CSC13002',7
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV099','CSC14003',8.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV099','CSC10003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV100','CSC10004',9.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV100','CSC10006',4.75
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV100','CSC13002',6
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV100','CSC14003',4.5
EXEC SP_UPD_DIEM_SINHVIEN N'thanhlinh1', N'7aoymrvdtsp', 'SV100','CSC10003',7


-- EXEC SP_UPD_DIEM_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV001','CSC10004',7
-- select * from BANGDIEM

-- SELECT bang diem
GO
CREATE PROCEDURE SP_SEL_BANGDIEM_LOP
@TenDN nvarchar(100),
@MK nvarchar(30)
AS
BEGIN
  DECLARE @LPT varchar(20), @MaNV varchar(20);
  SET @LPT = '';
  SET @MaNV = '';
  SELECT @LPT=MALOP, @MaNV=MANV FROM NV_LOP WHERE TENDN = @TenDN AND MATKHAU = HASHBYTES('SHA1', @MK)
  -- neu nhan vien phu trach mot lop, in bang diem lop do
  SELECT BD.MASV, BD.MAHP, CONVERT(varchar, DECRYPTBYASYMKEY(ASYMKEY_ID(@MaNV), BD.DIEMTHI, @MK)) AS DIEM 
  FROM BANGDIEM AS BD
  JOIN
  (SELECT MASV FROM SINHVIEN WHERE MALOP = @LPT) AS SV 
  ON BD.MASV = SV.MASV;
END
-- EXEC SP_SEL_BANGDIEM_LOP N'quynhanh3',  'ctl1wiw1d'

-- select danh sach lop
GO
CREATE PROCEDURE SP_SEL_SINHVIEN_LOP 
@TenDN nvarchar(100),
@MK nvarchar(30)
AS
BEGIN 
  DECLARE @LPT varchar(20);
  SET @LPT = '';
  SELECT @LPT=MALOP FROM NV_LOP WHERE TENDN = @TenDN AND MATKHAU = HASHBYTES('SHA1', @MK)
  -- neu nhan vien phu trach mot lop, in danh sach sinh vien lop do
  SELECT MASV, HOTEN, NGAYSINH, DIACHI FROM SINHVIEN WHERE MALOP = @LPT;
END
-- select * FROM SINHVIEN
-- EXEC SP_SEL_SINHVIEN_LOP N'quynhanh3', N'ctl1wiw1d'

-- NHANVIEN update SINHVIEN 
GO
CREATE PROCEDURE SP_UPD_TT_SINHVIEN
@TenDN nvarchar(100),
@MK nvarchar(30),
@MaSV varchar(20),
@HoTen nvarchar(100),
@NgaySinh datetime,
@DiaChi nvarchar(200) 
AS
BEGIN
  DECLARE @LPT varchar(20), @MaNV varchar(20);
  SET @LPT = '';
  SET @MaNV = '';
  SELECT @LPT=MALOP, @MaNV=MANV FROM NV_LOP WHERE TENDN = @TenDN AND MATKHAU = HASHBYTES('SHA1', @MK)
  IF EXISTS (SELECT * FROM SINHVIEN WHERE MASV=@MaSV AND MALOP=@LPT)
    UPDATE SINHVIEN SET HOTEN = @HoTen, NGAYSINH = @NgaySinh, DIACHI=@DiaChi WHERE MASV = @MaSV;
END
-- EXEC SP_UPD_TT_SINHVIEN N'quynhanh3', N'ctl1wiw1d', 'SV001', N'NGuyen dinhc hien', '2002-2-16', N'Haf tinh'
-- Select * FROM SINHVIEN
-- NHAN VIEN khong thay doi mat khau cua minh (hoi phuc tap)
 
-- SELECT* FROM SINHVIEN
-- SELECT* FROM BANGDIEM
-- SELECT* FROM NHANVIEN
-- SELECT* FROM LOP
-- SELECT* FROM HOCPHAN

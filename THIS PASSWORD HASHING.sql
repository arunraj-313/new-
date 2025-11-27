CREATE or alter PROC Check_PW_Vaildate_SP
 @User_name nvarchar(50),
 @Password nvarchar(50)
AS
BEGIN

    DECLARE @Random VARBINARY(16);
	SET @Random = CRYPT_GEN_RANDOM(16);
	DECLARE @hashedPassword VARBINARY(64);
	--SET @hashedPassword = @Password;

	SET @hashedPassword = HASHBYTES('SHA2_512', @password + CONVERT(NVARCHAR(MAX), @Random));

	IF NOT EXISTS (SELECT 1 FROM LOGIN_Pw_DATA WHERE User_Name = @User_Name)
	--IF (select * from LOGIN_Pw_DATA where [User_Name] != @User_Name)
		BEGIN
			INSERT INTO LOGIN_Pw_DATA ([User_Name], PW_Random, Hashed_password)
								VALUES (@User_Name, @Random, @HashedPassword);
		END
	ELSE
		BEGIN
			 PRINT 'This UserName Already Exists';
		END
END;

SELECT 1 FROM LOGIN_Pw_DATA WHERE User_Name = @User_Name

select * from LOGIN_Pw_DATA

EXEC Check_PW_Vaildate_SP 'GIRIDHARAN', 'SECURE@123' 


CREATE or alter PROC Check_PW_ValidOrNot_SP
     @User_name nvarchar(50),
	 @inputPassword nvarchar(50)
AS
BEGIN
	  DECLARE @storedRandom VARBINARY(16);
	  DECLARE @storedHash VARBINARY(64);
	  SElect @storedRandom = PW_Random from LOGIN_Pw_DATA
	  SElect @storedHash = Hashed_password from LOGIN_Pw_DATA

	  DECLARE @inputHash VARBINARY(64);
		SET @inputHash = HASHBYTES('SHA2_512', @inputPassword + CONVERT(NVARCHAR(MAX), @storedRandom));

-- Compare hashes
		IF @inputHash = @storedHash
			 PRINT 'Password is valid';
		ELSE
			 PRINT 'Invalid password';
	 
END;

exec Check_PW_ValidOrNot_SP 'GIRIDHARAN', 'SECURE@123'

selecT * from LOGIN_Pw_DATA
---------------------------------------------------------------------------------------------------------------------

                             ---- Form code SP 

---------------------------------------- login ----------------------------------------------
use DEMOLoginPage

CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    HashedPassword VARBINARY(64) NOT NULL,
    PW_Random VARBINARY(16) NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE()
);

select * from Users
--------------------------------------------- LOGIN_SP ---------------------------------------------------------------------

CREATE OR ALTER PROCEDURE LoginUser_SP
    @UsernameOrEmail NVARCHAR(100),
    @Password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @StoredSalt VARBINARY(16);
    DECLARE @StoredHash VARBINARY(64);
 
    -- Fetch salt and hash
    SELECT @StoredSalt = PW_Random, @StoredHash = HashedPassword
    FROM Users
    WHERE Username = @UsernameOrEmail OR Email = @UsernameOrEmail;
 
    IF @StoredSalt IS NULL
        RETURN 0;  -- User not found
 
    DECLARE @InputHash VARBINARY(64);
    SET @InputHash = HASHBYTES('SHA2_512', @Password + CONVERT(NVARCHAR(MAX), @StoredSalt));
 
    IF @InputHash = @StoredHash
        RETURN 1;   -- Login success
    ELSE
        RETURN -1;  -- Invalid password
END

exec LoginUser_SP '@gmail.com', 'arunraj@123'

-----------------------------------------------------REGISTER_SP-------------------------------------------------------------

exec RegisterUser_SP 'arunraj','arunraj@gmail.com', 'arunraj@123'
 
CREATE OR ALTER PROCEDURE RegisterUser_SP
    @Username NVARCHAR(50),
    @Email NVARCHAR(100),
    @Password NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Check if email exists
    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
        RETURN -1; -- Email already registered
 
    -- Check if username exists
    IF EXISTS (SELECT 1 FROM Users WHERE Username = @Username)
        RETURN -2; -- Username already exists
 
    DECLARE @Random VARBINARY(16) = CRYPT_GEN_RANDOM(16);
    DECLARE @HashedPassword VARBINARY(64);
 
    SET @HashedPassword = HASHBYTES('SHA2_512', @Password + CONVERT(NVARCHAR(MAX), @Random));
 
    INSERT INTO Users (Username, Email, HashedPassword, PW_Random)
    VALUES (@Username, @Email, @HashedPassword, @Random);
 
    RETURN 1; -- Success
END


-------------------------------------------------------------------------------------------------------------------------------
exec RegisterUser_SP 'giridharan', 'giridharan@gmail.com', 'giridharan@123'

select * from users



-------------------------------------------------- ForgotPassword_SP -------------------------------------------------------------

ALTER TABLE Users ADD ResetToken NVARCHAR(200) NULL;  --This will store a temporary unique code for resetting the password.
 

------------------------------------------------Create SP to generate reset token Stored Procedure:  -------------
--update users set Email = LTRIM(RTRIM(email));

--alter table users alter column email nvarchar(100);

--select email,len(email) from Users

CREATE OR ALTER PROCEDURE ForgotPassword_SP         
	 @Email NVARCHAR(100)						    
AS
BEGIN
    SET NOCOUNT ON;
 
    IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
        RETURN -1; -- Email not found
 
    DECLARE @Token NVARCHAR(200);
    SET @Token = CONVERT(NVARCHAR(200), NEWID()); -- unique token   
												  --NEWID() generates a unique random token
    UPDATE Users
    SET ResetToken = @Token					      --We return token so C# can send email or show link
    WHERE Email = @Email;
 
    SELECT @Token AS Token;  -- return token as result set
 
    RETURN 1; -- success
END


------------------------ Create SP to generate reset token  -----  Stored Procedure: ForgotPassword_SP ------------------------

CREATE OR ALTER PROCEDURE ResetPassword_SP                -- New password gets hashed
	 @Token NVARCHAR(200),								  --Old password destroyed
	@NewPassword NVARCHAR(100)							  --Token gets removed    
AS
BEGIN
    SET NOCOUNT ON;
 
    DECLARE @Salt VARBINARY(16);
    DECLARE @Hash VARBINARY(64);
    DECLARE @UserId INT;
 
    SELECT @UserId = UserId FROM Users
    WHERE ResetToken = @Token;
 
    IF @UserId IS NULL
        RETURN -1; -- Invalid token
 
    -- Generate new salt
    SET @Salt = CRYPT_GEN_RANDOM(16);
    SET @Hash = HASHBYTES('SHA2_512', @NewPassword + CONVERT(NVARCHAR(MAX), @Salt));
 
    UPDATE Users
    SET HashedPassword = @Hash, PW_Random = @Salt, ResetToken = NULL       -- remove token
    WHERE UserId = @UserId;
 
    RETURN 1; -- success
END

-- confirm current database
SELECT DB_NAME() AS CurrentDatabase;
 
-- show email values and lengths
SELECT UserId, Username, Email, LEN(Email) AS EmailLength, ResetToken
FROM dbo.Users;

-- check stored proc exists in current DB
SELECT OBJECT_SCHEMA_NAME(object_id) AS SchemaName, name
FROM sys.procedures
WHERE name = 'ForgotPassword_SP';

exec ForgotPassword_SP 'arunraj@gmail.com'

-----------------------------------------------------admin page ----------------------------------------------------------------------
USE StayEasy;
GO
 
-- Cities
CREATE TABLE dbo.Cities
(
    CityId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
);
 
-- Places (localities) belong to a city
CREATE TABLE dbo.Places
(
    PlaceId INT IDENTITY(1,1) PRIMARY KEY,
    CityId INT NOT NULL FOREIGN KEY REFERENCES dbo.Cities(CityId),
    Name NVARCHAR(150) NOT NULL
);
 
-- Amenities
CREATE TABLE dbo.Amenities
(
    AmenityId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL
);
 
-- Properties (PGs)
CREATE TABLE dbo.Properties
(
    PropertyId INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(200) NOT NULL,
    CityId INT NOT NULL FOREIGN KEY REFERENCES dbo.Cities(CityId),
    PlaceId INT NULL FOREIGN KEY REFERENCES dbo.Places(PlaceId),
    Type NVARCHAR(50) NULL,       -- "Coliving" or "Student"
    Gender NVARCHAR(20) NULL,     -- "Male","Female","Other" or NULL
    Price DECIMAL(10,2) NULL,
    Description NVARCHAR(MAX) NULL,
    CreatedDate DATETIME DEFAULT GETDATE()
);
 
-- Many-to-many: property <-> amenity
CREATE TABLE dbo.PropertyAmenities
(
    PropertyAmenityId INT IDENTITY(1,1) PRIMARY KEY,
    PropertyId INT NOT NULL FOREIGN KEY REFERENCES dbo.Properties(PropertyId),
    AmenityId INT NOT NULL FOREIGN KEY REFERENCES dbo.Amenities(AmenityId)
);
 
-- Enquiries (when user fills contact and clicks search you may save)
CREATE TABLE dbo.Enquiries
(
    EnquiryId INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100),
    Contact NVARCHAR(50),
    Email NVARCHAR(150),
    City NVARCHAR(100),
    Places NVARCHAR(500),       -- CSV of places selected
    Type NVARCHAR(50),
    Gender NVARCHAR(20),
    Amenities NVARCHAR(500),    -- CSV
    MoveInDate DATE,
    PropertySearch NVARCHAR(200),
    CreatedDate DATETIME DEFAULT GETDATE()
);
 
-- -------------------------
-- Sample data
INSERT INTO dbo.Cities (Name) VALUES ('Bangalore'), ('Mumbai'), ('Chennai');
 
INSERT INTO dbo.Places (CityId, Name) VALUES
(1,'Koramangala'),(1,'Indiranagar'),(1,'Bellandur'),
(2,'Andheri'),(2,'Bandra'),
(3,'Anna Nagar'),(3,'Adyar');
 
INSERT INTO dbo.Amenities (Name) VALUES ('AC'),('Food'),('Gym'),('Fridge'),('Parking'),('Power backup');
 
-- Add some sample properties
INSERT INTO dbo.Properties (Title, CityId, PlaceId, Type, Gender, Price, Description)
VALUES
('Sunny Coliving near Koramangala', 1, 1, 'Coliving', 'Male', 8000, 'Shared room, bright'),
('Student PG Indiranagar', 1, 2, 'Student', 'Female', 7000, 'Near college'),
('Bellandur Single Room', 1, 3, 'Coliving', 'Any', 12000, 'Individual room');
 
-- link amenities to properties
-- PropertyId 1 -> AC, Food
INSERT INTO dbo.PropertyAmenities (PropertyId, AmenityId) VALUES (1,1),(1,2);
-- PropertyId 2 -> Fridge, Power backup
INSERT INTO dbo.PropertyAmenities (PropertyId, AmenityId) VALUES (2,4),(2,6);
-- PropertyId 3 -> Parking, AC, Gym
INSERT INTO dbo.PropertyAmenities (PropertyId, AmenityId) VALUES (3,5),(3,1),(3,3);
 
GO

-------------------------------------------- GetCities_SP ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE GetCities_SP
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CityId, Name FROM dbo.Cities ORDER BY Name;
END

--------------------------------------------------------GetPlacesByCity_SP----------------------------------------------------

CREATE OR ALTER PROCEDURE GetPlacesByCity_SP
    @CityId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PlaceId, Name
    FROM dbo.Places
    WHERE CityId = @CityId
    ORDER BY Name;
END

--------------------------------------------------------SearchProperties_SP--------------------------------------------------

CREATE OR ALTER PROCEDURE SearchProperties_SP
    @CityId INT = NULL,
    @PlaceName NVARCHAR(150) = NULL,
    @Type NVARCHAR(50) = NULL,
    @Gender NVARCHAR(20) = NULL,
    @AmenitiesCSV NVARCHAR(MAX) = NULL, -- comma-separated amenity names e.g. 'AC,Gym'
    @PropertySearch NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
 
    SELECT DISTINCT
        p.PropertyId,
        p.Title,
        c.Name AS City,
        pl.Name AS Place,
        p.Type,
        p.Gender,
        p.Price,
        p.Description
    FROM dbo.Properties p
    INNER JOIN dbo.Cities c ON p.CityId = c.CityId
    LEFT JOIN dbo.Places pl ON p.PlaceId = pl.PlaceId
    WHERE
        (@CityId IS NULL OR p.CityId = @CityId)
        AND (@PlaceName IS NULL OR pl.Name = @PlaceName)
        AND (@Type IS NULL OR p.Type = @Type)
        AND (@Gender IS NULL OR p.Gender = @Gender)
        AND (@PropertySearch IS NULL OR p.Title LIKE '%' + @PropertySearch + '%' OR p.Description LIKE '%' + @PropertySearch + '%')
        -- amenities filter: if provided, property must have at least one of the listed amenities
        AND (
            @AmenitiesCSV IS NULL
            OR EXISTS (
                SELECT 1 FROM dbo.PropertyAmenities pa
                INNER JOIN dbo.Amenities a ON pa.AmenityId = a.AmenityId
                WHERE pa.PropertyId = p.PropertyId
                  AND a.Name IN (
                       SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@AmenitiesCSV, ',')
                  )
            )
        );
END

--------------------------------------------------------SaveEnquiry_SP--------------------------------------

CREATE OR ALTER PROCEDURE SaveEnquiry_SP
    @Name NVARCHAR(100),
    @Contact NVARCHAR(50),
    @Email NVARCHAR(150),
    @City NVARCHAR(100),
    @Places NVARCHAR(500),
    @Type NVARCHAR(50),
    @Gender NVARCHAR(20),
    @Amenities NVARCHAR(500),
    @MoveInDate DATE = NULL,
    @PropertySearch NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Enquiries (Name, Contact, Email, City, Places, Type, Gender, Amenities, MoveInDate, PropertySearch)
    VALUES (@Name, @Contact, @Email, @City, @Places, @Type, @Gender, @Amenities, @MoveInDate, @PropertySearch);
 
    RETURN SCOPE_IDENTITY();
END

--------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE GetPropertyAmenities_SP
    @PropertyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT a.AmenityId, a.Name
    FROM dbo.PropertyAmenities pa
    INNER JOIN dbo.Amenities a ON pa.AmenityId = a.AmenityId
    WHERE pa.PropertyId = @PropertyId;

END

CREATE TABLE PGs (
    PGId INT PRIMARY KEY IDENTITY(1,1),
    PGName VARCHAR(100) NOT NULL,
    City VARCHAR(100) NOT NULL,
    Locality VARCHAR(100) NOT NULL,
    Type VARCHAR(50) NULL,
    Gender VARCHAR(20) NULL,
    Amenities VARCHAR(500) NULL,
    Rent DECIMAL(10,2) NULL,
    Description VARCHAR(500) NULL,
    ImageUrl VARCHAR(500) NULL
);
 
INSERT INTO PGs (PGName, City, Locality, Type, Gender, Amenities, Rent, Description, ImageUrl)
VALUES
('Elite PG', 'Bangalore', 'BTM', 'Coliving', 'Male', 'Wifi,AC,Parking', 6500, 'Near Bus Stop', '/images/pg1.jpg'),
('Comfort Stay', 'Bangalore', 'Koramangala', 'Student', 'Female', 'Wifi,Kitchen', 7500, 'Center Area', '/images/pg2.jpg'),
('Royal Residency', 'Chennai', 'Adyar', 'Coliving', 'Male', 'Wifi,PowerBackup', 5500, 'Near Market', '/images/pg3.jpg');
-----------------------------------------------------------------------------------------------------------------------------

CREATE or alter PROCEDURE GetPGDetails_SP
    @PGName VARCHAR(100)
AS
BEGIN
    SELECT PGName, City, Address, Rent
    FROM PGTable   -- your REAL table name
    WHERE PGName = @PGName
END

select * from Users

update Users set ResetToken = null where UserId = 1

CREATE TABLE PGTable
(
    PGID INT IDENTITY(1,1) PRIMARY KEY,
    PGName VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
    Address VARCHAR(200) NOT NULL,
    Rent DECIMAL(10,2) NOT NULL
);
 
INSERT INTO PGTable (PGName, City, Address, Rent)
VALUES 
('Sunshine PG', 'Vellore', 'Near CMC Hospital', 5500),
('Comfort Stay', 'Chennai', 'Anna Nagar', 7000),
('Happy Home PG', 'Bangalore', 'BTM Layout', 8000);

-------------------------------------------------------------Main---------------------------------------------------------------------------

CREATE DATABASE EasyPG
 
USE EasyPG
																    --Users
 
CREATE TABLE Users (
   UserID INT IDENTITY(1,1) PRIMARY KEY,
   FullName NVARCHAR(100) NOT NULL,
   Email NVARCHAR(150) UNIQUE NOT NULL,
   Gender NVARCHAR(10) NOT NULL,
   PhoneNo NVARCHAR(15) NOT NULL,
   Address NVARCHAR(300) NOT NULL,
   IDProofType NVARCHAR(50) NOT NULL,         -- Aadhar / Driving Licence
   IDProofNumber NVARCHAR(50) NOT NULL,
   Occupation NVARCHAR(30) NOT NULL,          -- Student / Working Professional
   PasswordHash NVARCHAR(500) NOT NULL,       -- Hashed Password
   Role NVARCHAR(20) NOT NULL DEFAULT 'User', -- User / Admin
   CreatedOn DATETIME DEFAULT GETDATE()
    CONSTRAINT FK_UsersPGListings FOREIGN KEY (PGID) REFERENCES PGListings(PGID))

																		--Admins
CREATE TABLE Admins (
    AdminID INT IDENTITY PRIMARY KEY,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    PhoneNo NVARCHAR(15),
    PasswordHash NVARCHAR(200) NOT NULL,
    Role NVARCHAR(20) DEFAULT 'Admin'
);

SELECT * FROM Users
select * from Admins
																			--PasswordResetRequests
 
CREATE TABLE PasswordResetRequests (
   ResetID INT IDENTITY(1,1) PRIMARY KEY,
   Email NVARCHAR(150) NOT NULL,
   NewPasswordHash NVARCHAR(500) NOT NULL,
   ResetDate DATETIME DEFAULT GETDATE()
);
 
																	--	PGListings
CREATE TABLE PGListings (
    PGID INT PRIMARY KEY IDENTITY,
    PGName NVARCHAR(100),
	AdminID int,
	PGAddress nvarchar(200),
    Location NVARCHAR(100),
    Type NVARCHAR(50),
    Rent DECIMAL(10,2),
    RoomType NVARCHAR(50),
    ImageURL NVARCHAR(255),
    Description NVARCHAR(MAX),

    CONSTRAINT FK_PGListingsAdmins FOREIGN KEY (AdminID) REFERENCES Admins(AdminID))


																		--PGBookingDetails

CREATE TABLE PGBookingDetails (
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    PGID INT NOT NULL,
    CheckInDate DATE NOT NULL,
    CheckOutDate DATE NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    PaymentStatus VARCHAR(20) DEFAULT 'Pending', -- Pending, Paid, Failed
    BookingStatus VARCHAR(20) DEFAULT 'Active',  -- Active, Cancelled, Completed
    CreatedAt DATETIME DEFAULT GETDATE(),

    -- Foreign Keys
    CONSTRAINT FK_Booking_User FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Booking_PG FOREIGN KEY (PGID) REFERENCES PGListings(PGID))


select * from Users
select * from Admins

select * from PasswordResetRequests
select * from PGListings

alter table PGListings add PGAddress nvarchar(200); 

insert into PGListings values ('SBA PG For Gents',Banglore)

ALTER TABLE Users 
ADD PGID INT [constraint];

ALTER TABLE Users
ADD CONSTRAINT FK_UsersPGListings
FOREIGN KEY (PGID) REFERENCES PGListings(PGID);

AdminID INT FOREIGN KEY REFERENCES 
 PGID INT FOREIGN KEY REFERENCES PGListings(PGID)


SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users';


INSERT INTO Users (FullName, Email, Gender, PhoneNo, Address, IDProofType, IDProofNumber, Occupation, PasswordHash, Role)
VALUES ('Admin User', 'admin@example.com', 'Male', '9999999999', 'Admin Address', 'Aadhar', '123456789012', 'Admin', 'admin123', 'Admin');




SELECT u.UserID, u.FullName, u.Email, u.PhoneNo, u.Gender,
       p.PGName, p.Location, p.Rent
FROM Users u
INNER JOIN PGListings p ON u.PGID = p.PGID
WHERE p.AdminID = 1;

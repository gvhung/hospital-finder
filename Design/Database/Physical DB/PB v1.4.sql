USE [master]
GO
/****** Object:  Database [HospitalF]    Script Date: 9/6/2014 11:35:53 PM ******/
CREATE DATABASE [HospitalF]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'HospitalF', FILENAME = N'C:\Program Files (x86)\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\HospitalF.mdf' , SIZE = 9216KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'HospitalF_log', FILENAME = N'C:\Program Files (x86)\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\HospitalF_log.ldf' , SIZE = 1792KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [HospitalF] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [HospitalF].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [HospitalF] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [HospitalF] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [HospitalF] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [HospitalF] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [HospitalF] SET ARITHABORT OFF 
GO
ALTER DATABASE [HospitalF] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [HospitalF] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [HospitalF] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [HospitalF] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [HospitalF] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [HospitalF] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [HospitalF] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [HospitalF] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [HospitalF] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [HospitalF] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [HospitalF] SET  DISABLE_BROKER 
GO
ALTER DATABASE [HospitalF] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [HospitalF] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [HospitalF] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [HospitalF] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [HospitalF] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [HospitalF] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [HospitalF] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [HospitalF] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [HospitalF] SET  MULTI_USER 
GO
ALTER DATABASE [HospitalF] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [HospitalF] SET DB_CHAINING OFF 
GO
ALTER DATABASE [HospitalF] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [HospitalF] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [HospitalF]
GO
/****** Object:  FullTextCatalog [Word]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE FULLTEXT CATALOG [Word]WITH ACCENT_SENSITIVITY = ON
AS DEFAULT

GO
/****** Object:  StoredProcedure [dbo].[SP_ADVANCED_SEARCH_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_ADVANCED_SEARCH_HOSPITAL]
	@CityID INT, -- ALWAYS NOT NULL
	@DistrictID INT,
	@SpecialityID INT,
	@DiseaseName NVARCHAR(64)
AS
BEGIN
	DECLARE @NumOfRecordInTemp INT = 0
	DECLARE @RowNum INT = 1
	DECLARE @TempHospitalID INT = 0

	-- DEFINE TEMPORARY TABLE THAT CONTAIN LIST OF HOSPITALS
	-- THAT CONTAIN SORT PRIORITY
	DECLARE @TempHospitalList TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,
										Hospital_ID INT)
						
	-- DEFINE TEMPORARY TABLE THAT CONTAIN LIST OF HOSPITALS
	-- THAT CONTAIN SORT PRIORITY
	DECLARE @ResultHospitalList TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,
										Hospital_ID INT,
										[Priority] INT)

	-- SET DEFAULT VALUES FOR INPUT PARAMETERS
	iF (@DistrictID = 0)
		SET @DistrictID = NULL

	IF (@SpecialityID = 0)
		SET @SpecialityID = NULL

	IF (@DiseaseName IS NOT NULL)
	BEGIN
		IF ([dbo].[FU_REMOVE_WHITE_SPACE](@DiseaseName) = '')
			SET @DiseaseName = NULL
	END

	DECLARE @DiseaseID INT = 0
	IF (@DiseaseName IS NOT NULL)
		BEGIN
			SET @DiseaseID = (SELECT Disease_ID
							  FROM Disease
							  WHERE Disease_Name = (N'%' + @DiseaseName + N'%'))
		END

	-- SET VALUE FOR 'WHAT' and 'WHERE' PHRASE
	DECLARE @WhatPhrase INT = NULL,
			@WherePhrase INT = 1

	IF (@SpecialityID IS NULL AND @DiseaseName IS NULL)
		SET @WhatPhrase = 0
	ELSE
		SET @WhatPhrase = 1

	DECLARE @SelectPhrase NVARCHAR(512) = NULL
	SET @SelectPhrase = N'SELECT DISTINCT h.Hospital_ID'

	DECLARE @FromPhrase NVARCHAR(512) = NULL
	SET @FromPhrase = N'FROM Hospital h'

	DECLARE @ConditionPhrase NVARCHAR(512) = NULL
	SET @ConditionPhrase = N'WHERE h.Is_Active = ''True'''

	DECLARE @OrderPhrase NVARCHAR(512)
	SET @OrderPhrase = N'ORDER BY h.Hospital_ID ASC'

	DECLARE @SqlQuery NVARCHAR(MAX) = NULL

	-- CASE THAT WHAT PHRASE IS NULL AND WHERE PHRASE HAVE VALUE(S)
	IF (@WhatPhrase = 0)
	BEGIN
		SET @ConditionPhrase += CASE WHEN @DistrictID IS NOT NULL
								THEN N' AND h.District_ID = @DistrictID'
								ELSE ''
								END;
		SET @ConditionPhrase += N' AND h.City_ID = @CityID'
			
		SET @SqlQuery = @SelectPhrase + CHAR(13) + @FromPhrase + CHAR(13) +
						@ConditionPhrase + CHAR(13) + @OrderPhrase

		INSERT INTO @TempHospitalList
		EXECUTE SP_EXECUTESQL @SqlQuery,
							  N'@CityID INT, @DistrictID INT',
							  @CityID, @DistrictID

		-- ASSGIN PRIORITY
		SELECT @NumOfRecordInTemp = (SELECT COUNT(*)
									 FROM (SELECT Hospital_ID
										   FROM @TempHospitalList) t)

		IF (@NumOfRecordInTemp > 0)
		BEGIN
			SET @RowNum = 1
			WHILE (@RowNum <= @NumOfRecordInTemp)
			BEGIN
				SELECT @TempHospitalID = (SELECT h.Hospital_ID
										  FROM (SELECT ROW_NUMBER()
												OVER (ORDER BY t.Hospital_ID ASC) AS RowNumber, t.Hospital_ID
												FROM @TempHospitalList t) AS h
										  WHERE RowNumber = @RowNum)

				INSERT INTO @ResultHospitalList
				SELECT @TempHospitalID,
					   [dbo].[RETURN_SORT_PRIORITY] (@TempHospitalID, 99, NULL, NULL)

				SET @RowNum += 1
			END
		END

		-- QUERY HOSPITAL
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
				h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
				h.Ordinary_End_Time, h.Coordinate, h.Full_Description,
				h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
				h.Rating, h.Rating_Count
		FROM Hospital h, @ResultHospitalList temp
		WHERE h.Hospital_ID = temp.Hospital_ID
		ORDER BY temp.[Priority] DESC

		RETURN;
	END
	
	-- CASE THAT WHAT PHRASE AND WHERE PHRASE HAVE VALUE
	IF (@WhatPhrase = 1)
	BEGIN
		SET @FromPhrase += CASE WHEN @DiseaseID IS NOT NULL AND @DiseaseID != 0
						   THEN N', Speciality_Disease sd'
						   ELSE ''
						   END;
		SET @FromPhrase += CASE WHEN (@SpecialityID IS NOT NULL) AND (@DiseaseID IS NOT NULL)
						   THEN N', Hospital_Speciality hs'
						   ELSE CASE WHEN (@SpecialityID IS NULL) AND (@DiseaseID IS NULL) 
									 THEN ''
									 ELSE N', Hospital_Speciality hs'
									 END
						   END;

		SET @ConditionPhrase += CASE WHEN @SpecialityID IS NOT NULL AND @SpecialityID != 0
								THEN N' AND hs.Speciality_ID = @SpecialityID'
								ELSE ''
								END;
		SET @ConditionPhrase += CASE WHEN @DiseaseID IS NOT NULL AND @DiseaseID != 0
								THEN N' AND sd.Disease_ID = @DiseaseID' +
									 N' AND hs.Speciality_ID = sd.Speciality_ID'
								ELSE ''
								END;
		SET @ConditionPhrase += CASE WHEN (@SpecialityID IS NOT NULL) AND (@DiseaseID IS NOT NULL)
								THEN N' AND h.Hospital_ID = hs.Hospital_ID'
								ELSE CASE WHEN (@SpecialityID IS NULL) AND (@DiseaseID IS NULL)
									 THEN ''
									 ELSE N' AND h.Hospital_ID = hs.Hospital_ID'
									 END
								END;

		SET @ConditionPhrase += N' AND h.City_ID = @CityID'
		SET @ConditionPhrase += CASE WHEN @DistrictID IS NOT NULL
								THEN N' AND h.District_ID = @DistrictID'
								ELSE ''
								END;

		SET @SqlQuery = @SelectPhrase + CHAR(13) + @FromPhrase + CHAR(13) +
						@ConditionPhrase + CHAR(13) + @OrderPhrase

		INSERT INTO @TempHospitalList
		EXECUTE SP_EXECUTESQL @SqlQuery,
							  N'@CityID INT, @DistrictID INT, @SpecialityID INT, @DiseaseID INT',
							  @CityID, @DistrictID, @SpecialityID, @DiseaseID

		-- ASSGIN PRIORITY
		SELECT @NumOfRecordInTemp = (SELECT COUNT(*)
									 FROM (SELECT Hospital_ID
										   FROM @TempHospitalList) t)

		IF (@NumOfRecordInTemp > 0)
		BEGIN
			SET @RowNum = 1
			WHILE (@RowNum <= @NumOfRecordInTemp)
			BEGIN
				SELECT @TempHospitalID = (SELECT h.Hospital_ID
										  FROM (SELECT ROW_NUMBER()
												OVER (ORDER BY t.Hospital_ID ASC) AS RowNumber, t.Hospital_ID
												FROM @TempHospitalList t) AS h
										  WHERE RowNumber = @RowNum)

				INSERT INTO @ResultHospitalList
				SELECT @TempHospitalID,
					   [dbo].[RETURN_SORT_PRIORITY] (@TempHospitalID, 99, NULL, NULL)

				SET @RowNum += 1
			END
		END

		-- QUERY HOSPITAL
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
				h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
				h.Ordinary_End_Time, h.Coordinate, h.Full_Description,
				h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
				h.Rating, h.Rating_Count
		FROM Hospital h, @ResultHospitalList temp
		WHERE h.Hospital_ID = temp.Hospital_ID
		ORDER BY temp.[Priority] DESC

		RETURN;
	END
END
GO
/****** Object:  StoredProcedure [dbo].[SP_CHANGE_DISEASE_STATUS]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_CHANGE_DISEASE_STATUS]
	@DiseaseID INT
AS
BEGIN
	DECLARE @CurrentStatus BIT = (SELECT Is_Active
								  FROM Disease
								  WHERE Disease_ID = @DiseaseID)

	IF (@CurrentStatus = 'True')
	BEGIN
		IF (NOT EXISTS(SELECT Disease_ID
					   FROM Speciality_Disease
					   WHERE Disease_ID = @DiseaseID))
		BEGIN
			UPDATE Disease
			SET Is_Active = 'False'
			WHERE Disease_ID = @DiseaseID
			RETURN @@ROWCOUNT;
		END
		ELSE
		BEGIN
			RETURN 2;
		END
	END
	ELSE
	BEGIN
		UPDATE Disease
		SET Is_Active = 'True'
		WHERE Disease_ID = @DiseaseID
		RETURN @@ROWCOUNT;
	END

	RETURN 0;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_CHANGE_FACILITY_STATUS]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_CHANGE_FACILITY_STATUS]
	@FacilityID INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @CurrentStatus BIT = (SELECT Is_Active
								  FROM Facility
								  WHERE Facility_ID = @FacilityID)

	IF (@CurrentStatus = 'True')
	BEGIN
		UPDATE Facility
		SET Is_Active = 'False'
		WHERE Facility_ID = @FacilityID
		RETURN @@ROWCOUNT;
	END
	ELSE
	BEGIN
		UPDATE Facility
		SET Is_Active = 'True'
		WHERE Facility_ID = @FacilityID
		RETURN @@ROWCOUNT;
	END

	RETURN 0;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_CHANGE_HOSPITAL_STATUS]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_CHANGE_HOSPITAL_STATUS]
	@HospitalID INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @CurrentStatus BIT = (SELECT Is_Active
								  FROM Hospital
								  WHERE Hospital_ID = @HospitalID)

	IF (@CurrentStatus = 'True')
	BEGIN
		UPDATE Hospital
		SET Is_Active = 'False'
		WHERE Hospital_ID = @HospitalID
		RETURN @@ROWCOUNT;
	END
	ELSE
	BEGIN
		UPDATE Hospital
		SET Is_Active = 'True'
		WHERE Hospital_ID = @HospitalID
		RETURN @@ROWCOUNT;
	END

	RETURN 0;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_CHANGE_SERVICE_STATUS]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_CHANGE_SERVICE_STATUS]
	@ServiceID INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @CurrentStatus BIT = (SELECT Is_Active
								  FROM [Service]
								  WHERE Service_ID = @ServiceID)

	IF (@CurrentStatus = 'True')
	BEGIN
		UPDATE [Service]
		SET Is_Active = 'False'
		WHERE Service_ID = @ServiceID
		RETURN @@ROWCOUNT;
	END
	ELSE
	BEGIN
		UPDATE [Service]
		SET Is_Active = 'True'
		WHERE Service_ID = @ServiceID
		RETURN @@ROWCOUNT;
	END

	RETURN 0;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_CHANGE_SPECIALITY_STATUS]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_CHANGE_SPECIALITY_STATUS]
	@SpecialityID INT
AS
BEGIN
	DECLARE @CurrentStatus BIT = (SELECT Is_Active
								  FROM Speciality
								  WHERE Speciality_ID = @SpecialityID)

	IF (@CurrentStatus = 'True')
	BEGIN
		UPDATE Speciality
		SET Is_Active = 'False'
		WHERE Speciality_ID = @SpecialityID
		RETURN @@ROWCOUNT;
	END
	ELSE
	BEGIN
		UPDATE Speciality
		SET Is_Active = 'True'
		WHERE Speciality_ID = @SpecialityID
		RETURN @@ROWCOUNT;
	END

	RETURN 0;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_CHECK_NOT_DUPLICATED_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_CHECK_NOT_DUPLICATED_HOSPITAL]
	@HospitalName NVARCHAR(128),
	@FullAddress NVARCHAR(64)
AS
BEGIN
	IF (EXISTS(SELECT h.Hospital_ID
			   FROM Hospital h
			   WHERE [dbo].[FU_REMOVE_WHITE_SPACE](h.[Address]) LIKE
					 N'%' + [dbo].[FU_REMOVE_WHITE_SPACE](@FullAddress) + N'%' AND
					 [dbo].[FU_REMOVE_WHITE_SPACE](h.Hospital_Name) LIKE
					 N'%' + [dbo].[FU_REMOVE_WHITE_SPACE](@HospitalName) + N'%'))
		RETURN 0;
	ELSE
		RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_CHECK_VALID_USER_IN_CHARGED]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_CHECK_VALID_USER_IN_CHARGED]
	@Email NVARCHAR(64)
AS
BEGIN
	IF (EXISTS(SELECT u.[User_ID]
			   FROM [User] u
			   WHERE u.Email = @Email AND
					 u.Hospital_ID IS NULL AND
					 u.Is_Active = 'True'))
		RETURN 1;
	ELSE
	BEGIN
		IF (EXISTS(SELECT u.[User_ID]
				   FROM [User] u
				   WHERE u.Email = @Email AND
						 u.Hospital_ID IS NOT NULL AND
						 u.Is_Active = 'True'))
			RETURN 2;
		ELSE
			RETURN 0;
	END
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_APPOINTMENT]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_INSERT_APPOINTMENT]
	@FullName nvarchar(32),
	@Gender bit,
	@Birthday date,
	@PhoneNo varchar(13),
	@Email varchar(64),
	@Date date,
	@Start_time time,
	@End_time time,
	@Doctor_ID int,
	@Hospital_ID int,
	@Confirm_Code varchar(8),
	@HealthInsuranceCode varchar(15),
	@SymptomDescription nvarchar(200)
AS
BEGIN
	BEGIN TRANSACTION
	INSERT INTO Appointment
		([Patient_Full_Name]
		,[Patient_Gender]
		,[Patient_Birthday]
		,[Patient_Phone_Number]
		,[Patient_Email]
		,[Appointment_Date]
		,[Start_Time]
		,[End_Time]
		,[In_Charge_Doctor]
		,[Curing_Hospital]
		,[Confirm_Code]
		,[Health_Insurance_Code]
		,[Symptom_Description]
		,[Is_Confirm]
		,[Is_Active])
	VALUES
		(@FullName
		,@Gender
		,@Birthday
		,@PhoneNo
		,@Email
		,@Date
		,@Start_time
		,@End_time
		,@Doctor_ID
		,@Hospital_ID
		,@Confirm_Code
		,@HealthInsuranceCode
		,@SymptomDescription
		,'False'
		,'False')
	IF @@ERROR <>0
	BEGIN
		ROLLBACK TRAN;
		RETURN 0;
	END
	COMMIT TRAN T;

	RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_DISEASE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_INSERT_DISEASE]
	@DiseaseName NVARCHAR(64),
	@SpecialityList NVARCHAR(4000)
AS
BEGIN
	BEGIN TRANSACTION T
	BEGIN TRY
		INSERT INTO Disease
		VALUES
		(
			@DiseaseName,
			'True'
		)

		-- SELECT DISEASE ID
		DECLARE @DiseaseID INT = (SELECT TOP 1 Disease_ID
								  FROM Disease
								  ORDER BY Disease_ID DESC)

		-- INSERT TO SPECIALITY_DISEASE TABLE
		IF (@SpecialityList != '')
		BEGIN
			DECLARE @RowNumber INT = 1
			DECLARE @TotalToken  INT = 0
			DECLARE @Token NVARCHAR(MAX)		

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|') TokenList)

			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)
				INSERT INTO Speciality_Disease
				(
					Speciality_ID,
					Disease_ID,
					Is_Active
				)
				VALUES
				(
					@Token,
					@DiseaseID,
					'True'
				)

				SET @RowNumber += 1
			END
		END

		COMMIT TRAN T;
		RETURN 1;
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN T
		RETURN 0;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_FACILITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_INSERT_FACILITY]
	@FacilityName NVARCHAR(64),
	@FacilityType INT
AS
BEGIN
	INSERT INTO Facility
	VALUES
	(
		@FacilityName,
		@FacilityType,
		'True'
	)

	IF @@ROWCOUNT = 0
		RETURN 0;
	ELSE
		RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_FEEDBACK]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_INSERT_FEEDBACK]
	@header nvarchar(64),
	@feedback_content nvarchar(256),
	@feedback_type int,
	@email varchar(64),
	@hospitalID int
AS
BEGIN
	BEGIN TRANSACTION
		DECLARE @created_date DATETIME = GETDATE()
		IF(@hospitalID=0)
		BEGIN
			SET @hospitalID=NULL;
		END
		INSERT INTO Feedback
		VALUES
		(@header
		,@feedback_content
		,@feedback_type
		,@email
		,@hospitalID
		,@created_date)
		IF @@ERROR <>0
		BEGIN
			ROLLBACK TRAN;
			RETURN 0;
		END
	COMMIT TRAN;
	RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_INSERT_HOSPITAL]
	@HospitalName NVARCHAR(64),
	@HospitalType INT,
	@Address NVARCHAR(128),
	@CityID INT,
	@DistrictID INT,
	@WardID INT,
	@PhoneNumber VARCHAR(64),
	@Fax VARCHAR(16),
	@Email VARCHAR(64),
	@Website VARCHAR(64),
	@HolidayStartTime NVARCHAR(7),
	@HolidayEndTime NVARCHAR(7),
	@OrdinaryStartTime NVARCHAR(7),
	@OrdinaryEndTime NVARCHAR(7),
	@Coordinate VARCHAR(26),
	@IsAllowAppointment BIT,
	@CreatedPerson INT,
	@FullDescription NVARCHAR(4000),
	@PersonInChared VARCHAR(64),
	@PhotoList NVARCHAR(4000),
	@TagInput NVARCHAR(4000),
	@SpecialityList NVARCHAR(4000),
	@ServiceList NVARCHAR(4000),
	@FacilityList NVARCHAR(4000)
AS
BEGIN
	BEGIN TRANSACTION T
	BEGIN TRY
	-- INSERT TO HOSPITAL TABLE
	BEGIN
		INSERT INTO Hospital
		(
			Hospital_Name,
			Hospital_Type,
			[Address],
			City_ID,
			District_ID,
			Ward_ID,
			Phone_Number,
			Fax,
			Email,
			Website,
			Holiday_Start_Time,
			Holiday_End_Time,
			Ordinary_Start_Time,
			Ordinary_End_Time,
			Is_Allow_Appointment,
			Full_Description,
			Coordinate,
			Created_Person,
			Is_Active
		)
		VALUES
		(
			@HospitalName,
			@HospitalType,
			@Address,
			@CityID,
			@DistrictID,
			@WardID,
			@PhoneNumber,
			@Fax,
			@Email,
			@Website,
			@HolidayStartTime,
			@HolidayEndTime,
			@OrdinaryStartTime,
			@OrdinaryEndTime,
			@IsAllowAppointment,
			@FullDescription,
			@Coordinate,
			@CreatedPerson,
			'True'
		)

		IF @@ROWCOUNT = 0
		BEGIN
			ROLLBACK TRAN T;
			RETURN 0;
		END

		-- SELECT HOSPITAL ID
		DECLARE @HospitalID INT = (SELECT TOP 1 Hospital_ID
								   FROM Hospital
								   ORDER BY Hospital_ID DESC)

		-- INSERT TO HOSPITAL_SPECIALITY TABLE
		IF (@SpecialityList != '')
		BEGIN
			DECLARE @RowNumber INT = 1
			DECLARE @TotalToken  INT = 0
			DECLARE @Token NVARCHAR(MAX)		

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|') TokenList)

			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)
				INSERT INTO Hospital_Speciality
				(
					Hospital_ID,
					Speciality_ID,
					Is_Main_Speciality,
					Is_Active
				)
				VALUES
				(
					@HospitalID,
					@Token,
					'False',
					'True'
				)

				SET @RowNumber += 1
			END
		END

		-- INSERT TO SERVCE TABLE
		IF (@ServiceList != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@ServiceList, '|') TokenList)

			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@ServiceList, '|') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)
				INSERT INTO Hospital_Service
				(
					Hospital_ID,
					Service_ID,
					Is_Active
				)
				VALUES
				(
					@HospitalID,
					@Token,
					'True'
				)

				SET @RowNumber += 1
			END
		END

		-- INSERT TO FACILITY TABLE
		IF (@FacilityList != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@FacilityList, '|') TokenList)

			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@FacilityList, '|') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)
				INSERT INTO Hospital_Facility
				(
					Hospital_ID,
					Facility_ID,
					Is_Active
				)
				VALUES
				(
					@HospitalID,
					@Token,
					'True'
				)

				SET @RowNumber += 1
			END
		END

		-- INSERT PERSON IN CHARGED
		IF (@PersonInChared != '')
		BEGIN
			UPDATE [User]
			SET Hospital_ID = @HospitalID
			WHERE [User_ID] = (SELECT [User_ID]
							   FROM [User]
							   WHERE Email = @PersonInChared)
		END

		-- INSERT TO PHOTO TABLE
		IF (@PhotoList != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@PhotoList, '|') TokenList)

			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@PhotoList, '|') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)

				INSERT INTO Photo
				(
					File_Path,
					Add_Date,
					Hospital_ID,
					Uploaded_Person,
					Is_Active
				)
				VALUES
				(
					@Token,
					GETDATE(),
					@HospitalID,
					@CreatedPerson,
					'True'
				)

				SET @RowNumber += 1
			END
		END

		-- INSERT TO WORD_DICTIONARY TABLE
		DECLARE @WordID INT = 0

		IF (EXISTS(SELECT Word_ID
				   FROM Tag
				   WHERE LOWER(Word) = LOWER(@HospitalName)))
		BEGIN
			SET @WordID = (SELECT Word_ID
						   FROM Tag
						   WHERE LOWER(Word) = LOWER(@HospitalName))

			IF (NOT EXISTS(SELECT *
						   FROM Tag_Hospital
						   WHERE Hospital_ID = @HospitalID AND
								 Word_ID = @WordID))
			BEGIN
				INSERT INTO Tag_Hospital
				VALUES(@WordID, @HospitalID)
			END
		END
		ELSE
		BEGIN
			INSERT INTO Tag
			VALUES(@HospitalName, 3)

			SET @WordID = (SELECT TOP 1 Word_ID
						   FROM Tag
						   ORDER BY Word_ID DESC)

			INSERT INTO Tag_Hospital
			VALUES(@WordID, @HospitalID)
		END

		-- CHECK IF THERE IS ADDITIONAL TAG WORDS
		IF (@TagInput != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@TagInput, ',') TokenList)

			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@TagInput, ',') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)

				SET @WordID = (SELECT TOP 1 Word_ID
							   FROM Tag
							   ORDER BY Word_ID DESC)

				IF (EXISTS(SELECT Word_ID
						   FROM Tag
						   WHERE LOWER(Word) = LOWER(@Token)))
				BEGIN
					SET @WordID = (SELECT Word_ID
								   FROM Tag
								   WHERE LOWER(Word) = LOWER(@Token))
				END
				ELSE
				BEGIN
					INSERT INTO Tag
					VALUES(@Token, 3)

					SET @WordID = (SELECT TOP 1 Word_ID
								   FROM Tag
								   ORDER BY Word_ID DESC)
				END

				-- INSERT TO WORD_HOSPITAL TABLE
				IF (NOT EXISTS(SELECT *
							   FROM Tag_Hospital
							   WHERE Hospital_ID = @HospitalID AND
									 Word_ID = @WordID))
				BEGIN
					INSERT INTO Tag_Hospital
					VALUES(@WordID, @HospitalID)
				END

				SET @RowNumber += 1
			END
		END
	END
	COMMIT TRAN T;

	RETURN 1;
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN T
		RETURN 0;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_HOSPITAL_EXCEL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_INSERT_HOSPITAL_EXCEL]
	@HospitalName NVARCHAR(64),
	@HospitalType INT,
	@FullAddress NVARCHAR(256),
	@CityID INT,
	@DistrictID INT,
	@WardID INT,
	@PhoneNumber VARCHAR(64),
	@Fax VARCHAR(16),
	@Email VARCHAR(64),
	@Website VARCHAR(64),
	@HolidayStartTime NVARCHAR(7),
	@HolidayEndTime NVARCHAR(7),
	@OrdinaryStartTime NVARCHAR(7),
	@OrdinaryEndTime NVARCHAR(7),
	@Coordinate VARCHAR(26),
	@IsAllowAppointment BIT,
	@CreatedPerson INT,
	@TagInput NVARCHAR(4000),
	@SpecialityList NVARCHAR(4000),
	@ServiceList NVARCHAR(4000),
	@FacilityList NVARCHAR(4000)
AS
BEGIN
	BEGIN TRANSACTION T
	BEGIN TRY
	-- INSERT TO HOSPITAL TABLE
	BEGIN
		INSERT INTO Hospital
		(
			Hospital_Name,
			Hospital_Type,
			[Address],
			City_ID,
			District_ID,
			Ward_ID,
			Phone_Number,
			Fax,
			Email,
			Website,
			Holiday_Start_Time,
			Holiday_End_Time,
			Ordinary_Start_Time,
			Ordinary_End_Time,
			Is_Allow_Appointment,
			Coordinate,
			Created_Person,
			Is_Active
		)
		VALUES
		(
			@HospitalName,
			@HospitalType,
			@FullAddress,
			@CityID,
			@DistrictID,
			@WardID,
			@PhoneNumber,
			@Fax,
			@Email,
			@Website,
			@HolidayStartTime,
			@HolidayEndTime,
			@OrdinaryStartTime,
			@OrdinaryEndTime,
			@IsAllowAppointment,
			@Coordinate,
			@CreatedPerson,
			'True'
		)

		IF @@ROWCOUNT = 0
		BEGIN
			ROLLBACK TRAN T;
			RETURN 0;
		END

		-- SELECT HOSPITAL ID
		DECLARE @HospitalID INT = (SELECT TOP 1 Hospital_ID
								   FROM Hospital
								   ORDER BY Hospital_ID DESC)

		-- INSERT TO HOSPITAL_SPECIALITY TABLE
		IF (@SpecialityList IS NOT NULL AND @SpecialityList != '')
		BEGIN
			DECLARE @RowNumber INT = 1
			DECLARE @TotalToken  INT = 0
			DECLARE @Token NVARCHAR(MAX)		
			DECLARE @SpecialityId INT = 0

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, ',') TokenList)

			IF (@TotalToken = 0)
			BEGIN
				SET @SpecialityId = (SELECT Speciality_ID
									 FROM Speciality
									 WHERE Speciality_Name = @SpecialityList)

				IF (@SpecialityId IS NOT NULL AND @SpecialityId != 0)
				BEGIN
					IF (NOT EXISTS(SELECT *
								   FROM Hospital_Speciality
								   WHERE Hospital_ID = @HospitalID AND
										 Speciality_ID = @SpecialityId))
					BEGIN
						INSERT INTO Hospital_Speciality
						(
							Hospital_ID,
							Speciality_ID,
							Is_Main_Speciality,
							Is_Active
						)
						VALUES
						(
							@HospitalID,
							@SpecialityId,
							'False',
							'True'
						)
					END
				END
			END
			ELSE
			BEGIN
				WHILE (@RowNumber <= @TotalToken)
				BEGIN
					SELECT @Token = (SELECT LTRIM(TokenList.Token)
									 FROM (SELECT ROW_NUMBER()
										   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
										   FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, ',') TokenList) AS TokenList
									 WHERE RowNumber = @RowNumber)

					SET @SpecialityId = (SELECT Speciality_ID
										 FROM Speciality
										 WHERE Speciality_Name = @Token)

					IF (@SpecialityId IS NOT NULL AND @SpecialityId != 0)
					BEGIN
						IF (NOT EXISTS(SELECT *
								   FROM Hospital_Speciality
								   WHERE Hospital_ID = @HospitalID AND
										 Speciality_ID = @SpecialityId))
						BEGIN
							INSERT INTO Hospital_Speciality
							(
								Hospital_ID,
								Speciality_ID,
								Is_Main_Speciality,
								Is_Active
							)
							VALUES
							(
								@HospitalID,
								@SpecialityId,
								'False',
								'True'
							)
						END		
					END

					SET @RowNumber += 1
				END
			END
		END

		-- INSERT TO SERVCE TABLE
		IF (@ServiceList IS NOT NULL AND @ServiceList != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0
			DECLARE @ServiceId INT = 0

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@ServiceList, ',') TokenList)

			IF (@TotalToken = 0)
			BEGIN
				SET @ServiceId = (SELECT Service_ID
								  FROM [Service]
								  WHERE [Service_Name] = @ServiceList)

				IF (@ServiceId IS NOT NULL AND @ServiceId != 0)
				BEGIN
					IF (NOT EXISTS(SELECT *
								   FROM Hospital_Service
								   WHERE Hospital_ID = @HospitalID AND
										 Service_ID = @ServiceId))
					BEGIN
						INSERT INTO Hospital_Service
						(
							Hospital_ID,
							Service_ID,
							Is_Active
						)
						VALUES
						(
							@HospitalID,
							@ServiceId,
							'True'
						)
					END			
				END	
			END
			ELSE
			BEGIN
				WHILE (@RowNumber <= @TotalToken)
				BEGIN
					SELECT @Token = (SELECT LTRIM(TokenList.Token)
									 FROM (SELECT ROW_NUMBER()
										   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
										   FROM [dbo].[FU_STRING_TOKENIZE] (@ServiceList, ',') TokenList) AS TokenList
									 WHERE RowNumber = @RowNumber)

					SET @ServiceId = (SELECT Service_ID
									  FROM [Service]
									  WHERE [Service_Name] = @Token)

					IF (@ServiceId IS NOT NULL AND @ServiceId != 0)
					BEGIN
						IF (NOT EXISTS(SELECT *
								   FROM Hospital_Service
								   WHERE Hospital_ID = @HospitalID AND
										 Service_ID = @ServiceId))
						BEGIN
							INSERT INTO Hospital_Service
							(
								Hospital_ID,
								Service_ID,
								Is_Active
							)
							VALUES
							(
								@HospitalID,
								@ServiceId,
								'True'
							)
						END
					END			

					SET @RowNumber += 1
				END
			END
		END

		-- INSERT TO FACILITY TABLE
		IF (@FacilityList IS NOT NULL AND @FacilityList != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0
			DECLARE @FacilityId INT

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@FacilityList, ',') TokenList)

			IF (@TotalToken = 0)
			BEGIN
				SET @FacilityId = (SELECT Facility_ID
								   FROM Facility
								   WHERE Facility_Name = @Token)

				IF (@FacilityId IS NOT NULL AND @FacilityId != 0)
				BEGIN
					IF (NOT EXISTS(SELECT *
								   FROM Hospital_Facility
								   WHERE Hospital_ID = @HospitalID AND
										 Facility_ID = @FacilityId))
					BEGIN
						INSERT INTO Hospital_Facility
						(
							Hospital_ID,
							Facility_ID,
							Is_Active
						)
						VALUES
						(
							@HospitalID,
							@FacilityId,
							'True'
						)
					END
				END
			END
			ELSE
			BEGIN
				WHILE (@RowNumber <= @TotalToken)
				BEGIN
					SELECT @Token = (SELECT LTRIM(TokenList.Token)
									 FROM (SELECT ROW_NUMBER()
										   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
										   FROM [dbo].[FU_STRING_TOKENIZE] (@FacilityList, ',') TokenList) AS TokenList
									 WHERE RowNumber = @RowNumber)

					SET @FacilityId = (SELECT Facility_ID
									   FROM Facility
									   WHERE Facility_Name = @Token)

					IF (@FacilityId IS NOT NULL AND @FacilityId != 0)
					BEGIN
						IF (NOT EXISTS(SELECT *
								   FROM Hospital_Facility
								   WHERE Hospital_ID = @HospitalID AND
										 Facility_ID = @FacilityId))
						BEGIN
							INSERT INTO Hospital_Facility
							(
								Hospital_ID,
								Facility_ID,
								Is_Active
							)
							VALUES
							(
								@HospitalID,
								@FacilityId,
								'True'
							)
						END
					END

					SET @RowNumber += 1
				END
			END		
		END

		-- INSERT TO WORD_DICTIONARY TABLE
		DECLARE @WordID INT = 0

		IF (EXISTS(SELECT Word_ID
				   FROM Tag
				   WHERE LOWER(Word) = LOWER(@HospitalName)))
		BEGIN
			SET @WordID = (SELECT Word_ID
						   FROM Tag
						   WHERE LOWER(Word) = LOWER(@HospitalName))

			IF (NOT EXISTS(SELECT *
						   FROM Tag_Hospital
						   WHERE Hospital_ID = @HospitalID AND
								 Word_ID = @WordID))
			BEGIN
				INSERT INTO Tag_Hospital
				VALUES(@WordID, @HospitalID)
			END
		END
		ELSE
		BEGIN
			INSERT INTO Tag
			VALUES(@HospitalName, 3)

			SET @WordID = (SELECT TOP 1 Word_ID
						   FROM Tag
						   ORDER BY Word_ID DESC)

			INSERT INTO Tag_Hospital
			VALUES(@WordID, @HospitalID)
		END

		-- CHECK IF THERE IS ADDITIONAL TAG WORDS
		IF (@TagInput IS NOT NULL AND @TagInput != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@TagInput, ',') TokenList)
			
			IF (@TotalToken = 0)
			BEGIN
				IF (NOT EXISTS(SELECT Word_ID
							   FROM Tag
							   WHERE LOWER(Word) = LOWER(@TagInput)))
				BEGIN
					INSERT INTO Tag
					VALUES(@TagInput, 3)

					SET @WordID = (SELECT TOP 1 Word_ID
								   FROM Tag
								   ORDER BY Word_ID DESC)

					-- INSERT TO WORD_HOSPITAL TABLE
					INSERT INTO Tag_Hospital
					VALUES(@WordID, @HospitalID)
				END
			END
			ELSE
			BEGIN
				WHILE (@RowNumber <= @TotalToken)
				BEGIN
					SELECT @Token = (SELECT LTRIM(TokenList.Token)
									 FROM (SELECT ROW_NUMBER()
										   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
										   FROM [dbo].[FU_STRING_TOKENIZE] (@TagInput, ',') TokenList) AS TokenList
									 WHERE RowNumber = @RowNumber)

					-- CHECK IF TOKEN IS NULL
					IF (@Token IS NOT NULL)
					BEGIN
						SET @WordID = (SELECT TOP 1 Word_ID
									   FROM Tag
									   ORDER BY Word_ID DESC)

						IF (EXISTS(SELECT Word_ID
								   FROM Tag
								   WHERE LOWER(Word) = LOWER(@Token)))
						BEGIN
							SET @WordID = (SELECT Word_ID
										   FROM Tag
										   WHERE LOWER(Word) = LOWER(@Token))
						END
						ELSE
						BEGIN
							INSERT INTO Tag
							VALUES(@Token, 3)

							SET @WordID = (SELECT TOP 1 Word_ID
										   FROM Tag
										   ORDER BY Word_ID DESC)
						END

						-- INSERT TO WORD_HOSPITAL TABLE
						IF (NOT EXISTS(SELECT *
									   FROM Tag_Hospital
									   WHERE Hospital_ID = @HospitalID AND
											 Word_ID = @WordID))
						BEGIN
							INSERT INTO Tag_Hospital
							VALUES(@WordID, @HospitalID)
						END
					END

					SET @RowNumber += 1
				END
			END		
		END
	END
	COMMIT TRAN T;

	RETURN 1;
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN T
		RETURN 0;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_HOSPITAL_USER]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_INSERT_HOSPITAL_USER]
	@Email NVARCHAR(64),
	@SecondaryEmail NVARCHAR(64),
	@Password NVARCHAR(32),
	@FirstName NVARCHAR(16),
	@LastName NVARCHAR(16),
	@PhoneNumber NVARCHAR(16),
	@ConfirmPerson INT
AS
BEGIN
	INSERT INTO [User]
	(
		Email,
		[Password],
		Secondary_Email,
		First_Name,
		Last_Name,
		Role_ID,
		Confirmed_Person,
		Phone_Number,
		Is_Active
	)
	VALUES
	(
		@Email,
		@Password,
		@SecondaryEmail,
		@FirstName,
		@LastName,
		3,
		@ConfirmPerson,
		@PhoneNumber,
		'True'
	)

	IF @@ROWCOUNT = 0
		RETURN 0;
	ELSE
		RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_SEARCH_QUERY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_INSERT_SEARCH_QUERY]
(
	@Search_Query NVARCHAR(100),
	@Result_Count INT,
	@Search_Date DATETIME
)
AS
BEGIN
	DECLARE @Sentece_ID INT
	SET @Sentece_ID = 0
	
	SELECT @Sentece_ID = sq.Sentence_ID
	FROM SearchQuery sq
	WHERE sq.Sentence LIKE @Search_Query
	
	IF (@Sentece_ID > 0)
	BEGIN
		UPDATE SearchQuery
		SET Search_Date = @Search_Date, Result_Count = @Result_Count, Search_Time_Count = Search_Time_Count + 1
		WHERE Sentence_ID = @Sentece_ID
		RETURN @Result_Count
	END
	ELSE
	BEGIN
		INSERT INTO SearchQuery(Sentence, Search_Date, Result_Count, Search_Time_Count)
		VALUES(@Search_Query, @Search_Date, @Result_Count, 1)
		RETURN @Result_Count
	END
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_SERVICE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_INSERT_SERVICE]
	@ServivceName NVARCHAR(64),
	@ServiceType INT
AS
BEGIN
	INSERT INTO [Service]
	VALUES
	(
		@ServivceName,
		@ServiceType,
		'True'
	)

	IF @@ROWCOUNT = 0
		RETURN 0;
	ELSE
		RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_SPECIALITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_INSERT_SPECIALITY]
	@SpecialityName NVARCHAR(64)
AS
BEGIN
	INSERT INTO Speciality
	VALUES
	(
		@SpecialityName,
		'True'
	)

	IF @@ROWCOUNT = 0
		RETURN 0;
	ELSE
		RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_DISEASE_IN_SPECIALITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_DISEASE_IN_SPECIALITY]
	@SpecialityID INT
AS
BEGIN
	SELECT d.Disease_ID, d.Disease_Name
	FROM Speciality_Disease s, Disease d
	WHERE s.Speciality_ID = @SpecialityID AND
		  s.Disease_ID = d.Disease_ID
END

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO LOAD ALL SPECIALITIES OF HOSPITAL
-- ANHDTH
IF OBJECT_ID('[SP_LOAD_SPECIALITY_BY_HOSPITALID]') IS NOT NULL
	DROP PROCEDURE [SP_LOAD_SPECIALITY_BY_HOSPITALID]

GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_DOCTOR_BY_SPECIALITYID]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_DOCTOR_BY_SPECIALITYID]
	@SpecialityID int,
	@hospitalID int
AS
BEGIN
	SELECT	D.Doctor_ID,D.First_Name,D.Last_Name,
			D.Degree,D.Experience,D.Photo_ID,D.Working_Day
	FROM	Doctor AS D, Doctor_Speciality AS DS,Doctor_Hospital AS DH
	WHERE	@SpecialityID = DS.Speciality_ID AND
			DS.Doctor_ID = D.Doctor_ID AND
			DH.Hospital_ID = @hospitalID AND
			D.Is_Active=1
	GROUP BY D.Doctor_ID,D.First_Name,D.Last_Name,
			D.Degree,D.Experience,D.Photo_ID,D.Working_Day
END
-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIP TO LOAD TOP 10 RATED HOSPITALS
-- SONNX
IF OBJECT_ID('[SP_TAKE_TOP_10_RATED_HOSPITAL]', 'P') IS NOT NULL
	DROP PROCEDURE [SP_TAKE_TOP_10_RATED_HOSPITAL]

GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_DOCTOR_IN_DOCTOR_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_DOCTOR_IN_DOCTOR_HOSPITAL]
	@hospitalID INT
AS
BEGIN
	SELECT		D.Doctor_ID,D.First_Name,D.Last_Name,
				D.Degree,D.Experience,D.Working_Day,D.Photo_ID
	FROM		Doctor_Hospital AS DH,Doctor AS D
	WHERE		@hospitalID = DH.Hospital_ID AND
				DH.Doctor_ID = D.Doctor_ID AND
				D.Is_Active=1
END

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
--Procedure load all facilities of hospital
--ANHDTH
IF OBJECT_ID ('SP_LOAD_FACILITY_IN_HOSPITAL_FACILITY') IS NOT NULL
	DROP PROCEDURE [SP_LOAD_FACILITY_IN_HOSPITAL_FACILITY]

GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_FACILITIES_BY_HOSPITAL_ID]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_LOAD_FACILITIES_BY_HOSPITAL_ID]
	@Hospital_ID INT
AS
BEGIN
	SELECT f.Facility_ID, f.Facility_Name, ft.Type_ID, ft.Type_Name, hf.Is_Active
	FROM Facility f
	LEFT JOIN FacilityType ft ON f.Facility_Type = ft.Type_ID
	LEFT JOIN Hospital_Facility hf ON f.Facility_ID = hf.Facility_ID AND hf.Hospital_ID = @Hospital_ID
	ORDER BY ft.Type_ID
END

GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_FACILITY_IN_HOSPITAL_FACILITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_FACILITY_IN_HOSPITAL_FACILITY]
	@hospitalID INT
AS
BEGIN
	SELECT	F.Facility_ID,F.Facility_Name,F.Facility_Type,FT.[Type_Name]
	FROM	Facility AS F,Hospital_Facility AS HF,FacilityType AS FT
	WHERE	F.Facility_ID = HF.Facility_ID AND
			F.Facility_Type=FT.[Type_ID] AND
			HF.Hospital_ID=@hospitalID
END
GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_HOSPITAL_LIST]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_HOSPITAL_LIST]
	@HospitalName NVARCHAR(128),
	@CityID INT,
	@DistrictID INT,
	@HospitalType INT,
	@IsActive BIT
AS
BEGIN
	DECLARE @RowsPerPage INT = 10

	DECLARE @SelectPhrase NVARCHAR(512) = NULL
	SET @SelectPhrase = N'SELECT h.Hospital_ID, h.Hospital_Name, h.[Address],' +
						N' ht.[Type_Name], h.Is_Active'
	
	DECLARE @ChildWherePHrase NVARCHAR(512) = N'WHERE ht.[Type_ID] = h.Hospital_Type'
	SET @ChildWherePHrase += CASE WHEN (@HospitalName IS NOT NULL OR @HospitalName != '')
							 THEN N' AND h.Hospital_Name LIKE N''%'' + @HospitalName + N''%'''
							 ELSE ''
							 END;
	SET @ChildWherePHrase += CASE WHEN @CityID != 0
							 THEN N' AND h.City_ID = @CityID'
							 ELSE ''
							 END;
	SET @ChildWherePHrase += CASE WHEN @DistrictID != 0
							 THEN N' AND h.District_ID = @DistrictID'
							 ELSE ''
							 END;
	SET @ChildWherePHrase += CASE WHEN @HospitalType != 0
							 THEN N' AND h.Hospital_Type = @HospitalType'
							 ELSE ''
							 END;
	SET @ChildWherePHrase += CASE WHEN @IsActive IS NOT NULL
							 THEN N' AND h.Is_Active = @IsActive'
							 ELSE ''
							 END;

	DECLARE @FromPhrase NVARCHAR(512) = NULL
	SET @FromPhrase = N'FROM Hospital h, HospitalType ht'

	DECLARE @SqlQuery NVARCHAR(1024) = NULL
	SET @SqlQuery = @SelectPhrase + CHAR(13) + @FromPhrase +
					CHAR(13) + @ChildWherePHrase

	EXECUTE SP_EXECUTESQL @SqlQuery,
						  N'@HospitalName NVARCHAR(128), @CityID INT, @DistrictID INT, @HospitalType INT, @IsActive BIT',
						  @HospitalName, @CityID, @DistrictID, @HospitalType, @IsActive
END
GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_HOSPITAL_TYPE_COUNT]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_HOSPITAL_TYPE_COUNT]
AS
BEGIN
	SELECT ht.Type_ID, ht.Type_Name, COUNT(*) AS HospitalType_Count
	FROM HospitalType ht
	LEFT JOIN Hospital h ON h.Hospital_Type = ht.Type_ID
	GROUP BY ht.Type_ID, ht.Type_Name
END

EXEC SP_LOAD_HOSPITAL_TYPE_COUNT
GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_SEARCH_QUERY_STATISTIC]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_LOAD_SEARCH_QUERY_STATISTIC]
(
	@From_Date DATETIME,
	@To_Date DATETIME
)
AS
BEGIN
	SELECT sq.Sentence, sq.Search_Time_Count, sq.Result_Count
	FROM SearchQuery sq
	WHERE sq.Search_Date BETWEEN @From_Date AND @To_Date
	ORDER BY sq.Search_Time_Count DESC, sq.Result_Count DESC
END
GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_SERVICE_IN_HOSPITAL_SERVICE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_SERVICE_IN_HOSPITAL_SERVICE]
	@hospitalID int
AS
BEGIN
	SELECT	S.Service_ID,S.[Service_Name],S.Service_Type,ST.[Type_Name]
	FROM	[Service] AS S, Hospital_Service AS HS,ServiceType AS ST
	WHERE	S.Service_ID=HS.Service_ID AND
			S.Service_Type=ST.[Type_ID] AND
			HS.Hospital_ID=@hospitalID
END
GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_SERVICES_BY_HOSPITAL_ID]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_LOAD_SERVICES_BY_HOSPITAL_ID]
	@Hospital_ID INT
AS
BEGIN
	SELECT s.Service_ID, s.Service_Name, st.Type_ID, st.Type_Name, hs.Is_Active
	FROM Service s
	LEFT JOIN ServiceType st ON s.Service_Type = st.Type_ID
	LEFT JOIN Hospital_Service hs ON s.Service_ID = hs.Service_ID AND hs.Hospital_ID = @Hospital_ID
	ORDER BY st.Type_ID
END

GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_SPECIALITY_IN_DOCTOR_SPECIALITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_SPECIALITY_IN_DOCTOR_SPECIALITY]
	@doctorID int
AS
BEGIN
	SELECT	S.Speciality_ID,S.Speciality_Name
	FROM	Speciality AS S,Doctor_Speciality AS DS
	WHERE	S.Speciality_ID=DS.Speciality_ID AND
			DS.Doctor_ID=@doctorID AND DS.Is_Active=1
END

GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_SPECIFIC_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_SPECIFIC_HOSPITAL]
	@HospitalID INT
AS
BEGIN
	SELECT h.Hospital_ID, h.Hospital_Name, h.Hospital_Type, h.[Address], h.Ward_ID, h.District_ID,
		   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
		   h.OrDinary_End_Time, h.Holiday_Start_Time, h.Holiday_End_Time, h.Rating_Count,
		   h.Coordinate, h.Full_Description, h.Rating,
		   h.Is_Allow_Appointment, h.Is_Active, h.Created_Person,
		   c.City_Name, d.[Type] + ' '+  d.District_Name AS District_Name,
		   w.[Type] + ' '  + w.Ward_Name AS Ward_Name
	FROM Hospital h, City c, District d, Ward w
	WHERE h.Hospital_ID = @HospitalID AND
		  h.City_ID = c.City_ID AND
		  h.District_ID = d.District_ID AND
		  h.Ward_ID = w.Ward_ID
END
GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_SUGGEST_SEARCH_QUERY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_LOAD_SUGGEST_SEARCH_QUERY]
(
	@Search_Query NVARCHAR(100)
)
AS
BEGIN
	SELECT TOP 10 Sentence, Search_Time_Count, Result_Count
	FROM SearchQuery
	WHERE Result_Count > 0 AND Sentence LIKE N'%' + @Search_Query + '%'
	GROUP BY Sentence, Search_Time_Count, Result_Count
	ORDER BY Search_Time_Count DESC, Result_Count DESC
END

EXEC SP_LOAD_SUGGEST_SEARCH_QUERY N'bệnh viện mắt'

GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_TOP_10_HOSPITAL_APPOINTMENT]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_TOP_10_HOSPITAL_APPOINTMENT]
	@From_Date DATE,
	@To_Date DATE
AS
BEGIN
	SELECT TOP 10 h.Hospital_ID, h.Hospital_Name, h.Address, h.Rating, h.Rating_Count, COUNT(*) AS Appointment_Count
	FROM Hospital h, Appointment a
	WHERE h.Hospital_ID = a.Curing_Hospital AND a.Appointment_Date BETWEEN @From_Date AND @To_Date
	GROUP BY h.Hospital_ID, h.Hospital_Name, h.Address, h.Rating, h.Rating_Count
	ORDER BY Appointment_Count DESC
END
GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_TYPE_OF_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_TYPE_OF_HOSPITAL]
	@hospitalID int
AS
BEGIN
	SELECT	T.Type_ID,T.Type_Name
	FROM	HospitalType AS T, Hospital AS H
	WHERE	T.Type_ID=H.Hospital_Type AND
			H.Hospital_ID=@hospitalID
END

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
--PROCEDURE TO SEARCH DOCTOR BY DOCTOR NAME AND SPECIALITY
--ANHDTH

IF OBJECT_ID('SP_SEARCH_DOCTOR') IS NOT NULL
	DROP PROCEDURE [SP_SEARCH_DOCTOR]

GO
/****** Object:  StoredProcedure [dbo].[SP_LOCATION_SEARCH_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOCATION_SEARCH_HOSPITAL]
	@Latitude FLOAT,
	@Longitude FLOAT,
	@Distance FLOAT	
AS
BEGIN
	SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
		   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
		   h.Ordinary_End_Time, h.Full_Description, h.Holiday_End_Time,
		   h.Is_Allow_Appointment, h.Is_Active, h.Coordinate, h.Holiday_Start_Time, h.Rating,
		   c.City_Name, d.District_Name, w.Ward_Name,
		   [dbo].[FU_GET_DISTANCE] 
			(CONVERT(FLOAT, SUBSTRING(h.Coordinate, 1, CHARINDEX(',', h.Coordinate) - 1)),
			 CONVERT(FLOAT, SUBSTRING(h.Coordinate, CHARINDEX(',', h.Coordinate) + 1, LEN(h.Coordinate))),
			 @Latitude, @Longitude) AS Distance
		   
	FROM City c, District d, Ward w, Hospital h
	WHERE h.Is_Active = 'True' AND
		  h.City_ID = c.City_ID AND h.District_ID = d.District_ID AND h.Ward_ID = w.Ward_ID AND
		  [dbo].[FU_GET_DISTANCE] 
			(CONVERT(FLOAT, SUBSTRING(h.Coordinate, 1, CHARINDEX(',', h.Coordinate) - 1)),
			 CONVERT(FLOAT, SUBSTRING(h.Coordinate, CHARINDEX(',', h.Coordinate) + 1, LEN(h.Coordinate))),
			 @Latitude, @Longitude) <= CONVERT(INT, @Distance)
	ORDER BY Distance
END

GO
/****** Object:  StoredProcedure [dbo].[SP_NORMAL_SEARCH_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_NORMAL_SEARCH_HOSPITAL]
	@WhatPhrase NVARCHAR(128),
	@CityID INT,
	@DistrictID INT
AS
BEGIN
	-- DEFINE @WherePhrase
	DECLARE @WherePhrase INT
	IF (@CityID != 0 OR @DistrictID != 0)
		SET @WherePhrase = 1
	ELSE
		SET @WherePhrase = 0

	-- DEFINE INDEX NUMBER FOR SORT ORDER
	DECLARE @ExactlyIndexOfTag INT = 1
	DECLARE @ExactlyIndexOfSpeciality INT = 2
	DECLARE @ExactlyIndexOfDisease INT = 3

	DECLARE @RelativeIndexOfTag INT = 8
	DECLARE @RelativeIndexOfSpeciality INT = 9
	DECLARE @RelativeIndexOfDisease INT = 10
	
	DECLARE @NonDiacriticIndexOfTag INT = 11
	DECLARE @NonDiacriticIndexOfSpeciality INT = 12
	DECLARE @NonDiacriticIndexOfDisease INT = 13

	-- DEFINE PRIORITY OF SORT ORDER
	DECLARE @ExactlyPriorityOfCity INT = 10000
	DECLARE @ExactlyPriorityOfDistrict INT = 10000

	DECLARE @PriorityOfRatingPoint INT = 1000
	DECLARE @PriorityOfRatingCount INT = 100

	-- DEFINE SUPPORT VARIABLES
	DECLARE @RowNum INT = 1
	DECLARE @TempHospitalID INT = 0
	DECLARE @TempMatchedIndex INT = 0
	DECLARE @RatingPoint FLOAT
	DECLARE @RatingCount INT
	DECLARE @NonDiacriticWhatPhrase NVARCHAR(4000) =
			[dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE] (@WhatPhrase)

	-- DEFINE TEMPORARY TABLE THAT CONTAIN LIST OF HOSPITALS
	-- THAT CONTAINS MATCHED RESULT INDEX
	DECLARE @TempHospitalList TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,
									Hospital_ID INT,
									[Index] INT)

	-- CHECK IF WHAT PHRASE IS NOT NULL
	IF (@WhatPhrase != '')
	BEGIN
	-- REMOVE NOISE WORD FROM WHAT PHRASE---------------------------------------------------------
		
	SET @WhatPhrase = REPLACE(@WhatPhrase, N'bệnh viện', N'')
	SET @WhatPhrase = REPLACE(@WhatPhrase, N'bệnh', N'')
	SET @WhatPhrase = REPLACE(@WhatPhrase, N'khám', N'')
	SET @WhatPhrase = REPLACE(@WhatPhrase, N'chữa', N'')
	SET @WhatPhrase = REPLACE(REPLACE(REPLACE(@WhatPhrase,' ','<>'),'><',''),'<>',' ')
	SET @NonDiacriticWhatPhrase = REPLACE(@NonDiacriticWhatPhrase, N'benh vien', N'')
	SET @NonDiacriticWhatPhrase = REPLACE(@NonDiacriticWhatPhrase, N'benh', N'')
	SET @NonDiacriticWhatPhrase = REPLACE(@NonDiacriticWhatPhrase, N'kham', N'')
	SET @NonDiacriticWhatPhrase = REPLACE(REPLACE(REPLACE(@NonDiacriticWhatPhrase,' ','<>'),'><',''),'<>',' ')

	-- QUERY FROM TAG TABLE-----------------------------------------------------------------------
	
		-- FIND EXACTLY MATCHING TAGS WORD
		DECLARE @NumOfHospitalFoundByExactlyTag INT = 0
		SET @NumOfHospitalFoundByExactlyTag = (SELECT COUNT (Word_ID)
											   FROM Tag
											   WHERE [Type] = 3 AND
													 (N'%' + Word + N'%' LIKE N'%' + @WhatPhrase + N'%' OR
													  N'%' + @WhatPhrase + N'%' LIKE N'%' + Word + N'%'))

		IF (@NumOfHospitalFoundByExactlyTag > 0)
		BEGIN
			INSERT INTO @TempHospitalList (Hospital_ID, [Index])
			SELECT DISTINCT wh.Hospital_ID, @ExactlyIndexOfTag
			FROM Tag w, Tag_Hospital wh
			WHERE w.Word_ID = wh.Word_ID AND 
				  w.[Type] = 3 AND
				  (N'%' + Word + N'%' LIKE N'%' + @WhatPhrase + N'%' OR
				   N'%' + @WhatPhrase + N'%' LIKE N'%' + Word + N'%')
		END
		-- FIND RELATIVE MATCHING TAGS WORD
		ELSE
		BEGIN
			DECLARE @NumOfHospitalFoundByRelativeTag INT = 0

			-- DIACRITIC VIETNAMSESE
			SET @NumOfHospitalFoundByRelativeTag = 
				(SELECT DISTINCT  COUNT(wh.Hospital_ID)
				 FROM Tag w, Tag_Hospital wh
				 WHERE w.Word_ID = wh.Word_ID AND
					   w.[Type] = 3 AND
					   FREETEXT (w.Word, @WhatPhrase))

			IF (@NumOfHospitalFoundByRelativeTag > 0)
			BEGIN
				-- INSERT TO @TempHospitalList
				INSERT INTO @TempHospitalList (Hospital_ID, [Index])
				SELECT DISTINCT wh.Hospital_ID, @RelativeIndexOfTag
				FROM Tag w, Tag_Hospital wh
				WHERE w.Word_ID = wh.Word_ID AND 
					  w.[Type] = 3 AND
					  FREETEXT (w.Word,  @WhatPhrase)
					  
			END
			-- NON-DIACRITIC VIETNAMESE
			ELSE
			BEGIN
				INSERT INTO @TempHospitalList (Hospital_ID, [Index])
				SELECT DISTINCT wh.Hospital_ID, @NonDiacriticIndexOfTag
				FROM [NON_DIACRITIC_TAG] w, Tag_Hospital wh
				WHERE w.Word_ID = wh.Word_ID AND
					  FREETEXT (w.Word, @WhatPhrase)		  
			END
		END

	-- QUERY FROM SPECIALITY TABLE----------------------------------------------------------------

		-- FIND EXACTLY SPECIALITY
		DECLARE @NumOfHospitalFoundByExactlySpeciality INT = 0
		SET @NumOfHospitalFoundByExactlySpeciality = (SELECT COUNT(Speciality_ID)
													  FROM Speciality
													  WHERE N'%' + Speciality_Name + N'%' LIKE N'%' + @WhatPhrase + N'%' OR
															N'%' + @WhatPhrase + N'%' LIKE N'%' + Speciality_Name + N'%')

		IF (@NumOfHospitalFoundByExactlySpeciality > 0)
		BEGIN
			-- INSERT TO @TempHospitalList
			INSERT INTO @TempHospitalList (Hospital_ID, [Index])
			SELECT DISTINCT h.Hospital_ID, @ExactlyIndexOfSpeciality
			FROM Speciality s, Hospital h, Hospital_Speciality hs
			WHERE h.Hospital_ID = hs.Hospital_ID AND
				  hs.Speciality_ID = s.Speciality_ID AND
				  (N'%' + s.Speciality_Name + N'%' LIKE N'%' + @WhatPhrase + N'%' OR
				   N'%' + @WhatPhrase + N'%' LIKE N'%' + s.Speciality_Name + N'%')
		END
		-- FIND RELATIVE MATCHING SPECIALITY
		ELSE
		BEGIN
			DECLARE @NumOfHospitalFoundByRelativeSpeciality INT = 0

			-- DIACRITIC VIETNAMSESE
			SET @NumOfHospitalFoundByRelativeSpeciality = 
					(SELECT COUNT(s.Speciality_ID)
					 FROM Speciality s, Hospital h, Hospital_Speciality hs
					 WHERE h.Hospital_ID = hs.Hospital_ID AND
						   hs.Speciality_ID = s.Speciality_ID AND 
						   FREETEXT (s.Speciality_Name, @WhatPhrase))

			IF (@NumOfHospitalFoundByRelativeSpeciality > 0)
			BEGIN
				-- INSERT TO @TempHospitalList
				INSERT INTO @TempHospitalList (Hospital_ID, [Index])
				SELECT DISTINCT h.Hospital_ID, @RelativeIndexOfSpeciality
				FROM Speciality s, Hospital h, Hospital_Speciality hs
				WHERE h.Hospital_ID = hs.Hospital_ID AND
					  hs.Speciality_ID = s.Speciality_ID AND 
					  FREETEXT (s.Speciality_Name, @WhatPhrase)
			END
			-- NON-DIACRITIC VIETNAMESE
			ELSE
			BEGIN
				INSERT INTO @TempHospitalList (Hospital_ID, [Index])
				SELECT DISTINCT h.Hospital_ID, @NonDiacriticIndexOfSpeciality
				FROM [NON_DIACRITIC_SPECIALITY] s, Hospital h, Hospital_Speciality hs
				WHERE h.Hospital_ID = hs.Hospital_ID AND
					  hs.Speciality_ID = s.Speciality_ID AND
					  FREETEXT (s.Speciality_Name, @WhatPhrase)  
			END
		END

	-- QUERY FROM DISEASE TABLE-------------------------------------------------------------------

		-- FIND EXACTLY DISEASE
		DECLARE @NumOfHospitalFoundByExactlyDesease INT = 0
		SET @NumOfHospitalFoundByExactlyDesease = (SELECT COUNT(Disease_ID)
												   FROM Disease
												   WHERE N'%' + Disease_Name + N'%' LIKE N'%' + @WhatPhrase + N'%'OR
														 N'%' + @WhatPhrase + N'%' LIKE N'%' + Disease_Name + N'%')

		IF (@NumOfHospitalFoundByExactlyDesease > 0)
		BEGIN
			-- INSERT TO @TempHospitalList
			INSERT INTO @TempHospitalList (Hospital_ID, [Index])
			SELECT DISTINCT h.Hospital_ID, @ExactlyIndexOfDisease
			FROM Disease d, Speciality_Disease sd,
				 Hospital h, Hospital_Speciality hs, Speciality s
			WHERE h.Hospital_ID = hs.Hospital_ID AND
				  hs.Speciality_ID = s.Speciality_ID AND
				  s.Speciality_ID = sd.Speciality_ID AND
				  sd.Disease_ID = d.Disease_ID AND
				  (N'%' + Disease_Name + N'%' LIKE N'%' + @WhatPhrase + N'%' OR
				   N'%' + @WhatPhrase + N'%' LIKE N'%' + Disease_Name + N'%') 
		END
		-- FIND RELATIVE MATCHING DISEASE
		ELSE
		BEGIN
			DECLARE @NumOfHospitalFoundByRelativeDisease INT = 0
		
			-- DIACRITIC VIETNAMSESE
			SET @NumOfHospitalFoundByRelativeDisease = 
					(SELECT COUNT(d.Disease_ID)
					 FROM Disease d, Speciality_Disease sd,
						  Hospital h, Hospital_Speciality hs, Speciality s
					 WHERE h.Hospital_ID = hs.Hospital_ID AND
						   hs.Speciality_ID = s.Speciality_ID AND
						   s.Speciality_ID = sd.Speciality_ID AND
						   sd.Disease_ID = d.Disease_ID AND
						   FREETEXT (Disease_Name, @WhatPhrase))

			IF (@NumOfHospitalFoundByRelativeDisease > 0)
			BEGIN
				-- INSERT TO @TempHospitalList
				INSERT INTO @TempHospitalList (Hospital_ID, [Index])
				SELECT DISTINCT h.Hospital_ID, @RelativeIndexOfDisease 
				FROM Disease d, Speciality_Disease sd,
					 Hospital h, Hospital_Speciality hs, Speciality s
				WHERE h.Hospital_ID = hs.Hospital_ID AND
					  hs.Speciality_ID = s.Speciality_ID AND
					  s.Speciality_ID = sd.Speciality_ID AND
					  sd.Disease_ID = d.Disease_ID AND
					  FREETEXT (Disease_Name, @WhatPhrase)
			END
			-- NON-DIACRITIC VIETNAMESE
			ELSE
			BEGIN
				INSERT INTO @TempHospitalList (Hospital_ID, [Index])
				SELECT DISTINCT h.Hospital_ID, @NonDiacriticIndexOfDisease
				FROM [NON_DIACRITIC_DISEASE] d, Speciality_Disease sd,
					 Hospital h, Hospital_Speciality hs, Speciality s
				WHERE h.Hospital_ID = hs.Hospital_ID AND
					  hs.Speciality_ID = s.Speciality_ID AND
					  s.Speciality_ID = sd.Speciality_ID AND
					  sd.Disease_ID = d.Disease_ID AND
					  FREETEXT(d.Disease_Name, @WhatPhrase)
			END
		END
	END
----------------------------------------------------------------------------------------------

	-- DEFINE TEMPORARY TABLE THAT CONTAIN LIST OF HOSPITALS
	-- THAT CONTAIN SORT PRIORITY
	DECLARE @ResultList TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,
							  Hospital_ID INT,
							  [Priority] INT)

	---- CHECK IF THERE IS AT LEAST ONE RECORD IN @TempHospitalList
	DECLARE @NumOfRecordInTemp INT = 0;
	SELECT @NumOfRecordInTemp = (SELECT COUNT(Hospital_ID)
								 FROM @TempHospitalList)
	IF (@NumOfRecordInTemp > 0)
	BEGIN
		INSERT INTO @ResultList
		SELECT t.Hospital_ID,
			   t.[Priority] + CONVERT(INT, [dbo].[FU_TAKE_RATING_POINT] (t.Hospital_ID) * @PriorityOfRatingPoint) +
							  CONVERT(INT, [dbo].[FU_TAKE_RATING_COUNT] (t.Hospital_ID) * @PriorityOfRatingCount)
		FROM (SELECT t.Hospital_ID, 
					 SUM([dbo].[RETURN_SORT_PRIORITY]
						(t.Hospital_ID, t.[Index], @WhatPhrase, @NonDiacriticWhatPhrase)) AS [Priority]
			  FROM @TempHospitalList t
			  GROUP BY t.Hospital_ID) t
	END

	-- CHECK IF WHERE PHRASE IS AVAILABLE
	IF (@WherePhrase != 0)
	BEGIN
		IF (@NumOfRecordInTemp > 0)
		BEGIN
			-- CHECK IF BOTH CITY AND DISTRICT ARE NOT NULL
			IF (@CityID != 0 AND @DistrictID != 0)
			BEGIN
				SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
					   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
					   h.Ordinary_End_Time, h.Coordinate, h.Full_Description,
					   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
					   h.Rating, h.Rating_Count
				FROM Hospital h, @ResultList temp
				WHERE h.Hospital_ID = temp.Hospital_ID AND
					  h.City_ID = @CityID AND
					  h.District_ID = @DistrictID AND
					  h.Is_Active = 'True'
				ORDER BY temp.[Priority] DESC
				RETURN;
			END

			-- CHECK IF CITY IS NOT NULL
			IF (@CityID != 0)
			BEGIN
				SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
					   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
					   h.Ordinary_End_Time, h.Coordinate, h.Full_Description,
					   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
					   h.Rating, h.Rating_Count
				FROM Hospital h, @ResultList temp
				WHERE h.Hospital_ID = temp.Hospital_ID AND
					  h.City_ID = @CityID AND
					  h.Is_Active = 'True'
				ORDER BY temp.[Priority] DESC
				RETURN;
			END

			-- CHECK IF DISTRICT IS NOT NULL
			IF (@DistrictID != 0)
			BEGIN
				SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
					   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
					   h.Ordinary_End_Time, h.Coordinate, h.Full_Description,
					   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
					   h.Rating, h.Rating_Count
				FROM Hospital h, @ResultList temp
				WHERE h.Hospital_ID = temp.Hospital_ID AND
					  h.District_ID = @DistrictID AND
					  h.Is_Active = 'True'
				ORDER BY temp.[Priority] DESC
				RETURN;
			END
		END
		ELSE
		BEGIN
			-- CHECK IF BOTH CITY AND DISTRICT ARE NOT NULL
			IF (@CityID != 0 AND @DistrictID != 0)
			BEGIN
				SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
					   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
					   h.Ordinary_End_Time, h.Coordinate, h.Full_Description,
					   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
					   h.Rating, h.Rating_Count
				FROM Hospital h
				WHERE h.City_ID = @CityID AND
					  h.District_ID = @DistrictID AND
					  h.Is_Active = 'True'
				ORDER BY [dbo].[FU_TAKE_RATING_POINT] (h.Hospital_ID) +
						 [dbo].[FU_TAKE_RATING_COUNT] (h.Hospital_ID) +
						 @ExactlyPriorityOfCity + @ExactlyPriorityOfDistrict DESC
				RETURN;
			END

			-- CHECK IF CITY IS NOT NULL
			IF (@CityID != 0)
			BEGIN
				SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
					   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
					   h.Ordinary_End_Time, h.Coordinate, h.Full_Description,
					   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
					   h.Rating, h.Rating_Count
				FROM Hospital h
				WHERE h.City_ID = @CityID AND
					  h.Is_Active = 'True'
				ORDER BY [dbo].[FU_TAKE_RATING_POINT] (h.Hospital_ID) +
						 [dbo].[FU_TAKE_RATING_COUNT] (h.Hospital_ID) +
						 @ExactlyPriorityOfCity DESC
				RETURN;
			END

			-- CHECK IF DISTRICT IS NOT NLL
			IF (@DistrictID != 0)
			BEGIN
				SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
					   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
					   h.Ordinary_End_Time, h.Coordinate, h.Full_Description,
					   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
					   h.Rating, h.Rating_Count
				FROM Hospital h
				WHERE h.District_ID = @DistrictID AND
					  h.Is_Active = 'True'
				ORDER BY [dbo].[FU_TAKE_RATING_POINT] (h.Hospital_ID) +
						 [dbo].[FU_TAKE_RATING_COUNT] (h.Hospital_ID) +
						 @ExactlyPriorityOfDistrict DESC
				RETURN;
			END
		END
	END
	-- THERE IS NO WHERE PHRASE
	ELSE
	BEGIN
		IF (@NumOfRecordInTemp > 0)
		BEGIN
			SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
				   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
				   h.Ordinary_End_Time, h.Coordinate, h.Full_Description,
				   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
				   h.Rating
			FROM Hospital h, @ResultList temp
			WHERE h.Hospital_ID = temp.Hospital_ID AND
				  h.Is_Active = 'True'
			ORDER BY temp.[Priority] DESC
			RETURN;
		END
		ELSE
		BEGIN
			RETURN;
		END		
	END
END
GO
/****** Object:  StoredProcedure [dbo].[SP_RATE_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_RATE_HOSPITAL]
(
	@User_ID INT,
	@Hospital_ID INT,
	@Score INT
)
AS
BEGIN
	IF (1 <= @Score AND @Score <= 5)
	BEGIN
		DECLARE @Check INT
		SET @Check = 0
		SELECT @Check = COUNT(r.Rating_ID)
		FROM Rating r
		WHERE r.Hospital_ID = @Hospital_ID AND r.Created_Person = @User_ID
		
		BEGIN TRAN
		BEGIN TRY
			IF (@Check > 0)
				BEGIN
					UPDATE Rating
					SET Score = @Score
					WHERE Hospital_ID = @Hospital_ID AND Created_Person = @User_ID
				END
			ELSE
				BEGIN
					INSERT INTO Rating (Score, Hospital_ID, Created_Person)
					VALUES (@Score, @Hospital_ID, @User_ID)
				END
			
			DECLARE @Average_Score FLOAT
			SET @Average_Score = [dbo].[FU_CALCULATE_AVERAGE_RATING] (@Hospital_ID)
			
			DECLARE @Rating_Count INT
			SELECT @Rating_Count = COUNT(r.Rating_ID)
			FROM Rating r
			WHERE r.Hospital_ID = @Hospital_ID
			
			UPDATE Hospital
			SET Rating = @Average_Score, Rating_Count = @Rating_Count
			WHERE Hospital_ID = @Hospital_ID
						
			COMMIT TRAN
			RETURN @Rating_Count
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
			RETURN -1
		END CATCH		
	END
END

GO
/****** Object:  StoredProcedure [dbo].[SP_SEARCH_DOCTOR]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_SEARCH_DOCTOR]
	@doctorName NVARCHAR(64),
	@specialityID INT,
	@hospitalID INT
AS
BEGIN
	IF(@doctorName='')
		SET @doctorName=NULL
	IF(@specialityID=0)
		SET @specialityID=NULL
		
	IF(@doctorName IS NULL)
		BEGIN
			SELECT	D.Doctor_ID,D.First_Name,D.Last_Name,
					D.Degree,D.Experience,D.Photo_ID,D.Working_Day
			FROM	Doctor AS D, Doctor_Speciality AS DS,Doctor_Hospital AS DH
			WHERE	@SpecialityID = DS.Speciality_ID AND
					DS.Doctor_ID = D.Doctor_ID AND
					DH.Hospital_ID = @hospitalID AND
					D.Is_Active=1
			GROUP BY D.Doctor_ID,D.First_Name,D.Last_Name,
					D.Degree,D.Experience,D.Photo_ID,D.Working_Day
		END
	ELSE
		BEGIN
			IF(@specialityID IS NULL)
				BEGIN
					SELECT	D.Doctor_ID,D.First_Name,D.Last_Name,
							D.Degree,D.Experience,D.Photo_ID,D.Working_Day
					FROM	Doctor AS D,Doctor_Hospital AS DH
					WHERE	D.Last_Name+' '+D.First_Name LIKE N'%'+@doctorName+'%' AND
							DH.Hospital_ID = @hospitalID AND
							D.Doctor_ID=dh.Doctor_ID AND
							D.Is_Active=1
					GROUP BY D.Doctor_ID,D.First_Name,D.Last_Name,
							D.Degree,D.Experience,D.Photo_ID,D.Working_Day,DH.Hospital_ID
					RETURN;
				END
			ELSE -- search doctor by doctor name and speciality
				BEGIN
					SELECT	*
					FROM	
						(SELECT	D.Doctor_ID,D.First_Name,D.Last_Name,
								D.Degree,D.Experience,D.Photo_ID,D.Working_Day
						FROM	Doctor AS D, Doctor_Speciality AS DS,Doctor_Hospital AS DH
						WHERE	@SpecialityID = DS.Speciality_ID AND
								DS.Doctor_ID = D.Doctor_ID AND
								DH.Hospital_ID = @hospitalID AND
								D.Is_Active=1
						GROUP BY D.Doctor_ID,D.First_Name,D.Last_Name,
								D.Degree,D.Experience,D.Photo_ID,D.Working_Day) AS T
					WHERE		T.Last_Name+' '+T.First_Name LIKE N'%'+@doctorName+'%' 
					RETURN;
				END
		END
END

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO CHANGE STATUS OF A SPECIFIC HOSPITAL
-- SONNX
IF OBJECT_ID('SP_CHANGE_HOSPITAL_STATUS', 'P') IS NOT NULL
	DROP PROCEDURE [SP_CHANGE_HOSPITAL_STATUS]

GO
/****** Object:  StoredProcedure [dbo].[SP_TAKE_DISEASE_AND_TYPE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_TAKE_DISEASE_AND_TYPE]
	@DiseaseName NVARCHAR(128),
	@IsActive BIT,
	@Mode INT,
	@SpecialityID INT
AS
BEGIN
	DECLARE @TempDiseaseList TABLE(ID INT IDENTITY(1,1) PRIMARY KEY,
								   Disease_ID INT,
								   Disease_Name NVARCHAR(128),
								   Is_Active BIT,
								   Speciality_Name NVARCHAR(512),
								   Speciality_ID INT)

	DECLARE @SelectPhrase NVARCHAR(512) = NULL
	IF (@Mode = 0)
	BEGIN
		SET @SelectPhrase = N'SELECT d.Disease_ID, d.Disease_Name, d.Is_Active'
	END
	IF (@Mode = 1 OR @Mode = 2 OR @Mode = 3)
	BEGIN
		SET @SelectPhrase = N'SELECT d.Disease_ID, d.Disease_Name, d.Is_Active, s.Speciality_Name, s.Speciality_ID'
	END
	
	DECLARE @FromPhrase NVARCHAR(512) = NULL
	IF (@Mode = 0)
	BEGIN
		SET @FromPhrase = N'FROM Disease d'
	END
	IF (@Mode = 1 OR @Mode = 2)
	BEGIN
		SET @FromPhrase = N'FROM Disease d, Speciality s, Speciality_Disease sd'
	END
	IF (@Mode = 3)
	BEGIN
		SET @FromPhrase = N'FROM Disease d, Speciality s, Speciality_Disease sd,' +
						  N' (SELECT Disease_ID' +
						  N'  FROM Speciality_Disease sd' +
						  N'  GROUP BY sd.Disease_ID' +
						  N'  HAVING COUNT(*) > 1) t'
	END

	DECLARE @WherePhrase NVARCHAR(512) = N'WHERE d.Is_Active = @IsActive'
	IF (@Mode = 0)
	BEGIN
		SET @WherePhrase += CASE WHEN (@DiseaseName IS NOT NULL OR @DiseaseName != '')
							THEN N' AND NOT EXISTS(SELECT sd.Disease_ID' +
												N' FROM Speciality_Disease sd' +
												N' WHERE d.Disease_ID = sd.Disease_ID)' +
								 N' AND d.Disease_Name LIKE N''%'' + @DiseaseName + N''%'''
							ELSE N' AND NOT EXISTS(SELECT sd.Disease_ID' +
												N' FROM Speciality_Disease sd' +
												N' WHERE d.Disease_ID = sd.Disease_ID)'
							END;
	END
	IF (@Mode = 1)
	BEGIN
		SET @WherePhrase += CASE WHEN (@DiseaseName IS NOT NULL OR @DiseaseName != '')
							THEN N' AND d.Disease_Name LIKE N''%'' + @DiseaseName + N''%''' +
								 N' AND d.Disease_ID = sd.Disease_ID' +
								 N' AND sd.Speciality_ID = s.Speciality_ID' 
							ELSE N' AND d.Disease_ID = sd.Disease_ID' +
								 N' AND sd.Speciality_ID = s.Speciality_ID' 
							END;
	END
	IF (@Mode = 2)
	BEGIN
		SET @WherePhrase += CASE WHEN (@DiseaseName IS NOT NULL OR @DiseaseName != '')
							THEN N' AND d.Disease_Name LIKE N''%'' + @DiseaseName + N''%''' +
								 N' AND d.Disease_ID = sd.Disease_ID' +
								 N' AND sd.Speciality_ID = s.Speciality_ID' +
								 N' AND s.Speciality_ID = @SpecialityID'
							ELSE N' AND d.Disease_ID = sd.Disease_ID' +
								 N' AND sd.Speciality_ID = s.Speciality_ID' +
								 N' AND s.Speciality_ID = @SpecialityID'
							END;
	END
	IF (@Mode = 3)
	BEGIN
		SET @WherePhrase += CASE WHEN (@DiseaseName IS NOT NULL OR @DiseaseName != '')
							THEN N' AND d.Disease_Name LIKE N''%'' + @DiseaseName + N''%''' +
								 N' AND d.Disease_ID = t.Disease_ID' +
								 N' AND sd.Disease_ID = d.Disease_ID' +
								 N' AND s.Speciality_ID = sd.Speciality_ID' 
							ELSE N' AND d.Disease_ID = t.Disease_ID' +
								 N' AND sd.Disease_ID = d.Disease_ID' +
								 N' AND s.Speciality_ID = sd.Speciality_ID'
							END;
	END
	
	DECLARE @OrderPhrase NVARCHAR(512) = NULL
	SET @OrderPhrase = N'ORDER BY d.Disease_Name ASC'

	DECLARE @SqlQuery NVARCHAR(1024) = NULL
	SET @SqlQuery = @SelectPhrase + CHAR(13) + @FromPhrase +
					CHAR(13) + @WherePhrase +
					CHAR(13) + @OrderPhrase

	-- DISPLAY RESULT IN CASE @Mode = 0
	IF (@Mode = 0)
	BEGIN
		EXECUTE SP_EXECUTESQL @SqlQuery,
				N'@IsActive BIT, @DiseaseName NVARCHAR(128), @Mode INT, @SpecialityID INT',
				@IsActive, @DiseaseName, @Mode, @SpecialityID
		RETURN;
	END

	-- DISPLAY RESULT IN CASE @Mode = 1 OR @Mode = 2 OR @Mode = 3
	INSERT INTO @TempDiseaseList
	EXECUTE SP_EXECUTESQL @SqlQuery,
			N'@IsActive BIT, @DiseaseName NVARCHAR(128), @Mode INT, @SpecialityID INT',
			@IsActive, @DiseaseName, @Mode, @SpecialityID

	DECLARE @ResultDiseaseList TABLE(Disease_ID INT PRIMARY KEY,
									 Disease_Name NVARCHAR(128),
									 Is_Active BIT,
									 Speciality_Name NVARCHAR(512),
									 Speciality_ID INT)
	DECLARE @NumberOfRecord INT =
			(SELECT COUNT(ID)
			 FROM @TempDiseaseList)

	IF (@NumberOfRecord > 0)
	BEGIN
		DECLARE @RowNum INT = 1
		DECLARE @TempDiseaseID INT = 0
		DECLARE @TempSpeciliatyName NVARCHAR(512)
		WHILE (@RowNum <= @NumberOfRecord)
		BEGIN
			SELECT @TempDiseaseID = (SELECT h.Disease_ID
									 FROM (SELECT ROW_NUMBER()
										   OVER (ORDER BY t.Disease_ID ASC) AS RowNumber, t.Disease_ID
										   FROM @TempDiseaseList t) AS h
									 WHERE RowNumber = @RowNum)

			SELECT @TempSpeciliatyName = (SELECT h.Speciality_Name
										  FROM (SELECT ROW_NUMBER()
												OVER (ORDER BY t.Disease_ID ASC) AS RowNumber, t.Speciality_Name
												FROM @TempDiseaseList t) AS h
										  WHERE RowNumber = @RowNum)

			-- CHECK IF HOSPITAL ID HAS BEEN EXISTED IN @ResultDiseaseList
			IF (NOT EXISTS (SELECT r.Disease_ID
							FROM @ResultDiseaseList r
							WHERE r.Disease_ID = @TempDiseaseID))
			BEGIN
				INSERT INTO @ResultDiseaseList
				SELECT h.Disease_ID, h.Disease_Name, h.Is_Active, h.Speciality_Name, h.Speciality_ID
				FROM (SELECT ROW_NUMBER()
					  OVER (ORDER BY t.Disease_ID ASC) AS RowNumber, t.Disease_ID,
						   t.Disease_Name, t.Is_Active, t.Speciality_Name, t.Speciality_ID
					  FROM @TempDiseaseList t) AS h
				WHERE RowNumber = @RowNum
			END
			ELSE
			BEGIN
				-- UPDATE VALUE OF PRIORITY
				UPDATE @ResultDiseaseList
				SET Speciality_Name = (SELECT Speciality_Name
									   FROM @ResultDiseaseList
									   WHERE Disease_ID = @TempDiseaseID) +
									   ', ' + @TempSpeciliatyName
				WHERE Disease_ID = @TempDiseaseID
			END

			SET @RowNum += 1
		END
	END

	SELECT *
	FROM @ResultDiseaseList
	ORDER BY Disease_Name ASC
END

GO
/****** Object:  StoredProcedure [dbo].[SP_TAKE_FACILITY_AND_TYPE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_TAKE_FACILITY_AND_TYPE]
	@FacilityName NVARCHAR(128),
	@FacilityType INT,
	@IsActive BIT
AS
BEGIN
	DECLARE @SelectPhrase NVARCHAR(512) = NULL
	SET @SelectPhrase = N'SELECT f.Facility_ID, f.Facility_Name, t.[Type_Name],' +
						N' t.[Type_ID], f.Is_Active'

	DECLARE @FromPhrase NVARCHAR(512) = NULL
	SET @FromPhrase = N'FROM Facility f, FacilityType t'

	DECLARE @WherePhrase NVARCHAR(512) = N'WHERE f.Facility_Type = t.[Type_ID]'
	SET @WherePhrase += CASE WHEN (@FacilityName IS NOT NULL OR @FacilityName != '')
						THEN N' AND f.Facility_Name LIKE N''%'' + @FacilityName + N''%'''
						ELSE ''
						END;
	SET @WherePhrase += CASE WHEN @FacilityType != 0
						THEN N' AND f.Facility_Type = @FacilityType'
						ELSE ''
						END;
	SET @WherePhrase += CASE WHEN @IsActive IS NOT NULL
						THEN N' AND f.Is_Active = @IsActive'
						ELSE ''
						END;

	DECLARE @OrderPhrase NVARCHAR(512) = NULL
	SET @OrderPhrase = N'ORDER BY t.[Type_ID] ASC'

	DECLARE @SqlQuery NVARCHAR(1024) = NULL
	SET @SqlQuery = @SelectPhrase + CHAR(13) + @FromPhrase +
					CHAR(13) + @WherePhrase +
					CHAR(13) + @OrderPhrase

	EXECUTE SP_EXECUTESQL @SqlQuery,
			N'@FacilityName NVARCHAR(128), @FacilityType INT, @IsActive BIT',
			@FacilityName, @FacilityType, @IsActive
END

GO
/****** Object:  StoredProcedure [dbo].[SP_TAKE_SERVICE_AND_TYPE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_TAKE_SERVICE_AND_TYPE]
	@ServiceName NVARCHAR(128),
	@ServiceType INT,
	@IsActive BIT
AS
BEGIN
	DECLARE @SelectPhrase NVARCHAR(512) = NULL
	SET @SelectPhrase = N'SELECT s.Service_ID, s.[Service_Name], t.[Type_Name],' +
						N' t.[Type_ID], s.Is_Active'

	DECLARE @FromPhrase NVARCHAR(512) = NULL
	SET @FromPhrase = N'FROM [Service] s, ServiceType t'

	DECLARE @WherePhrase NVARCHAR(512) = N'WHERE s.Service_Type = t.[Type_ID]'
	SET @WherePhrase += CASE WHEN (@ServiceName IS NOT NULL OR @ServiceName != '')
						THEN N' AND s.[Service_Name] LIKE N''%'' + @ServiceName + N''%'''
						ELSE ''
						END;
	SET @WherePhrase += CASE WHEN @ServiceType != 0
						THEN N' AND s.Service_Type = @ServiceType'
						ELSE ''
						END;
	SET @WherePhrase += CASE WHEN @IsActive IS NOT NULL
						THEN N' AND s.Is_Active = @IsActive'
						ELSE ''
						END;

	DECLARE @OrderPhrase NVARCHAR(512) = NULL
	SET @OrderPhrase = N'ORDER BY t.[Type_ID] ASC'

	DECLARE @SqlQuery NVARCHAR(1024) = NULL
	SET @SqlQuery = @SelectPhrase + CHAR(13) + @FromPhrase +
					CHAR(13) + @WherePhrase +
					CHAR(13) + @OrderPhrase

	EXECUTE SP_EXECUTESQL @SqlQuery,
			N'@ServiceName NVARCHAR(128), @ServiceType INT, @IsActive BIT',
			@ServiceName, @ServiceType, @IsActive
END
GO
/****** Object:  StoredProcedure [dbo].[SP_TAKE_SPECIALITY_AND_TYPE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_TAKE_SPECIALITY_AND_TYPE]
	@SpecialityName NVARCHAR(128),
	@IsActive BIT
AS
BEGIN
	DECLARE @SelectPhrase NVARCHAR(512) = NULL
	SET @SelectPhrase = N'SELECT s.Speciality_ID, s.Speciality_Name, s.Is_Active'

	DECLARE @FromPhrase NVARCHAR(512) = NULL
	SET @FromPhrase = N'FROM Speciality s'

	DECLARE @WherePhrase NVARCHAR(512) = N'WHERE Is_Active = @IsActive'
	SET @WherePhrase += CASE WHEN (@SpecialityName IS NOT NULL OR @SpecialityName != '')
						THEN N' AND s.Speciality_Name LIKE N''%'' + @SpecialityName + N''%'''
						ELSE ''
						END;

	DECLARE @OrderPhrase NVARCHAR(512) = NULL
	SET @OrderPhrase = N'ORDER BY s.Speciality_Name ASC'

	DECLARE @SqlQuery NVARCHAR(1024) = NULL
	SET @SqlQuery = @SelectPhrase + CHAR(13) + @FromPhrase +
					CHAR(13) + @WherePhrase +
					CHAR(13) + @OrderPhrase

	EXECUTE SP_EXECUTESQL @SqlQuery,
			N'@IsActive BIT, @SpecialityName NVARCHAR(128)',
			@IsActive, @SpecialityName
END
GO
/****** Object:  StoredProcedure [dbo].[SP_TAKE_TOP_10_RATED_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_TAKE_TOP_10_RATED_HOSPITAL]
AS
BEGIN
	SELECT TOP 10 h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, 
		   h.District_ID, h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website,
		   h.Ordinary_Start_Time, h.Ordinary_End_Time, h.Coordinate, h.Short_Description,
		   h.Full_Description, h.Is_Allow_Appointment,
		   [dbo].[FU_CALCULATE_AVERAGE_RATING](h.Hospital_ID) AS AverageScore
	FROM Hospital h
	WHERE Is_Active = 'True'
	ORDER BY ([dbo].[FU_CALCULATE_AVERAGE_RATING](h.Hospital_ID)) DESC
END
GO
/****** Object:  StoredProcedure [dbo].[SP_UPDATE_DISEASE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_UPDATE_DISEASE]
	@DiseaseID INT,
	@DiseaseName NVARCHAR(64),
	@SpecialityList NVARCHAR(4000)
AS
BEGIN
	BEGIN TRANSACTION T
	BEGIN TRY
		UPDATE Disease
		SET Disease_Name = @DiseaseName
		WHERE Disease_ID = @DiseaseID

		-- UPDATE SPECIALITY_DISEASE TABLE
		IF (@SpecialityList != '')
		BEGIN
			DECLARE @RowNumber INT = 1
			DECLARE @TotalToken INT = 0
			DECLARE @Token VARCHAR(4)
			DECLARE @TotalSpeciality INT = 0
			DECLARE @TempSpecialityID INT = 0
			DECLARE @TempSpecialityName NVARCHAR(256) = N''

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|') TokenList)

			SELECT @TotalSpeciality = (SELECT COUNT(Speciality_ID)
									   FROM Speciality_Disease
									   WHERE Disease_ID = @DiseaseID)

			-- UPDATE IS_ACTIVE STATUS FROM 'TRUE' TO 'FALSE'
			IF (@TotalSpeciality > @TotalToken)
			BEGIN
				SET @RowNumber = 1
				WHILE (@RowNumber <= @TotalSpeciality)
				BEGIN
					SELECT @TempSpecialityID = (SELECT hs.Speciality_ID
												FROM (SELECT ROW_NUMBER()
													  OVER (ORDER BY hs.Speciality_ID ASC) AS RowNumber, hs.Speciality_ID
													  FROM Speciality_Disease hs
													  WHERE Disease_ID = @DiseaseID) AS hs
												WHERE RowNumber = @RowNumber)
					SELECT @TempSpecialityName = (SELECT Speciality_Name
												  FROM Speciality
												  WHERE Speciality_ID = @TempSpecialityID)
					IF (NOT EXISTS(SELECT Token
								   FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|')
								   WHERE [dbo].[FU_REMOVE_WHITE_SPACE] (Token) = 
										 [dbo].[FU_REMOVE_WHITE_SPACE] (@TempSpecialityName)))
					BEGIN
						DELETE FROM Speciality_Disease
						WHERE Speciality_ID = @TempSpecialityID AND
							  Disease_ID = @DiseaseID
					END

					SET @RowNumber += 1
				END
			END
		END

		-- UPDATE IS_ACTIVE STATUS FROM 'FALSE' TO 'TRUE' AND MAPPING NEW SPECIALITY
		IF (@TotalSpeciality < @TotalToken)
		BEGIN
			SET @RowNumber = 1
			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)

				IF (NOT EXISTS(SELECT ds.Disease_ID
							FROM Speciality_Disease ds
							WHERE ds.Speciality_ID = @Token AND
								  ds.Disease_ID = @DiseaseID))
				BEGIN
					-- INSERT NEW SPECIALITY
					INSERT INTO Speciality_Disease
					(
						Speciality_ID,
						Disease_ID,
						Is_Active
					)
					VALUES
					(
						@Token,
						@DiseaseID,
						'True'
					)
				END

				SET @RowNumber += 1
			END
		END

		COMMIT TRAN T;
		RETURN 1;
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN T
		RETURN 0;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[SP_UPDATE_FACILITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_UPDATE_FACILITY]
	@FacilityID INT,
	@FacilityName NVARCHAR(64),
	@FacilityType INT
AS
BEGIN
	UPDATE Facility
	SET Facility_Name = @FacilityName,
		Facility_Type = @FacilityType
	WHERE Facility_ID = @FacilityID

	IF @@ROWCOUNT = 0
		RETURN 0;
	ELSE
		RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_UPDATE_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_UPDATE_HOSPITAL]
	@HospitalID INT,
	@HospitalName NVARCHAR(64),
	@HospitalType INT,
	@Address NVARCHAR(128),
	@CityID INT,
	@DistrictID INT,
	@WardID INT,
	@PhoneNumber VARCHAR(64),
	@Fax VARCHAR(16),
	@Email VARCHAR(64),
	@Website VARCHAR(64),
	@HolidayStartTime NVARCHAR(7),
	@HolidayEndTime NVARCHAR(7),
	@OrdinaryStartTime NVARCHAR(7),
	@OrdinaryEndTime NVARCHAR(7),
	@Coordinate VARCHAR(26),
	@IsAllowAppointment BIT,
	@CreatedPerson INT,
	@FullDescription NVARCHAR(MAX),
	@SpecialityList NVARCHAR(4000),
	@ServiceList NVARCHAR(4000),
	@FacilityList NVARCHAR(4000),
	@TagInput NVARCHAR(4000),
	@PhotoList NVARCHAR(MAX)
AS
BEGIN
	BEGIN TRANSACTION T
	BEGIN TRY
		DECLARE @HospitalNameWordID INT =
			(SELECT t.Word_ID
			 FROM Tag_Hospital th, Tag t
			 WHERE th.Hospital_ID = 90 AND
				   t.Word = N'Nhà tui')

		-- UPDATE HOSPITAL TABLE
		BEGIN
			DECLARE @OldHospitalName NVARCHAR(128) =
				(SELECT Hospital_Name
				 FROM Hospital
				 WHERE Hospital_ID = @HospitalID)

			IF (@OldHospitalName != @HospitalName)
			BEGIN
				UPDATE Tag
				SET Word = @HospitalName
				WHERE Word_ID = @HospitalNameWordID
			END

			UPDATE Hospital
			SET Hospital_Name = @HospitalName,
				Hospital_Type = @HospitalType,
				[Address] = @Address,
				City_ID = @CityID,
				District_ID = @DistrictID,
				Ward_ID = @WardID,
				Phone_Number = @PhoneNumber,
				Fax = @Fax,
				Email = @Email,
				Website = @Website,
				Holiday_Start_Time = @HolidayStartTime,
				Holiday_End_Time = @HolidayEndTime,
				Ordinary_Start_Time = @OrdinaryStartTime,
				Ordinary_End_Time = @OrdinaryEndTime,
				Is_Allow_Appointment = @IsAllowAppointment,
				Full_Description = @FullDescription,
				Coordinate = @Coordinate
			WHERE Hospital_ID = @HospitalID

			IF @@ROWCOUNT = 0
			BEGIN
				ROLLBACK TRAN T;
				RETURN 0;
			END
		END

		-- UPDATE SPECIALITY TABLE
		IF (@SpecialityList != '')
		BEGIN
			DECLARE @RowNumber INT = 1
			DECLARE @TotalToken INT = 0
			DECLARE @Token NVARCHAR(256)
			DECLARE @TotalSpeciality INT = 0
			DECLARE @TempSpecialityID INT = 0
			DECLARE @TempSpecialityName NVARCHAR(256) = N''

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|') TokenList)

			SELECT @TotalSpeciality = (SELECT COUNT(Hospital_ID)
									   FROM Hospital_Speciality
									   WHERE Hospital_ID = @HospitalID)

			-- UPDATE IS_ACTIVE STATUS FROM 'TRUE' TO 'FALSE'
			IF (@TotalSpeciality > @TotalToken)
			BEGIN
				SET @RowNumber = 1
				WHILE (@RowNumber <= @TotalSpeciality)
				BEGIN
					SELECT @TempSpecialityID = (SELECT hs.Speciality_ID
											   FROM (SELECT ROW_NUMBER()
													 OVER (ORDER BY hs.Speciality_ID ASC) AS RowNumber, hs.Speciality_ID
													 FROM Hospital_Speciality hs
													 WHERE  Hospital_ID = @HospitalID) AS hs
											   WHERE RowNumber = @RowNumber)
					SELECT @TempSpecialityName = (SELECT Speciality_Name
												  FROM Speciality
												  WHERE Speciality_ID = @TempSpecialityID)
					IF (NOT EXISTS(SELECT Token
								   FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|')
								   WHERE [dbo].[FU_REMOVE_WHITE_SPACE] (Token) = 
										 [dbo].[FU_REMOVE_WHITE_SPACE] (@TempSpecialityName)))
					BEGIN
						DELETE FROM Hospital_Speciality
						WHERE Speciality_ID = @TempSpecialityID AND
							  Hospital_ID = @HospitalID
					END

					SET @RowNumber += 1
				END
			END

			-- UPDATE IS_ACTIVE STATUS FROM 'FALSE' TO 'TRUE' AND MAPPING NEW SPECIALITY
			IF (@TotalSpeciality < @TotalToken)
			BEGIN
				SET @RowNumber = 1
				WHILE (@RowNumber <= @TotalToken)
				BEGIN
					SELECT @Token = (SELECT TokenList.Token
									 FROM (SELECT ROW_NUMBER()
										   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
										   FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|') TokenList) AS TokenList
									 WHERE RowNumber = @RowNumber)

					-- CHECK STATUS OF SPECIALITY IN HOSPITAL
					IF (NOT EXISTS(SELECT hs.Hospital_ID
									FROM Hospital_Speciality hs
									WHERE hs.Speciality_ID = @Token AND
											hs.Hospital_ID = @HospitalID))
					BEGIN
						-- INSERT NEW SPECIALITY
						INSERT INTO Hospital_Speciality
						(
							Hospital_ID,
							Speciality_ID,
							Is_Main_Speciality,
							Is_Active
						)
						VALUES
						(
							@HospitalID,
							@Token,
							'False',
							'True'
						)
					END

					SET @RowNumber += 1
				END
			END	
		END
		ELSE
		BEGIN
			DELETE FROM Hospital_Speciality
			WHERE Hospital_ID = @HospitalID
		END

		-- UPDATE SERVICE TABLE
		IF (@ServiceList != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0
			SET @Token = N''
			DECLARE @TotalService INT = 0
			DECLARE @TempServiceID INT = 0
			DECLARE @TempServiceName NVARCHAR(256) = N''

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@ServiceList, '|') TokenList)

			SELECT @TotalService = (SELECT COUNT(Hospital_ID)
									FROM Hospital_Service
									WHERE Hospital_ID = @HospitalID)

			-- UPDATE IS_ACTIVE STATUS FROM 'TRUE' TO 'FALSE'
			IF (@TotalService > @TotalToken)
			BEGIN
				SET @RowNumber = 1
				WHILE (@RowNumber <= @TotalService)
				BEGIN
					SELECT @TempServiceID = (SELECT hs.Service_ID
											 FROM (SELECT ROW_NUMBER()
												   OVER (ORDER BY hs.Service_ID ASC) AS RowNumber, hs.Service_ID
												   FROM Hospital_Service hs
												   WHERE  Hospital_ID = @HospitalID) AS hs
											 WHERE RowNumber = @RowNumber)
					SELECT @TempServiceName = (SELECT [Service_Name]
											   FROM [Service]
											   WHERE Service_ID = @TempServiceID)
					IF (NOT EXISTS(SELECT Token
								   FROM [dbo].[FU_STRING_TOKENIZE] (@ServiceList, '|')
								   WHERE [dbo].[FU_REMOVE_WHITE_SPACE] (Token) = 
										 [dbo].[FU_REMOVE_WHITE_SPACE] (@TempServiceName)))
					BEGIN
						DELETE FROM Hospital_Service
						WHERE Service_ID = @TempServiceID AND
							  Hospital_ID = @HospitalID
					END

					SET @RowNumber += 1
				END
			END

			-- UPDATE IS_ACTIVE STATUS FROM 'FALSE' TO 'TRUE' AND MAPPING NEW SERVICE
			IF (@TotalService < @TotalToken)
			BEGIN
				SET @RowNumber = 1
				WHILE (@RowNumber <= @TotalToken)
				BEGIN
					SELECT @Token = (SELECT TokenList.Token
									 FROM (SELECT ROW_NUMBER()
										 OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
										 FROM [dbo].[FU_STRING_TOKENIZE] (@ServiceList, '|') TokenList) AS TokenList
									 WHERE RowNumber = @RowNumber)

					-- CHECK STATUS OF SERVICE IN HOSPITAL
					IF (NOT EXISTS(SELECT hs.Hospital_ID
								FROM Hospital_Service hs
								WHERE hs.Service_ID = @Token AND
										hs.Hospital_ID = @HospitalID))
					BEGIN
						-- INSERT NEW SERVICE
						INSERT INTO Hospital_Service
						(
							Hospital_ID,
							Service_ID,
							Is_Active
						)
						VALUES
						(
							@HospitalID,
							@Token,
							'True'
						)
					END

					SET @RowNumber += 1
				END
			END
		END
		ELSE
		BEGIN
			DELETE FROM Hospital_Service
			WHERE Hospital_ID = @HospitalID
		END

		-- UPDATE FACILITY TABLE
		IF (@FacilityList != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0
			SET @Token = N''
			DECLARE @TotalFacility INT = 0
			DECLARE @TempFacilityID INT = 0
			DECLARE @TempFacilityName NVARCHAR(256) = N''

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@FacilityList, '|') TokenList)

			SELECT @TotalFacility = (SELECT COUNT(Hospital_ID)
									 FROM Hospital_Facility
									 WHERE Hospital_ID = @HospitalID)

			-- UPDATE IS_ACTIVE STATUS FROM 'TRUE' TO 'FALSE'
			IF (@TotalFacility > @TotalToken)
			BEGIN
				SET @RowNumber = 1
				WHILE (@RowNumber <= @TotalFacility)
				BEGIN
					SELECT @TempFacilityID = (SELECT hf.Facility_ID
											  FROM (SELECT ROW_NUMBER()
													OVER (ORDER BY hf.Facility_ID ASC) AS RowNumber, hf.Facility_ID
													FROM Hospital_Facility hf
													WHERE  Hospital_ID = @HospitalID) AS hf
											  WHERE RowNumber = @RowNumber)
					SELECT @TempFacilityName = (SELECT Facility_Name
												FROM Facility
												WHERE Facility_ID = @TempFacilityID)
					IF (NOT EXISTS(SELECT Token
								   FROM [dbo].[FU_STRING_TOKENIZE] (@FacilityList, '|')
								   WHERE [dbo].[FU_REMOVE_WHITE_SPACE] (Token) = 
										 [dbo].[FU_REMOVE_WHITE_SPACE] (@TempFacilityName)))
					BEGIN
						DELETE FROM Hospital_Facility
						WHERE Facility_ID = @TempFacilityID AND
							  Hospital_ID = @HospitalID
					END

					SET @RowNumber += 1
				END
			END

			-- UPDATE IS_ACTIVE STATUS FROM 'FALSE' TO 'TRUE' AND MAPPING NEW FACILITY
			IF (@TotalFacility < @TotalToken)
			BEGIN
				SET @RowNumber = 1
				WHILE (@RowNumber <= @TotalToken)
				BEGIN
					SELECT @Token = (SELECT TokenList.Token
									 FROM (SELECT ROW_NUMBER()
										 OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
										 FROM [dbo].[FU_STRING_TOKENIZE] (@FacilityList, '|') TokenList) AS TokenList
									 WHERE RowNumber = @RowNumber)

					-- CHECK STATUS OF SERVICE IN HOSPITAL
					IF (NOT EXISTS(SELECT hs.Hospital_ID
								FROM Hospital_Facility hs
								WHERE hs.Facility_ID = @Token AND
										hs.Hospital_ID = @HospitalID))
					BEGIN
						-- INSERT NEW SERVICE
						INSERT INTO Hospital_Facility
						(
							Hospital_ID,
							Facility_ID,
							Is_Active
						)
						VALUES
						(
							@HospitalID,
							@Token,
							'True'
						)
					END

					SET @RowNumber += 1
				END
			END
		END
		ELSE
		BEGIN
			DELETE FROM Hospital_Facility
			WHERE Hospital_ID = @HospitalID
		END

		-- UPDATE TAG TABLE
		IF (@TagInput != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0
			SET @Token = N''
			DECLARE @TotalTag INT = 0
			DECLARE @TempWordID INT = 0
			DECLARE @TempWord NVARCHAR(256) = N''

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@TagInput, ',') TokenList)

			SELECT @TotalTag = (SELECT COUNT(Hospital_ID)
								FROM Tag_Hospital
								WHERE Hospital_ID = @HospitalID)

			-- UPDATE IS_ACTIVE STATUS FROM 'TRUE' TO 'FALSE'
			IF (@TotalTag > @TotalToken)
			BEGIN
				SET @RowNumber = 1
				WHILE (@RowNumber <= @TotalTag)
				BEGIN
					SELECT @TempWordID = (SELECT th.Word_ID
										  FROM (SELECT ROW_NUMBER()
												OVER (ORDER BY th.Word_ID ASC) AS RowNumber, th.Word_ID
												FROM Tag_Hospital th
												WHERE  Hospital_ID = @HospitalID) AS th
										  WHERE RowNumber = @RowNumber)
					SELECT @TempWord = (SELECT Word
										FROM Tag
										WHERE Word_ID = @TempWordID)
					IF (NOT EXISTS(SELECT Token
								   FROM [dbo].[FU_STRING_TOKENIZE] (@TagInput, ',')
								   WHERE [dbo].[FU_REMOVE_WHITE_SPACE] (Token) = 
										 [dbo].[FU_REMOVE_WHITE_SPACE] (@TempWord)))
					BEGIN
						DELETE FROM Tag_Hospital
						WHERE Hospital_ID = @HospitalID AND
							  Word_ID = @TempWordID
					END

					SET @RowNumber += 1
				END
			END

			-- UPDATE IS_ACTIVE STATUS FROM 'FALSE' TO 'TRUE' AND MAPPING NEW TAG
			IF (@TotalTag < @TotalToken)
			BEGIN
				SET @RowNumber = 1
				SET @TempWordID = 0
				WHILE (@RowNumber <= @TotalToken)
				BEGIN
					SELECT @Token = (SELECT TokenList.Token
									 FROM (SELECT ROW_NUMBER()
										   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
										   FROM [dbo].[FU_STRING_TOKENIZE] (@TagInput, ',') TokenList) AS TokenList
									 WHERE RowNumber = @RowNumber)

					IF (NOT EXISTS(SELECT Word_ID
								   FROM Tag
								   WHERE LOWER(Word) = LOWER(@Token)))
					BEGIN
						INSERT INTO Tag
						VALUES(@Token, 3)

						INSERT INTO Tag_Hospital
						VALUES ((SELECT TOP 1 Word_ID
								 FROM Tag
								 WHERE Word = @Token), @HospitalID)
					END
					ELSE
					BEGIN
						IF (NOT EXISTS(SELECT *
							   FROM Tag_Hospital
							   WHERE Hospital_ID = @HospitalID AND
									 Word_ID = (SELECT Word_ID
												FROM Tag
												WHERE LOWER(Word) = LOWER(@Token))))
						BEGIN
							INSERT INTO Tag_Hospital
							VALUES ((SELECT Word_ID
									 FROM Tag
									 WHERE LOWER(Word) = LOWER(@Token)), @HospitalID)
						END
					END

					SET @RowNumber += 1
				END
			END
		END
		ELSE
		BEGIN
			DELETE FROM Tag_Hospital
			WHERE Hospital_ID = @HospitalID AND
				  Word_ID != @HospitalNameWordID
		END

		-- UPDATE PHOTO TABLE
		IF (@PhotoList != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@PhotoList, '|') TokenList)

			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@PhotoList, '|') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)

				INSERT INTO Photo
				(
					File_Path,
					Add_Date,
					Hospital_ID,
					Uploaded_Person,
					Is_Active
				)
				VALUES
				(
					@Token,
					GETDATE(),
					@HospitalID,
					@CreatedPerson,
					'True'
				)

				SET @RowNumber += 1
			END
		END

		COMMIT TRAN T;
		RETURN 1;
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN T
		RETURN 0;
	END CATCH	
END
GO
/****** Object:  StoredProcedure [dbo].[SP_UPDATE_SERVICE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_UPDATE_SERVICE]
	@ServiceID INT,
	@ServivceName NVARCHAR(64),
	@ServiceType INT
AS
BEGIN
	UPDATE [Service]
	SET [Service_Name] = @ServivceName,
		Service_Type = @ServiceType
	WHERE Service_ID = @ServiceID

	IF @@ROWCOUNT = 0
		RETURN 0;
	ELSE
		RETURN 1;
END

GO
/****** Object:  StoredProcedure [dbo].[SP_UPDATE_SPECIALITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_UPDATE_SPECIALITY]
	@SpecialityID INT,
	@SpecialityName NVARCHAR(64)
AS
BEGIN
	UPDATE Speciality
	SET Speciality_Name = @SpecialityName
	WHERE Speciality_ID = @SpecialityID

	IF @@ROWCOUNT = 0
		RETURN 0;
	ELSE
		RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_UPDATE_SPECIALITY_SERVICE_FACILITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_UPDATE_SPECIALITY_SERVICE_FACILITY]
	@HospitalId int,
	@SpecialityList NVARCHAR(4000),
	@ServiceList NVARCHAR(4000),
	@FacilityList NVARCHAR(4000)
AS
BEGIN
	BEGIN TRANSACTION T
	-- INSERT TO HOSPITAL_SPECIALITY TABLE
		IF (@SpecialityList != '')
		BEGIN
			DECLARE @RowNumber INT = 1
			DECLARE @TotalToken  INT = 0;
			DECLARE @Token VARCHAR(4)
			DECLARE @Active bit='False';

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|') TokenList)

			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@SpecialityList, '|') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)
				SELECT @Active=	(SELECT	Is_Active
								FROM	Hospital_Speciality
								WHERE	Speciality_ID=@Token AND Hospital_ID=@HospitalId)
				IF(@Active IS NOT NULL)
					IF(@Active='False')
						UPDATE	Hospital_Speciality
						SET		Is_Active='True'
						WHERE	Hospital_ID=@HospitalId AND Speciality_ID=@Token
				IF(@Active IS NULL) 
					INSERT INTO Hospital_Speciality
					(
						Hospital_ID,
						Speciality_ID,
						Is_Main_Speciality,
						Is_Active
					)
					VALUES
					(
						@HospitalID,
						@Token,
						'False',
						'True')
				IF @@ERROR<> 0
				BEGIN
					ROLLBACK TRAN T;
					RETURN 0;
				END

				SET @RowNumber += 1
			END
		END
		
		-- INSERT TO SERVCE TABLE
		IF (@ServiceList != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@ServiceList, '|') TokenList)

			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@ServiceList, '|') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)
				 SELECT @Active=	(SELECT	Is_Active
									FROM	Hospital_Service
									WHERE	Service_ID=@Token AND Hospital_ID=@HospitalId)
				IF(@Active IS NOT NULL)
					IF(@Active='False')
						UPDATE	Hospital_Service
						SET		Is_Active='True'
						WHERE	Hospital_ID=@HospitalId AND Service_ID=@Token
				ELSE
				INSERT INTO Hospital_Service
				(
					Hospital_ID,
					Service_ID,
					Is_Active
				)
				VALUES
				(
					@HospitalID,
					@Token,
					'True'
				)

				IF @@ERROR<> 0
				BEGIN
					ROLLBACK TRAN T;
					RETURN 0;
				END

				SET @RowNumber += 1
			END
		END

		-- INSERT TO FACILITY TABLE
		IF (@FacilityList != '')
		BEGIN
			SET @RowNumber = 1
			SET @TotalToken = 0

			SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
								  FROM [dbo].[FU_STRING_TOKENIZE] (@FacilityList, '|') TokenList)

			WHILE (@RowNumber <= @TotalToken)
			BEGIN
				SELECT @Token = (SELECT TokenList.Token
								 FROM (SELECT ROW_NUMBER()
									   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
									   FROM [dbo].[FU_STRING_TOKENIZE] (@FacilityList, '|') TokenList) AS TokenList
								 WHERE RowNumber = @RowNumber)
				SELECT @Active=	(SELECT	Is_Active
								FROM	Hospital_Facility
								WHERE	Facility_ID=@Token AND Hospital_ID=@HospitalId)
				IF(@Active IS NOT NULL)
					IF(@Active='False')
						UPDATE	Hospital_Facility
						SET		Is_Active='True'
						WHERE	Hospital_ID=@HospitalId AND Facility_ID=@Token
					ELSE
				INSERT INTO Hospital_Facility
				(
					Hospital_ID,
					Facility_ID,
					Is_Active
				)
				VALUES
				(
					@HospitalID,
					@Token,
					'True'
				)

				IF @@ERROR<> 0
				BEGIN
					ROLLBACK TRAN T;
					RETURN 0;
				END

				SET @RowNumber += 1
			END
		END
		
	COMMIT TRAN T;
	RETURN 1;
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_AUTO_GENERATE_ENTITIES_CLASS]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_AUTO_GENERATE_ENTITIES_CLASS]
(
	@TableName VARCHAR(MAX),
	@NameSpace VARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @result VARCHAR(MAX)

	SET @result = 'using System;' + CHAR(13) + CHAR(13)

	SET @result = @result + 'namespace ' +
		@NameSpace  + CHAR(13) + '{' + CHAR(13)

	SET @result = @result + 
		'	/// <summary>' + CHAR(13) +
		'	/// Class defines properties for ' + @TableName + ' table' + CHAR(13) +
		'	/// <summary>' + CHAR(13) +
		'	public class ' +
		REPLACE(@TableName, '_', '') + 'Entity' + CHAR(13) + '	{' + CHAR(13)

	SET @result = @result + '		#region ' + @TableName + ' Properties' + CHAR(13) 

	SELECT @result = @result + CHAR(13) +
		   '		/// <summary>' + CHAR(13) +
		   '		/// Property for ' + orgColName + ' attribute' + CHAR(13) +
		   '		/// <summary>' + CHAR(13) +
		   '		public ' +
		   ColumnType + ' ' + ColumnName + ' { get; set; }' + CHAR(13)
	FROM
	(
		SELECT REPLACE(col.name, '_', '') ColumnName,
			   col.name orgColName, column_id,
			CASE typ.name 
				WHEN 'bigint' THEN
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'long?' ELSE 'long' END
				WHEN 'binary' THEN 'byte[]'
				WHEN 'bit' THEN 
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'bool?' ELSE 'bool' END            
				WHEN 'char' THEN 'string'
				WHEN 'date' THEN
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'DateTime?' ELSE 'DateTime' END                        
				WHEN 'datetime' THEN
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'DateTime?' ELSE 'DateTime' END                        
				WHEN 'datetime2' THEN  
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'DateTime?' ELSE 'DateTime' END                        
				WHEN 'datetimeoffset' THEN 
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'DateTimeOffset?' ELSE 'DateTimeOffset' END                                    
				WHEN 'decimal' THEN  
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'decimal?' ELSE 'decimal' END                                    
				WHEN 'float' THEN 
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'float?' ELSE 'float' END                                    
				WHEN 'image' THEN 'byte[]'
				WHEN 'int' THEN  
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'int?' ELSE 'int' END
				WHEN 'money' THEN
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'decimal?' ELSE 'decimal' END                                                
				WHEN 'nchar' THEN 'string'
				WHEN 'ntext' THEN 'string'
				WHEN 'numeric' THEN
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'decimal?' ELSE 'decimal' END                                                            
				WHEN 'nvarchar' THEN 'string'
				WHEN 'real' THEN 
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'double?' ELSE 'double' END                                                                        
				WHEN 'smalldatetime' THEN 
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'DateTime?' ELSE 'DateTime' END                                    
				WHEN 'smallint' THEN 
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'int?' ELSE 'int'END            
				WHEN 'smallmoney' THEN  
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'decimal?' ELSE 'decimal' END                                                                        
				WHEN 'text' THEN 'string'
				WHEN 'time' THEN 
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'TimeSpan?' ELSE 'TimeSpan' END                                                                                    
				WHEN 'timestamp' THEN 
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'DateTime?' ELSE 'DateTime' END                                    
				WHEN 'tinyint' THEN 
					CASE col.IS_NULLABLE
						WHEN 'TRUE' THEN 'byte?' ELSE 'byte' END                                                
				WHEN 'uniqueidentifier' THEN 'Guid'
				WHEN 'varbinary' THEN 'byte[]'
				WHEN 'varchar' THEN 'string'
				ELSE 'Object'
			END ColumnType
		FROM sys.columns col join
			 sys.types typ
		ON col.system_type_id = typ.system_type_id AND
		   col.user_type_id = typ.user_type_id
		WHERE object_id = object_id(@TableName)
	) t
	ORDER BY column_id

	SET @result = @result + CHAR(13) + '		#endregion '+ CHAR(13) 

	SET @result = @result  + '	}' + CHAR(13) + '}'

	RETURN @result
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_CALCULATE_AVERAGE_RATING]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_CALCULATE_AVERAGE_RATING]
(
	@HospitalID INT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @TotalRecord INT

	SELECT @TotalRecord = r.Total
	FROM (SELECT COUNT(Rating_ID) AS Total
		  FROM Rating
		  WHERE Hospital_ID = @HospitalID) r

	DECLARE @AverageScore FLOAT 

	SELECT @AverageScore = a.Result
	FROM (SELECT CONVERT(FLOAT, (CONVERT(FLOAT, SUM(Score)) / @TotalRecord)) AS Result
		  FROM Rating
		  WHERE Hospital_ID = @HospitalID) a

	RETURN @AverageScore
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_CREATE_BAD_MATCH_TABLE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_CREATE_BAD_MATCH_TABLE]
(
	@Pattern NVARCHAR(MAX)
)
RETURNS NVARCHAR(256)
AS
BEGIN
	DECLARE @BadMatchTable NVARCHAR(256) = NULL

	DECLARE @Count INT = 1
	DECLARE @PatternLength INT 
	SET @PatternLength = LEN(@Pattern)

	DECLARE @CharInPattern NVARCHAR(1) = NULL

	WHILE (@Count <= @PatternLength)
	BEGIN
		SET @CharInPattern =  SUBSTRING(@Pattern, @Count, 1)

		IF (CHARINDEX(@CharInPattern, @BadMatchTable) > 0)
		BEGIN
			SET @BadMatchTable = REPLACE(@BadMatchTable,
				SUBSTRING(@BadMatchTable,
					CHARINDEX(@CharInPattern, @BadMatchTable) - 2, 1), @Count - 1)
		END
		ELSE
		BEGIN
			SET @BadMatchTable = CONCAT(@BadMatchTable, '[', @Count - 1, ',', @CharInPattern, ']|')
		END

		SET @Count += 1
	END

	RETURN @BadMatchTable
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_GET_DISTANCE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_GET_DISTANCE]
(
	@Latitude1 FLOAT,
	@Longitude1 FLOAT,
	@Latitude2 FLOAT,
	@Longitude2 FLOAT
)
RETURNS INT
AS
BEGIN
	DECLARE @Result FLOAT

	DECLARE @R FLOAT
	SET @R = 6371000

	DECLARE @LatitudeDistance FLOAT
	SET @LatitudeDistance = [dbo].[FU_GET_RADIUS] (@Latitude2 - @Latitude1)

	DECLARE @LongitudeDistance FLOAT
	SET @LongitudeDistance = [dbo].[FU_GET_RADIUS] (@Longitude2 - @Longitude1)

	DECLARE @A FLOAT
	SET @A = SIN(@LatitudeDistance / 2) * SIN(@LatitudeDistance / 2) +
			 COS([dbo].[FU_GET_RADIUS] (@Latitude1)) * COS([dbo].[FU_GET_RADIUS] (@Latitude1)) *
			 SIN(@LongitudeDistance / 2) * SIN(@LongitudeDistance / 2)

	DECLARE @C FLOAT
	SEt @C = 2 * ATN2(SQRT(@A), SQRT(1 - @A))

	SET @Result = @R * @C
	RETURN CONVERT(INT, @Result)
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_GET_RADIUS]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_GET_RADIUS]
(
	@Value FLOAT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @Result FLOAT
	SET @Result = (@Value * PI()) / 180

	RETURN @Result
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_IS_PATTERN_MATCHED]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_IS_PATTERN_MATCHED]
(
	@Text NVARCHAR(MAX),
	@Pattern NVARCHAR(MAX)
)
RETURNS BIT
AS
BEGIN
	SET @Text = LOWER(LTRIM(RTRIM(@Text)))
	SET @Pattern = LOWER(LTRIM(RTRIM(@Pattern)))

	DECLARE @Shift INT = 0
	DECLARE @TextLength INT = LEN(@Text)
	DECLARE @PatternLength INT = LEN(@Pattern)
	DECLARE @BadMatchTable NVARCHAR(256) = [dbo].[FU_CREATE_BAD_MATCH_TABLE] (@Pattern)
	DECLARE @Count1 INT = 0
	DECLARE @Count2 INT = 0

	DECLARE @CharInText NVARCHAR(1) = NULL
	DECLARE @CharInPattern NVARCHAR(1) = NULL
	DECLARE @Temp INT = 0
	
	WHILE (@Count1 <= (@TextLength - @PatternLength))
	BEGIN
		SET @Shift = 0
		SET @Count2 = @PatternLength - 1

		WHILE (@Count2 >= 0)
		BEGIN
			SET @CharInText =  SUBSTRING(@Text, @Count1 + @Count2 + 1, 1)
			SET @CharInPattern =  SUBSTRING(@Pattern, @Count2 + 1, 1)

			IF (@CharInPattern != @CharInText)
			BEGIN
				IF (CHARINDEX(@CharInText, @BadMatchTable) = 0)
				BEGIN
					SET @Temp = @Count2
					IF (@Temp > 1)
						SET @Shift = @Temp
					ELSE
						SET @Shift = 1
					BREAK
				END
				ELSE
				BEGIN
					DECLARE @A INT = CHARINDEX(@CharInText, @BadMatchTable) - 2
					DECLARE @B NVARCHAR(1)  = SUBSTRING(@BadMatchTable, CHARINDEX(@CharInText, @BadMatchTable) - 2, 1)

					SET @Temp = @Count2 - CONVERT(INT, SUBSTRING(@BadMatchTable, CHARINDEX(@CharInText, @BadMatchTable) - 2, 1))
					IF (@Temp > 1)
						SET @Shift = @Temp
					ELSE
						SET @Shift = 1
					BREAK
				END
			END

			SET @Count2 -= 1
		END

		IF (@Shift = 0)
			RETURN 1;

		SET @Count1 += @Shift
	END

	RETURN 0
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_REMOVE_WHITE_SPACE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_REMOVE_WHITE_SPACE]
(
	@InputString NVARCHAR(4000)
)
RETURNS NVARCHAR(4000)
AS
BEGIN
	SET @InputString = REPLACE(@InputString, ' ', '')
	RETURN @InputString
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_STRING_COMPARE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_STRING_COMPARE]
(
	@InputStr1 NVARCHAR(MAX),
	@InputStr2 NVARCHAR(MAX)
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @Result FLOAT
	DECLARE @Union INT = 0
	DECLARE @Intersection INT = 0

	DECLARE @RowNumber1 INT = 1
	DECLARE @RowNumber2 INT
	DECLARE @NumOfPairsStr1 INT
	DECLARE @NumOfPairsStr2 INT
	DECLARE @PairStr1 NVARCHAR(2)
	DECLARE @PairStr2 NVARCHAR(2)

	SELECT @NumOfPairsStr1 = (SELECT COUNT(TokenList.ID)
							  FROM [dbo].[FU_TAKE_PAIRS_OF_LETTER_IN_WORD] (@InputStr1) TokenList)
	SELECT @NumOfPairsStr2 = (SELECT COUNT(TokenList.ID)
							  FROM [dbo].[FU_TAKE_PAIRS_OF_LETTER_IN_WORD] (@InputStr2) TokenList)

	SET @Union = @NumOfPairsStr1 + @NumOfPairsStr2

	WHILE (@RowNumber1 <= @NumOfPairsStr1)
	BEGIN
		SELECT @PairStr1 = (SELECT PairList.Pair
							FROM (SELECT ROW_NUMBER()
								  OVER (ORDER BY PairList.ID ASC) AS RowNumber, PairList.Pair
								  FROM [dbo].[FU_TAKE_PAIRS_OF_LETTER_IN_WORD] (@InputStr1) PairList) AS PairList
							WHERE RowNumber = @RowNumber1)
		SET @RowNumber2 = 1

		WHILE (@RowNumber2 <= @NumOfPairsStr2)
		BEGIN
			SELECT @PairStr2 = (SELECT PairList.Pair
								FROM (SELECT ROW_NUMBER()
									  OVER (ORDER BY PairList.ID ASC) AS RowNumber, PairList.Pair
									  FROM [dbo].[FU_TAKE_PAIRS_OF_LETTER_IN_WORD] (@InputStr2) PairList) AS PairList
								WHERE RowNumber = @RowNumber2)

			IF (@PairStr1 = @PairStr2)
			BEGIN
				SET @Intersection += 1
			END

			SET @RowNumber2 += 1
		END

		SET @RowNumber1 += 1
	END

	SET @Result = CONVERT(FLOAT, 2 * @Intersection) / CONVERT(FLOAT, @Union)
	RETURN @Result
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_STRING_TOKENIZE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_STRING_TOKENIZE]
(
	@InputStr NVARCHAR(MAX),
	@Delimeter VARCHAR(1)
)
RETURNS @TokenList TABLE (ID INT PRIMARY KEY,
						  Token NVARCHAR(MAX))
AS
BEGIN
	DECLARE @Start INT
	DECLARE @End INT
	DECLARE @Id INT = 1
    SELECT @Start = 1, @End = CHARINDEX(@Delimeter, @InputStr) 

    WHILE @Start < LEN(@InputStr) + 1
	BEGIN 
        IF @End = 0  
            SET @End = LEN(@InputStr) + 1
       
        INSERT INTO @TokenList
        SELECT @Id, (SUBSTRING(@InputStr, @Start, @End - @Start))

        SET @Start = @End + 1 
        SET @End = CHARINDEX(@Delimeter, @InputStr, @Start)
        SET @Id += 1
    END 
    RETURN 
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_MATCHED_STRING_POSITION]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_TAKE_MATCHED_STRING_POSITION]
(
	@Text NVARCHAR(MAX),
	@Pattern NVARCHAR(MAX)
)
RETURNS INT
AS
BEGIN
	SET @Text = LOWER(LTRIM(RTRIM(@Text)))
	SET @Pattern = LOWER(LTRIM(RTRIM(@Pattern)))

	DECLARE @Shift INT = 0
	DECLARE @TextLength INT = LEN(@Text)
	DECLARE @PatternLength INT = LEN(@Pattern)
	DECLARE @BadMatchTable NVARCHAR(256) = [dbo].[FU_CREATE_BAD_MATCH_TABLE] (@Pattern)
	DECLARE @Count1 INT = 0
	DECLARE @Count2 INT = 0

	DECLARE @CharInText NVARCHAR(1) = NULL
	DECLARE @CharInPattern NVARCHAR(1) = NULL
	DECLARE @Temp INT = 0
	
	WHILE (@Count1 <= (@TextLength - @PatternLength))
	BEGIN
		SET @Shift = 0
		SET @Count2 = @PatternLength - 1

		WHILE (@Count2 >= 0)
		BEGIN
			SET @CharInText =  SUBSTRING(@Text, @Count1 + @Count2 + 1, 1)
			SET @CharInPattern =  SUBSTRING(@Pattern, @Count2 + 1, 1)

			IF (@CharInPattern != @CharInText)
			BEGIN
				IF (CHARINDEX(@CharInText, @BadMatchTable) = 0)
				BEGIN
					SET @Temp = @Count2
					IF (@Temp > 1)
						SET @Shift = @Temp
					ELSE
						SET @Shift = 1
					BREAK
				END
				ELSE
				BEGIN
					DECLARE @A INT = CHARINDEX(@CharInText, @BadMatchTable) - 2
					DECLARE @B NVARCHAR(1)  = SUBSTRING(@BadMatchTable, CHARINDEX(@CharInText, @BadMatchTable) - 2, 1)

					SET @Temp = @Count2 - CONVERT(INT, SUBSTRING(@BadMatchTable, CHARINDEX(@CharInText, @BadMatchTable) - 2, 1))
					IF (@Temp > 1)
						SET @Shift = @Temp
					ELSE
						SET @Shift = 1
					BREAK
				END
			END

			SET @Count2 -= 1
		END

		IF (@Shift = 0)
			RETURN @Count1;

		SET @Count1 += @Shift
	END

	RETURN 9999
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_NUMBER_OF_RELATIVE_DISEASE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_TAKE_NUMBER_OF_RELATIVE_DISEASE]
(
	@HospitalID INT,
	@WhatPhrase NVARCHAR(4000),
	@Mode INT
)
RETURNS INT
AS
BEGIN
	IF (@WhatPhrase IS NULL OR @WhatPhrase = '')
	BEGIN
		RETURN 0;
	END

	DECLARE @NumberOfDisease INT

	IF (@Mode = 0)
	BEGIN
		SELECT @NumberOfDisease = (SELECT COUNT(d.Disease_ID)
								   FROM Disease d, Speciality_Disease sd,
										Hospital h, Hospital_Speciality hs
								   WHERE h.Hospital_ID = @HospitalID AND
										 h.Hospital_ID = hs.Hospital_ID AND
										 hs.Speciality_ID = sd.Speciality_ID AND
										 sd.Disease_ID = d.Disease_ID AND
										 FREETEXT(Disease_Name, @WhatPhrase))
	END
	ELSE
	BEGIN
		SELECT @NumberOfDisease = (SELECT COUNT(d.Disease_ID)
								   FROM [NON_DIACRITIC_DISEASE] d, Speciality_Disease sd,
										Hospital h, Hospital_Speciality hs, Speciality s
								   WHERE h.Hospital_ID = @HospitalID AND
									     h.Hospital_ID = hs.Hospital_ID AND
									     hs.Speciality_ID = sd.Speciality_ID AND
									     s.Speciality_ID = sd.Speciality_ID AND
									     sd.Disease_ID = d.Disease_ID AND
										 FREETEXT(d.Disease_Name, N'ngoai'))
	END

	IF (@NumberOfDisease IS NULL)
		RETURN 0;
	ELSE
		RETURN @NumberOfDisease;

	RETURN 0;
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_NUMBER_OF_RELATIVE_SPECIALITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_TAKE_NUMBER_OF_RELATIVE_SPECIALITY]
(
	@HospitalID INT,
	@WhatPhrase NVARCHAR(4000),
	@Mode INT
)
RETURNS INT
AS
BEGIN
	IF (@WhatPhrase IS NULL OR @WhatPhrase = '')
	BEGIN
		RETURN 0;
	END

	DECLARE @NumberOfSpeciality INT

	IF (@Mode = 0)
	BEGIN
		SELECT @NumberOfSpeciality = (SELECT COUNT(s.Speciality_ID)
									  FROM Speciality s, Hospital h, Hospital_Speciality hs
									  WHERE h.Hospital_ID = @HospitalID AND
											h.Hospital_ID = hs.Hospital_ID AND
											hs.Speciality_ID = s.Speciality_ID AND
											FREETEXT (s.Speciality_Name, @WhatPhrase))
	END
	ELSE
	BEGIN
		SELECT @NumberOfSpeciality = (SELECT COUNT(s.Speciality_ID)
									  FROM [NON_DIACRITIC_SPECIALITY] s, Hospital h, Hospital_Speciality hs
									  WHERE h.Hospital_ID = @HospitalID AND
											h.Hospital_ID = hs.Hospital_ID AND
											hs.Speciality_ID = s.Speciality_ID AND
											FREETEXT (s.Speciality_Name, @WhatPhrase))
	END


	IF (@NumberOfSpeciality IS NULL)
		RETURN 0;
	ELSE
		RETURN @NumberOfSpeciality;

	RETURN 0;
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_NUMBER_OF_RELATIVE_TAG]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_TAKE_NUMBER_OF_RELATIVE_TAG]
(
	@HospitalID INT,
	@WhatPhrase NVARCHAR(4000),
	@Mode INT
)
RETURNS INT
AS
BEGIN
	IF (@WhatPhrase IS NULL OR @WhatPhrase = '')
	BEGIN
		RETURN 0;
	END

	DECLARE @NumberOfTag INT

	IF (@Mode = 0)
	BEGIN
		SELECT @NumberOfTag = (SELECT COUNT(w.Word_ID)
							   FROM Tag w, Tag_Hospital wh
							   WHERE wh.Hospital_ID = @HospitalID AND
									 w.Word_ID = wh.Word_ID AND
									 w.[Type] = 3 AND
									 FREETEXT (w.Word, @WhatPhrase))
	END
	ELSE
	BEGIN
		SELECT @NumberOfTag = (SELECT COUNT(w.Word_ID)
							   FROM [NON_DIACRITIC_TAG] w, Tag_Hospital wh
							   WHERE wh.Hospital_ID = @HospitalID AND
									 w.Word_ID = wh.Word_ID AND
									 FREETEXT (w.Word, @WhatPhrase))
	END
	
	IF (@NumberOfTag IS NULL)
		RETURN 0;
	ELSE
		RETURN @NumberOfTag;

	RETURN 0;
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_PAIRS_OF_LETTER]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_TAKE_PAIRS_OF_LETTER]
(
	@Word NVARCHAR(32)
)
RETURNS @PairList TABLE (ID INT PRIMARY KEY,
						 Pair NVARCHAR(512))
AS
BEGIN
	DECLARE @Pair NVARCHAR(32)
	DECLARE @NumOfPairs INT = LEN(@Word) - 1
	DECLARE @Count INT = 0

	WHILE (@Count < @NumOfPairs)
	BEGIN
		SET @Pair = SUBSTRING(@Word, @Count + 1, 2)

		INSERT INTO @PairList 
		SELECT @Count + 1, @Pair

		SET @Count += 1
	END

	RETURN
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_PAIRS_OF_LETTER_IN_WORD]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_TAKE_PAIRS_OF_LETTER_IN_WORD]
(
	@InputStr NVARCHAR(MAX)
)
RETURNS @PairList TABLE (ID INT PRIMARY KEY, 
						 Pair NVARCHAR(2))
AS
BEGIN
	DECLARE @RowNumber1 INT = 1
	DECLARE @NumOfPairs INT
	DECLARE @RowNumber2 INT
	DECLARE @Token NVARCHAR(32)
	DECLARE @Pair NVARCHAR(2)
	DECLARE @Id INT = 1

	DECLARE @TotalToken INT
	SELECT @TotalToken = (SELECT COUNT(TokenList.ID)
						  FROM [dbo].[FU_STRING_TOKENIZE] (@InputStr, ' ') TokenList)

	WHILE (@RowNumber1 <= @TotalToken)
	BEGIN
		SELECT @Token = (SELECT TokenList.Token
						 FROM (SELECT ROW_NUMBER()
							   OVER (ORDER BY TokenList.ID ASC) AS RowNumber, TokenList.Token
							   FROM [dbo].[FU_STRING_TOKENIZE] (@InputStr, ' ') TokenList) AS TokenList
						 WHERE RowNumber = @RowNumber1)

		SELECT @NumOfPairs = (SELECT COUNT(PairList.ID)
							  FROM [dbo].[FU_TAKE_PAIRS_OF_LETTER] (@Token) PairList)
		SET @RowNumber2 = 1

		WHILE(@RowNumber2 <= @NumOfPairs)
		BEGIN
			SELECT @Pair = (SELECT PairList.Pair
							FROM (SELECT ROW_NUMBER()
								  OVER (ORDER BY PairList.ID ASC) AS RowNumber, PairList.Pair
								  FROM [dbo].[FU_TAKE_PAIRS_OF_LETTER] (@Token) PairList) AS PairList
							WHERE RowNumber = @RowNumber2)

			INSERT INTO @PairList 
			SELECT @Id, @Pair

			SET @RowNumber2 += 1
			SET @Id += 1
		END

		SET @RowNumber1 += 1
	END

	RETURN
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_RATING_COUNT]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_TAKE_RATING_COUNT]
(
	@HospitalID INT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @RatingCount FLOAT

	SELECT @RatingCount = (SELECT h.Rating_Count
						   FROM Hospital h
						   WHERE h.Hospital_ID = @HospitalID)
	IF (@RatingCount IS NULL)
		RETURN 0;
	ELSE
		RETURN @RatingCount;

	RETURN 0;
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_RATING_POINT]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_TAKE_RATING_POINT]
(
	@HospitalID INT
)
RETURNS FLOAT
AS
BEGIN
	DECLARE @RatingPoint FLOAT

	SELECT @RatingPoint = (SELECT h.Rating
						   FROM Hospital h
						   WHERE h.Hospital_ID = @HospitalID)
	IF (@RatingPoint IS NULL)
		RETURN 0;
	ELSE
		RETURN @RatingPoint;

	RETURN 0;
END
GO
/****** Object:  UserDefinedFunction [dbo].[RETURN_SORT_PRIORITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[RETURN_SORT_PRIORITY]
(
	@HospitalID INT,
	@Index INT,
	@WhatPhrase NVARCHAR(128),
	@NonDiacriticWhatPhrase NVARCHAR(128)
)
RETURNS INT
AS
BEGIN
	DECLARE @Priority INT = 0

	-- DEFINE PRIORITY OF SORT ORDER
	DECLARE @PriorityOfRatingPoint INT = 1000
	DECLARE @PriorityOfRatingCount INT = 100

	DECLARE @ExactlyPriorityOfTag INT = 10000
	DECLARE @ExactlyPriorityOfSpeciality INT = 10000
	DECLARE @ExactlyPriorityOfDisease INT = 10000

	DECLARE @RelativePriorityOfTag INT = 100
	DECLARE @RelativePriorityOfSpeciality INT = 100
	DECLARE @RelativePriorityOfDisease INT = 100
	
	DECLARE @NonDiacriticPriorityOfTag INT = 10
	DECLARE @NonDiacriticPriorityOfSpeciality INT = 10
	DECLARE @NonDiacriticPriorityOfDisease INT = 10

	-- DEFINE INDEX NUMBER FOR SORT ORDER
	DECLARE @ExactlyIndexOfTag INT = 1
	DECLARE @ExactlyIndexOfSpeciality INT = 2
	DECLARE @ExactlyIndexOfDisease INT = 3

	DECLARE @RelativeIndexOfTag INT = 8
	DECLARE @RelativeIndexOfSpeciality INT = 9
	DECLARE @RelativeIndexOfDisease INT = 10
	
	DECLARE @NonDiacriticIndexOfTag INT = 11
	DECLARE @NonDiacriticIndexOfSpeciality INT = 12
	DECLARE @NonDiacriticIndexOfDisease INT = 13

	DECLARE @AdvancedSearch INT = 99

	-- RETURN PRIORITY OF EXACTLY TAG
	SELECT @Priority = 
		CASE @Index
			WHEN @ExactlyIndexOfTag THEN @ExactlyPriorityOfTag
			WHEN @ExactlyIndexOfSpeciality THEN @ExactlyPriorityOfSpeciality
			WHEN @ExactlyIndexOfDisease THEN @ExactlyPriorityOfDisease

			WHEN @RelativeIndexOfTag THEN
				[dbo].[FU_TAKE_NUMBER_OF_RELATIVE_TAG] (@HospitalID, @WhatPhrase, 0) * @RelativePriorityOfTag
			WHEN @RelativeIndexOfSpeciality THEN
				[dbo].[FU_TAKE_NUMBER_OF_RELATIVE_SPECIALITY] (@HospitalID, @WhatPhrase, 0) * @RelativePriorityOfSpeciality
			WHEN @RelativeIndexOfDisease THEN
				[dbo].[FU_TAKE_NUMBER_OF_RELATIVE_DISEASE] (@HospitalID, @WhatPhrase, 0) * @RelativePriorityOfDisease

			WHEN @NonDiacriticIndexOfTag THEN
				[dbo].[FU_TAKE_NUMBER_OF_RELATIVE_TAG] (@HospitalID, @NonDiacriticWhatPhrase, 1) * @NonDiacriticPriorityOfTag
			WHEN @NonDiacriticIndexOfSpeciality
				THEN [dbo].[FU_TAKE_NUMBER_OF_RELATIVE_SPECIALITY] (@HospitalID, @NonDiacriticWhatPhrase, 1) * @NonDiacriticPriorityOfSpeciality
			WHEN @NonDiacriticIndexOfDisease
				THEN [dbo].[FU_TAKE_NUMBER_OF_RELATIVE_DISEASE] (@HospitalID, @NonDiacriticWhatPhrase, 1) * @NonDiacriticPriorityOfDisease

			WHEN @AdvancedSearch THEN
				CONVERT(INT, [dbo].[FU_TAKE_RATING_POINT] (@HospitalID) * @PriorityOfRatingPoint) +
				CONVERT(INT, [dbo].[FU_TAKE_RATING_COUNT] (@HospitalID) * @PriorityOfRatingCount)
		END

	-- RETURN SORT PRIORTY
	RETURN @Priority
END
GO
/****** Object:  Table [dbo].[Disease]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Disease](
	[Disease_ID] [int] IDENTITY(1,1) NOT NULL,
	[Disease_Name] [nvarchar](64) NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Disease] PRIMARY KEY CLUSTERED 
(
	[Disease_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  UserDefinedFunction [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE]
(
	@strInput NVARCHAR(4000)
)
RETURNS NVARCHAR(4000) WITH SCHEMABINDING
AS
BEGIN    
    IF @strInput IS NULL
		RETURN @strInput
    IF @strInput = ''
		RETURN @strInput

    DECLARE @l_str NVARCHAR(4000);
	SET @l_str = LTRIM(@strInput);
	SET @l_str = LOWER(RTRIM(@l_str));
 
	SET @l_str = REPLACE(@l_str, N'á', 'a');
 
	SET @l_str = REPLACE(@l_str, N'à', 'a');
	SET @l_str = REPLACE(@l_str, N'ả', 'a');
	SET @l_str = REPLACE(@l_str, N'ã', 'a');
	SET @l_str = REPLACE(@l_str, N'ạ', 'a');
 
	SET @l_str = REPLACE(@l_str, N'â', 'a');
	SET @l_str = REPLACE(@l_str, N'ấ', 'a');
	SET @l_str = REPLACE(@l_str, N'ầ', 'a');
	SET @l_str = REPLACE(@l_str, N'ẩ', 'a');
	SET @l_str = REPLACE(@l_str, N'ẫ', 'a');
	SET @l_str = REPLACE(@l_str, N'ậ', 'a');
 
	SET @l_str = REPLACE(@l_str, N'ă', 'a');
	SET @l_str = REPLACE(@l_str, N'ắ', 'a');
	SET @l_str = REPLACE(@l_str, N'ằ', 'a');
	SET @l_str = REPLACE(@l_str, N'ẳ', 'a');
	SET @l_str = REPLACE(@l_str, N'ẵ', 'a');
	SET @l_str = REPLACE(@l_str, N'ặ', 'a');
 
	SET @l_str = REPLACE(@l_str, N'é', 'e');
	SET @l_str = REPLACE(@l_str, N'è', 'e');
	SET @l_str = REPLACE(@l_str, N'ẻ', 'e');
	SET @l_str = REPLACE(@l_str, N'ẽ', 'e');
	SET @l_str = REPLACE(@l_str, N'ẹ', 'e');
 
	SET @l_str = REPLACE(@l_str, N'ê', 'e');
	SET @l_str = REPLACE(@l_str, N'ế', 'e');
	SET @l_str = REPLACE(@l_str, N'ề', 'e');
	SET @l_str = REPLACE(@l_str, N'ể', 'e');
	SET @l_str = REPLACE(@l_str, N'ễ', 'e');
	SET @l_str = REPLACE(@l_str, N'ệ', 'e');
 
	SET @l_str = REPLACE(@l_str, N'í', 'i');
	SET @l_str = REPLACE(@l_str, N'ì', 'i');
	SET @l_str = REPLACE(@l_str, N'ỉ', 'i');
	SET @l_str = REPLACE(@l_str, N'ĩ', 'i');
	SET @l_str = REPLACE(@l_str, N'ị', 'i');
 
	SET @l_str = REPLACE(@l_str, N'ó', 'o');
	SET @l_str = REPLACE(@l_str, N'ò', 'o');
	SET @l_str = REPLACE(@l_str, N'ỏ', 'o');
	SET @l_str = REPLACE(@l_str, N'õ', 'o');
	SET @l_str = REPLACE(@l_str, N'ọ', 'o');
 
	SET @l_str = REPLACE(@l_str, N'ô', 'o');
	SET @l_str = REPLACE(@l_str, N'ố', 'o');
	SET @l_str = REPLACE(@l_str, N'ồ', 'o');
	SET @l_str = REPLACE(@l_str, N'ổ', 'o');
	SET @l_str = REPLACE(@l_str, N'ỗ', 'o');
	SET @l_str = REPLACE(@l_str, N'ộ', 'o');
 
	SET @l_str = REPLACE(@l_str, N'ơ', 'o');
	SET @l_str = REPLACE(@l_str, N'ớ', 'o');
	SET @l_str = REPLACE(@l_str, N'ờ', 'o');
	SET @l_str = REPLACE(@l_str, N'ở', 'o');
	SET @l_str = REPLACE(@l_str, N'ỡ', 'o');
	SET @l_str = REPLACE(@l_str, N'ợ', 'o');
 
	SET @l_str = REPLACE(@l_str, N'ú', 'u');
	SET @l_str = REPLACE(@l_str, N'ù', 'u');
	SET @l_str = REPLACE(@l_str, N'ủ', 'u');
	SET @l_str = REPLACE(@l_str, N'ũ', 'u');
	SET @l_str = REPLACE(@l_str, N'ụ', 'u');
 
	SET @l_str = REPLACE(@l_str, N'ư', 'u');
	SET @l_str = REPLACE(@l_str, N'ứ', 'u');
	SET @l_str = REPLACE(@l_str, N'ừ', 'u');
	SET @l_str = REPLACE(@l_str, N'ử', 'u');
	SET @l_str = REPLACE(@l_str, N'ữ', 'u');
	SET @l_str = REPLACE(@l_str, N'ự', 'u');
 
	SET @l_str = REPLACE(@l_str, N'ý', 'y');
	SET @l_str = REPLACE(@l_str, N'ỳ', 'y');
	SET @l_str = REPLACE(@l_str, N'ỷ', 'y');
	SET @l_str = REPLACE(@l_str, N'ỹ', 'y');
	SET @l_str = REPLACE(@l_str, N'ỵ', 'y');
 
	SET @l_str = REPLACE(@l_str, N'đ', 'd');

    RETURN @l_str
END
GO
/****** Object:  Table [dbo].[Hospital]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Hospital](
	[Hospital_ID] [int] IDENTITY(1,1) NOT NULL,
	[Hospital_Name] [nvarchar](64) NULL,
	[Hospital_Type] [int] NULL,
	[Address] [nvarchar](128) NULL,
	[Ward_ID] [int] NULL,
	[District_ID] [int] NULL,
	[City_ID] [int] NULL,
	[Phone_Number] [varchar](64) NULL,
	[Fax] [varchar](16) NULL,
	[Email] [varchar](64) NULL,
	[Website] [varchar](64) NULL,
	[Ordinary_Start_Time] [time](7) NULL,
	[Ordinary_End_Time] [time](7) NULL,
	[Holiday_Start_Time] [time](7) NULL,
	[Holiday_End_Time] [time](7) NULL,
	[Coordinate] [varchar](26) NULL,
	[Full_Description] [nvarchar](max) NULL,
	[Is_Allow_Appointment] [bit] NULL,
	[Rating] [float] NULL,
	[Rating_Count] [int] NULL,
	[Created_Person] [int] NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Hospital] PRIMARY KEY CLUSTERED 
(
	[Hospital_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Hospital_Speciality]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Hospital_Speciality](
	[Hospital_ID] [int] NOT NULL,
	[Speciality_ID] [int] NOT NULL,
	[Is_Main_Speciality] [bit] NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Hospital_Speciality] PRIMARY KEY CLUSTERED 
(
	[Hospital_ID] ASC,
	[Speciality_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Speciality]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Speciality](
	[Speciality_ID] [int] IDENTITY(1,1) NOT NULL,
	[Speciality_Name] [nvarchar](64) NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Speciality] PRIMARY KEY CLUSTERED 
(
	[Speciality_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Speciality_Disease]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Speciality_Disease](
	[Speciality_ID] [int] NOT NULL,
	[Disease_ID] [int] NOT NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Speciality_Disease] PRIMARY KEY CLUSTERED 
(
	[Speciality_ID] ASC,
	[Disease_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  UserDefinedFunction [dbo].[SP_NON_DIACRITIC_DISEASE_IN_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[SP_NON_DIACRITIC_DISEASE_IN_HOSPITAL]
(
	@HospitalID INT
)
RETURNS TABLE
AS

	RETURN
	(SELECT d.Disease_ID,
		  [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE](d.Disease_Name) AS Disease_Name,
		  h.Hospital_ID
	FROM Disease d, [dbo].[Speciality_Disease] sd,
		 [dbo].[Hospital] h, [dbo].[Hospital_Speciality] hs, [dbo].[Speciality] s
	WHERE h.Hospital_ID = @HospitalID AND
		  h.Hospital_ID = hs.Hospital_ID AND
		  hs.Speciality_ID = sd.Speciality_ID AND
		  s.Speciality_ID = sd.Speciality_ID AND
		  sd.Disease_ID = d.Disease_ID)
GO
/****** Object:  UserDefinedFunction [dbo].[FU_NON_DIACRITIC_DISEASE_IN_HOSPITAL]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_NON_DIACRITIC_DISEASE_IN_HOSPITAL]
(
	@HospitalID INT
)
RETURNS TABLE
AS
	RETURN
	(SELECT d.Disease_ID,
		  [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE](d.Disease_Name) AS Disease_Name,
		  h.Hospital_ID
	FROM Disease d, [dbo].[Speciality_Disease] sd,
		 [dbo].[Hospital] h, [dbo].[Hospital_Speciality] hs, [dbo].[Speciality] s
	WHERE h.Hospital_ID = @HospitalID AND
		  h.Hospital_ID = hs.Hospital_ID AND
		  hs.Speciality_ID = sd.Speciality_ID AND
		  s.Speciality_ID = sd.Speciality_ID AND
		  sd.Disease_ID = d.Disease_ID)
GO
/****** Object:  View [dbo].[NON_DIACRITIC_SPECIALITY]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[NON_DIACRITIC_SPECIALITY]
WITH SCHEMABINDING
AS
SELECT Speciality_ID,
	   [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE](Speciality_Name) AS Speciality_Name
FROM [dbo].[Speciality]

GO
/****** Object:  View [dbo].[NON_DIACRITIC_DISEASE]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[NON_DIACRITIC_DISEASE]
WITH SCHEMABINDING
AS
SELECT Disease_ID,
	   [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE](Disease_Name) AS Disease_Name
FROM [dbo].[Disease]
GO
/****** Object:  Table [dbo].[Tag]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tag](
	[Word_ID] [int] IDENTITY(1,1) NOT NULL,
	[Word] [nvarchar](128) NULL,
	[Type] [int] NULL,
 CONSTRAINT [PK_WordDictionary] PRIMARY KEY CLUSTERED 
(
	[Word_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[NON_DIACRITIC_TAG]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[NON_DIACRITIC_TAG]
WITH SCHEMABINDING
AS
SELECT Word_ID,
	   [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE](Word) AS Word
FROM [dbo].[Tag]
WHERE [Type] = 3
GO
/****** Object:  Table [dbo].[Appointment]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Appointment](
	[Appointment_ID] [int] IDENTITY(1,1) NOT NULL,
	[Patient_Full_Name] [nvarchar](32) NULL,
	[Patient_Gender] [bit] NULL,
	[Patient_Birthday] [date] NULL,
	[Patient_Phone_Number] [varchar](13) NULL,
	[Patient_Email] [varchar](64) NULL,
	[Appointment_Date] [date] NULL,
	[Start_Time] [time](7) NULL,
	[End_Time] [time](7) NULL,
	[In_Charge_Doctor] [int] NULL,
	[Curing_Hospital] [int] NULL,
	[Health_Insurance_Code] [varchar](15) NULL,
	[Symptom_Description] [nvarchar](256) NULL,
	[Confirm_Code] [varchar](8) NULL,
	[Is_Confirm] [bit] NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Appointment] PRIMARY KEY CLUSTERED 
(
	[Appointment_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[City]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[City](
	[City_ID] [int] NOT NULL,
	[City_Name] [nvarchar](32) NULL,
	[Type] [nvarchar](9) NULL,
 CONSTRAINT [PK_City] PRIMARY KEY CLUSTERED 
(
	[City_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[District]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[District](
	[District_ID] [int] NOT NULL,
	[District_Name] [nvarchar](32) NULL,
	[Type] [nvarchar](9) NULL,
	[Coordinate] [varchar](26) NULL,
	[City_ID] [int] NULL,
 CONSTRAINT [PK_District] PRIMARY KEY CLUSTERED 
(
	[District_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Doctor]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Doctor](
	[Doctor_ID] [int] IDENTITY(1,1) NOT NULL,
	[First_Name] [nvarchar](32) NULL,
	[Last_Name] [nvarchar](32) NULL,
	[Gender] [bit] NULL,
	[Degree] [nvarchar](256) NULL,
	[Experience] [nvarchar](512) NULL,
	[Working_Day] [varchar](33) NULL,
	[Photo_ID] [int] NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Doctor] PRIMARY KEY CLUSTERED 
(
	[Doctor_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Doctor_Hospital]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Doctor_Hospital](
	[Doctor_ID] [int] NOT NULL,
	[Hospital_ID] [int] NOT NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Doctor_Hospital] PRIMARY KEY CLUSTERED 
(
	[Doctor_ID] ASC,
	[Hospital_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Doctor_Speciality]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Doctor_Speciality](
	[Doctor_ID] [int] NOT NULL,
	[Speciality_ID] [int] NOT NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Doctor_Speciality] PRIMARY KEY CLUSTERED 
(
	[Doctor_ID] ASC,
	[Speciality_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Facility]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Facility](
	[Facility_ID] [int] IDENTITY(1,1) NOT NULL,
	[Facility_Name] [nvarchar](64) NULL,
	[Facility_Type] [int] NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Facility] PRIMARY KEY CLUSTERED 
(
	[Facility_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FacilityType]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FacilityType](
	[Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Type_Name] [nvarchar](64) NULL,
 CONSTRAINT [PK_FacilityType] PRIMARY KEY CLUSTERED 
(
	[Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Feedback]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Feedback](
	[Feedback_ID] [int] IDENTITY(1,1) NOT NULL,
	[Header] [nvarchar](64) NULL,
	[Feedback_Content] [nvarchar](256) NULL,
	[Feedback_Type] [int] NULL,
	[Email] [varchar](64) NULL,
	[Hospital_ID] [int] NULL,
	[Created_Date] [datetime] NULL,
	[Is_Response] [bit] NULL,
 CONSTRAINT [PK_Feedback] PRIMARY KEY CLUSTERED 
(
	[Feedback_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FeedbackType]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FeedbackType](
	[Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Type_Name] [nvarchar](256) NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Feedback_Type] PRIMARY KEY CLUSTERED 
(
	[Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Hospital_Facility]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Hospital_Facility](
	[Hospital_ID] [int] NOT NULL,
	[Facility_ID] [int] NOT NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Hospital_Facility] PRIMARY KEY CLUSTERED 
(
	[Hospital_ID] ASC,
	[Facility_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Hospital_Service]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Hospital_Service](
	[Hospital_ID] [int] NOT NULL,
	[Service_ID] [int] NOT NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Hospital_Service] PRIMARY KEY CLUSTERED 
(
	[Hospital_ID] ASC,
	[Service_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[HospitalType]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HospitalType](
	[Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Type_Name] [nvarchar](32) NULL,
 CONSTRAINT [PK_HospitalType] PRIMARY KEY CLUSTERED 
(
	[Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Photo]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Photo](
	[Photo_ID] [int] IDENTITY(1,1) NOT NULL,
	[File_Path] [varchar](256) NULL,
	[Caption] [nvarchar](128) NULL,
	[Add_Date] [datetime] NULL,
	[Hospital_ID] [int] NULL,
	[Doctor_ID] [int] NULL,
	[Uploaded_Person] [int] NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Photo] PRIMARY KEY CLUSTERED 
(
	[Photo_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Rating]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rating](
	[Rating_ID] [int] IDENTITY(1,1) NOT NULL,
	[Score] [int] NULL,
	[Hospital_ID] [int] NULL,
	[Created_Person] [int] NULL,
 CONSTRAINT [PK_Rating] PRIMARY KEY CLUSTERED 
(
	[Rating_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Role]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Role](
	[Role_ID] [int] IDENTITY(1,1) NOT NULL,
	[Role_Name] [nvarchar](32) NULL,
 CONSTRAINT [PK_Role] PRIMARY KEY CLUSTERED 
(
	[Role_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SearchQuery]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SearchQuery](
	[Sentence_ID] [int] IDENTITY(1,1) NOT NULL,
	[Sentence] [nvarchar](64) NULL,
	[Search_Date] [datetime] NULL,
	[Result_Count] [int] NULL,
	[Search_Time_Count] [int] NULL,
 CONSTRAINT [PK_SentenceDictionary] PRIMARY KEY CLUSTERED 
(
	[Sentence_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Service]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Service](
	[Service_ID] [int] IDENTITY(1,1) NOT NULL,
	[Service_Name] [nvarchar](64) NULL,
	[Service_Type] [int] NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Service] PRIMARY KEY CLUSTERED 
(
	[Service_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ServiceType]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ServiceType](
	[Type_ID] [int] IDENTITY(1,1) NOT NULL,
	[Type_Name] [nvarchar](64) NULL,
 CONSTRAINT [PK_ServceType] PRIMARY KEY CLUSTERED 
(
	[Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Tag_Hospital]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tag_Hospital](
	[Word_ID] [int] NOT NULL,
	[Hospital_ID] [int] NOT NULL,
 CONSTRAINT [PK_Table_Word_Hospital] PRIMARY KEY CLUSTERED 
(
	[Hospital_ID] ASC,
	[Word_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[User]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[User](
	[User_ID] [int] IDENTITY(1,1) NOT NULL,
	[Email] [varchar](64) NULL,
	[Password] [nvarchar](32) NULL,
	[Secondary_Email] [varchar](64) NULL,
	[First_Name] [nvarchar](16) NULL,
	[Last_Name] [nvarchar](16) NULL,
	[Phone_Number] [varchar](13) NULL,
	[Role_ID] [int] NULL,
	[Confirmed_Person] [int] NULL,
	[Hospital_ID] [int] NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_User] PRIMARY KEY CLUSTERED 
(
	[User_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Ward]    Script Date: 9/6/2014 11:35:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Ward](
	[Ward_ID] [int] NOT NULL,
	[Ward_Name] [nvarchar](32) NULL,
	[Type] [nvarchar](9) NULL,
	[Coordinate] [varchar](26) NULL,
	[District_ID] [int] NULL,
 CONSTRAINT [PK_Ward] PRIMARY KEY CLUSTERED 
(
	[Ward_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [NON_DIACRITIC_INDEX]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE UNIQUE CLUSTERED INDEX [NON_DIACRITIC_INDEX] ON [dbo].[NON_DIACRITIC_DISEASE]
(
	[Disease_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [NON_DIACRITIC_INDEX]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE UNIQUE CLUSTERED INDEX [NON_DIACRITIC_INDEX] ON [dbo].[NON_DIACRITIC_SPECIALITY]
(
	[Speciality_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [NON_DIACRITIC_INDEX]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE UNIQUE CLUSTERED INDEX [NON_DIACRITIC_INDEX] ON [dbo].[NON_DIACRITIC_TAG]
(
	[Word_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [NonClusteredIndex-20140902-105037]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20140902-105037] ON [dbo].[Disease]
(
	[Disease_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20140902-105817]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20140902-105817] ON [dbo].[Hospital_Speciality]
(
	[Hospital_ID] ASC,
	[Speciality_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [NonClusteredIndex-20140902-105020]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20140902-105020] ON [dbo].[Speciality]
(
	[Speciality_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20140902-105755]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20140902-105755] ON [dbo].[Speciality_Disease]
(
	[Speciality_ID] ASC,
	[Disease_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [NonClusteredIndex-20140902-104946]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20140902-104946] ON [dbo].[Tag]
(
	[Word] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [NonClusteredIndex-20140902-110710]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20140902-110710] ON [dbo].[Tag_Hospital]
(
	[Word_ID] ASC,
	[Hospital_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [NON_DIACRITIC_NAME_INDEX]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE NONCLUSTERED INDEX [NON_DIACRITIC_NAME_INDEX] ON [dbo].[NON_DIACRITIC_DISEASE]
(
	[Disease_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [NON_DIACRITIC_NAME_INDEX]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE NONCLUSTERED INDEX [NON_DIACRITIC_NAME_INDEX] ON [dbo].[NON_DIACRITIC_SPECIALITY]
(
	[Speciality_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [NON_DIACRITIC_NAME_INDEX]    Script Date: 9/6/2014 11:35:54 PM ******/
CREATE NONCLUSTERED INDEX [NON_DIACRITIC_NAME_INDEX] ON [dbo].[NON_DIACRITIC_TAG]
(
	[Word] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Appointment]  WITH CHECK ADD  CONSTRAINT [FK_Appointment_Doctor] FOREIGN KEY([In_Charge_Doctor])
REFERENCES [dbo].[Doctor] ([Doctor_ID])
GO
ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [FK_Appointment_Doctor]
GO
ALTER TABLE [dbo].[Appointment]  WITH CHECK ADD  CONSTRAINT [FK_Appointment_Hospital] FOREIGN KEY([Curing_Hospital])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [FK_Appointment_Hospital]
GO
ALTER TABLE [dbo].[District]  WITH CHECK ADD  CONSTRAINT [FK_District_City] FOREIGN KEY([City_ID])
REFERENCES [dbo].[City] ([City_ID])
GO
ALTER TABLE [dbo].[District] CHECK CONSTRAINT [FK_District_City]
GO
ALTER TABLE [dbo].[Doctor_Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Doctor_Hospital_Doctor] FOREIGN KEY([Doctor_ID])
REFERENCES [dbo].[Doctor] ([Doctor_ID])
GO
ALTER TABLE [dbo].[Doctor_Hospital] CHECK CONSTRAINT [FK_Doctor_Hospital_Doctor]
GO
ALTER TABLE [dbo].[Doctor_Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Doctor_Hospital_Hospital] FOREIGN KEY([Hospital_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Doctor_Hospital] CHECK CONSTRAINT [FK_Doctor_Hospital_Hospital]
GO
ALTER TABLE [dbo].[Doctor_Speciality]  WITH CHECK ADD  CONSTRAINT [FK_Doctor_Speciality_Doctor] FOREIGN KEY([Doctor_ID])
REFERENCES [dbo].[Doctor] ([Doctor_ID])
GO
ALTER TABLE [dbo].[Doctor_Speciality] CHECK CONSTRAINT [FK_Doctor_Speciality_Doctor]
GO
ALTER TABLE [dbo].[Doctor_Speciality]  WITH CHECK ADD  CONSTRAINT [FK_Doctor_Speciality_Speciality] FOREIGN KEY([Speciality_ID])
REFERENCES [dbo].[Speciality] ([Speciality_ID])
GO
ALTER TABLE [dbo].[Doctor_Speciality] CHECK CONSTRAINT [FK_Doctor_Speciality_Speciality]
GO
ALTER TABLE [dbo].[Facility]  WITH CHECK ADD  CONSTRAINT [FK_Facility_FacilityType] FOREIGN KEY([Facility_Type])
REFERENCES [dbo].[FacilityType] ([Type_ID])
GO
ALTER TABLE [dbo].[Facility] CHECK CONSTRAINT [FK_Facility_FacilityType]
GO
ALTER TABLE [dbo].[Feedback]  WITH CHECK ADD  CONSTRAINT [FK_Feedback_Feedback_Type] FOREIGN KEY([Feedback_Type])
REFERENCES [dbo].[FeedbackType] ([Type_ID])
GO
ALTER TABLE [dbo].[Feedback] CHECK CONSTRAINT [FK_Feedback_Feedback_Type]
GO
ALTER TABLE [dbo].[Feedback]  WITH CHECK ADD  CONSTRAINT [FK_Feedback_Hospital] FOREIGN KEY([Hospital_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Feedback] CHECK CONSTRAINT [FK_Feedback_Hospital]
GO
ALTER TABLE [dbo].[Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_City] FOREIGN KEY([City_ID])
REFERENCES [dbo].[City] ([City_ID])
GO
ALTER TABLE [dbo].[Hospital] CHECK CONSTRAINT [FK_Hospital_City]
GO
ALTER TABLE [dbo].[Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_District] FOREIGN KEY([District_ID])
REFERENCES [dbo].[District] ([District_ID])
GO
ALTER TABLE [dbo].[Hospital] CHECK CONSTRAINT [FK_Hospital_District]
GO
ALTER TABLE [dbo].[Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_HospitalType] FOREIGN KEY([Hospital_Type])
REFERENCES [dbo].[HospitalType] ([Type_ID])
GO
ALTER TABLE [dbo].[Hospital] CHECK CONSTRAINT [FK_Hospital_HospitalType]
GO
ALTER TABLE [dbo].[Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_User] FOREIGN KEY([Created_Person])
REFERENCES [dbo].[User] ([User_ID])
GO
ALTER TABLE [dbo].[Hospital] CHECK CONSTRAINT [FK_Hospital_User]
GO
ALTER TABLE [dbo].[Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_Ward] FOREIGN KEY([Ward_ID])
REFERENCES [dbo].[Ward] ([Ward_ID])
GO
ALTER TABLE [dbo].[Hospital] CHECK CONSTRAINT [FK_Hospital_Ward]
GO
ALTER TABLE [dbo].[Hospital_Facility]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_Facility_Facility] FOREIGN KEY([Facility_ID])
REFERENCES [dbo].[Facility] ([Facility_ID])
GO
ALTER TABLE [dbo].[Hospital_Facility] CHECK CONSTRAINT [FK_Hospital_Facility_Facility]
GO
ALTER TABLE [dbo].[Hospital_Facility]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_Facility_Hospital] FOREIGN KEY([Hospital_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Hospital_Facility] CHECK CONSTRAINT [FK_Hospital_Facility_Hospital]
GO
ALTER TABLE [dbo].[Hospital_Service]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_Service_Hospital] FOREIGN KEY([Hospital_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Hospital_Service] CHECK CONSTRAINT [FK_Hospital_Service_Hospital]
GO
ALTER TABLE [dbo].[Hospital_Service]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_Service_Service] FOREIGN KEY([Service_ID])
REFERENCES [dbo].[Service] ([Service_ID])
GO
ALTER TABLE [dbo].[Hospital_Service] CHECK CONSTRAINT [FK_Hospital_Service_Service]
GO
ALTER TABLE [dbo].[Hospital_Speciality]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_Speciality_Hospital] FOREIGN KEY([Hospital_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Hospital_Speciality] CHECK CONSTRAINT [FK_Hospital_Speciality_Hospital]
GO
ALTER TABLE [dbo].[Hospital_Speciality]  WITH CHECK ADD  CONSTRAINT [FK_Hospital_Speciality_Speciality] FOREIGN KEY([Speciality_ID])
REFERENCES [dbo].[Speciality] ([Speciality_ID])
GO
ALTER TABLE [dbo].[Hospital_Speciality] CHECK CONSTRAINT [FK_Hospital_Speciality_Speciality]
GO
ALTER TABLE [dbo].[Photo]  WITH CHECK ADD  CONSTRAINT [FK_Photo_Doctor1] FOREIGN KEY([Doctor_ID])
REFERENCES [dbo].[Doctor] ([Doctor_ID])
GO
ALTER TABLE [dbo].[Photo] CHECK CONSTRAINT [FK_Photo_Doctor1]
GO
ALTER TABLE [dbo].[Photo]  WITH CHECK ADD  CONSTRAINT [FK_Photo_Hospital] FOREIGN KEY([Hospital_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Photo] CHECK CONSTRAINT [FK_Photo_Hospital]
GO
ALTER TABLE [dbo].[Photo]  WITH CHECK ADD  CONSTRAINT [FK_Photo_User] FOREIGN KEY([Uploaded_Person])
REFERENCES [dbo].[User] ([User_ID])
GO
ALTER TABLE [dbo].[Photo] CHECK CONSTRAINT [FK_Photo_User]
GO
ALTER TABLE [dbo].[Rating]  WITH CHECK ADD  CONSTRAINT [FK_Rating_Hospital] FOREIGN KEY([Hospital_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Rating] CHECK CONSTRAINT [FK_Rating_Hospital]
GO
ALTER TABLE [dbo].[Rating]  WITH CHECK ADD  CONSTRAINT [FK_Rating_User] FOREIGN KEY([Created_Person])
REFERENCES [dbo].[User] ([User_ID])
GO
ALTER TABLE [dbo].[Rating] CHECK CONSTRAINT [FK_Rating_User]
GO
ALTER TABLE [dbo].[Service]  WITH CHECK ADD  CONSTRAINT [FK_Service_ServiceType] FOREIGN KEY([Service_Type])
REFERENCES [dbo].[ServiceType] ([Type_ID])
GO
ALTER TABLE [dbo].[Service] CHECK CONSTRAINT [FK_Service_ServiceType]
GO
ALTER TABLE [dbo].[Speciality_Disease]  WITH CHECK ADD  CONSTRAINT [FK_Speciality_Disease_Disease] FOREIGN KEY([Disease_ID])
REFERENCES [dbo].[Disease] ([Disease_ID])
GO
ALTER TABLE [dbo].[Speciality_Disease] CHECK CONSTRAINT [FK_Speciality_Disease_Disease]
GO
ALTER TABLE [dbo].[Speciality_Disease]  WITH CHECK ADD  CONSTRAINT [FK_Speciality_Disease_Speciality] FOREIGN KEY([Speciality_ID])
REFERENCES [dbo].[Speciality] ([Speciality_ID])
GO
ALTER TABLE [dbo].[Speciality_Disease] CHECK CONSTRAINT [FK_Speciality_Disease_Speciality]
GO
ALTER TABLE [dbo].[Tag_Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Tag_Hospital_Tag] FOREIGN KEY([Word_ID])
REFERENCES [dbo].[Tag] ([Word_ID])
GO
ALTER TABLE [dbo].[Tag_Hospital] CHECK CONSTRAINT [FK_Tag_Hospital_Tag]
GO
ALTER TABLE [dbo].[Tag_Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Word_Hospital_Hospital] FOREIGN KEY([Hospital_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Tag_Hospital] CHECK CONSTRAINT [FK_Word_Hospital_Hospital]
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD  CONSTRAINT [FK_User_Hospital] FOREIGN KEY([Hospital_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[User] CHECK CONSTRAINT [FK_User_Hospital]
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD  CONSTRAINT [FK_User_Role] FOREIGN KEY([Role_ID])
REFERENCES [dbo].[Role] ([Role_ID])
GO
ALTER TABLE [dbo].[User] CHECK CONSTRAINT [FK_User_Role]
GO
ALTER TABLE [dbo].[User]  WITH CHECK ADD  CONSTRAINT [FK_User_User] FOREIGN KEY([Confirmed_Person])
REFERENCES [dbo].[User] ([User_ID])
GO
ALTER TABLE [dbo].[User] CHECK CONSTRAINT [FK_User_User]
GO
ALTER TABLE [dbo].[Ward]  WITH CHECK ADD  CONSTRAINT [FK_Ward_District] FOREIGN KEY([District_ID])
REFERENCES [dbo].[District] ([District_ID])
GO
ALTER TABLE [dbo].[Ward] CHECK CONSTRAINT [FK_Ward_District]
GO
USE [master]
GO
ALTER DATABASE [HospitalF] SET  READ_WRITE 
GO

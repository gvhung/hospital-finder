USE [HospitalF]
GO
/****** Object:  StoredProcedure [dbo].[SP_ADVANCED_SEARCH_HOSPITAL]    Script Date: 7/26/2014 7:58:28 PM ******/
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

	DECLARE @DiseaseID INT = NULL
	IF (@DiseaseName IS NOT NULL)
		BEGIN
			SET @DiseaseID = (SELECT Disease_ID
							  FROM Disease
							  WHERE Disease_Name LIKE (N'%' + @DiseaseName + N'%'))
		END

	-- SET VALUE FOR 'WHAT' and 'WHERE' PHRASE
	DECLARE @WhatPhrase INT = NULL,
			@WherePhrase INT = 1

	IF (@SpecialityID IS NULL AND @DiseaseName IS NULL)
		SET @WhatPhrase = 0
	ELSE
		SET @WhatPhrase = 1

	DECLARE @SelectPhrase NVARCHAR(512) = NULL
	SET @SelectPhrase = N'SELECT DISTINCT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,' +
						N'h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,' +
						N'h.Ordinary_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,' +
						N'h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,' +
						N'[dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating'

	DECLARE @FromPhrase NVARCHAR(512) = NULL
	SET @FromPhrase = N'FROM Hospital h'

	DECLARE @ConditionPhrase NVARCHAR(512) = NULL
	SET @ConditionPhrase = N'WHERE h.Is_Active = ''True'''

	DECLARE @OrderPhrase NVARCHAR(512)
	SET @OrderPhrase = N'ORDER BY h.Hospital_Name'

	DECLARE @SqlQuery NVARCHAR(512) = NULL

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

		EXECUTE SP_EXECUTESQL @SqlQuery,
							  N'@CityID INT, @DistrictID INT',
							  @CityID, @DistrictID
		RETURN;
	END
	
	-- CASE THAT WHAT PHRASE AND WHERE PHRASE HAVE VALUE
	IF (@WhatPhrase = 1)
	BEGIN		
		SET @FromPhrase += CASE WHEN @DiseaseID IS NOT NULL
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

		SET @ConditionPhrase += CASE WHEN @SpecialityID IS NOT NULL
								THEN N' AND hs.Speciality_ID = @SpecialityID'
								ELSE ''
								END;
		SET @ConditionPhrase += CASE WHEN @DiseaseID IS NOT NULL
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

		EXECUTE SP_EXECUTESQL @SqlQuery,
							  N'@CityID INT, @DistrictID INT, @SpecialityID INT, @DiseaseID INT',
							  @CityID, @DistrictID, @SpecialityID, @DiseaseID
		RETURN;
	END
END
GO
/****** Object:  StoredProcedure [dbo].[SP_CHANGE_HOSPITAL_STATUS]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  StoredProcedure [dbo].[SP_CHECK_NOT_DUPLICATED_HOSPITAL]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_CHECK_NOT_DUPLICATED_HOSPITAL]
	@CityID INT,
	@DistrictID INT,
	@WardID INT,
	@Address NVARCHAR(64)
AS
BEGIN
	IF (EXISTS(SELECT Hospital_ID
			   FROM Hospital
			   WHERE City_ID = @CityID AND
				     District_ID = @DistrictID AND
				     Ward_ID = @WardID AND
				     [dbo].[FU_REMOVE_WHITE_SPACE]([Address]) LIKE
					 N'%' + [dbo].[FU_REMOVE_WHITE_SPACE](@Address) + N'%'))
		RETURN 0;
	ELSE
		RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_CHECK_VALID_USER_IN_CHARGED]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  StoredProcedure [dbo].[SP_INSERT_APPOINTMENT]    Script Date: 7/26/2014 7:58:28 PM ******/
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
	@Confirm_Code varchar(8)
AS
BEGIN
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
		,[Confirm_Code])
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
		,@Confirm_Code)
	IF @@ROWCOUNT >0
		RETURN 1
	ELSE
		RETURN 0
END

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIP TO LOAD TOP 10 RATED HOSPITALS
-- SONNX
IF OBJECT_ID('[SP_TAKE_TOP_10_RATED_HOSPITAL]', 'P') IS NOT NULL
	DROP PROCEDURE [SP_TAKE_TOP_10_RATED_HOSPITAL]

GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_HOSPITAL]    Script Date: 7/26/2014 7:58:28 PM ******/
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
	@SpecialityList NVARCHAR(4000),
	@ServiceList NVARCHAR(4000),
	@FacilityList NVARCHAR(4000)
AS
BEGIN
	BEGIN TRANSACTION T

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

		-- INSERT TO HOSPITAL_SPECIALITY TABLE
		IF (@SpecialityList != '')
		BEGIN
			DECLARE @RowNumber INT = 1
			DECLARE @TotalToken  INT = 0;
			DECLARE @Token VARCHAR(4)
			DECLARE @HospitalID INT = (SELECT TOP 1 Hospital_ID
									   FROM Hospital
									   ORDER BY Hospital_ID DESC)

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

				IF @@ROWCOUNT = 0
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
			SET @TotalToken = 0;

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

				IF @@ROWCOUNT = 0
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
			SET @TotalToken = 0;

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

				IF @@ROWCOUNT = 0
				BEGIN
					ROLLBACK TRAN T;
					RETURN 0;
				END

				SET @RowNumber += 1
			END
		END	
	END
	COMMIT TRAN T;

	RETURN 1;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_INSERT_HOSPITAL_USER]    Script Date: 7/26/2014 7:58:28 PM ******/
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
		'True'
	)

	IF @@ROWCOUNT = 0
		RETURN 1;
	ELSE
		RETURN 0;
END
GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_DISEASE_IN_SPECIALITY]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  StoredProcedure [dbo].[SP_LOAD_DOCTOR_BY_SPECIALITYID]    Script Date: 7/26/2014 7:58:28 PM ******/
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
GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_DOCTOR_IN_DOCTOR_HOSPITAL]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  StoredProcedure [dbo].[SP_LOAD_FACILITY_IN_HOSPITAL_FACILITY]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  StoredProcedure [dbo].[SP_LOAD_HOSPITAL_LIST]    Script Date: 7/26/2014 7:58:28 PM ******/
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
	SET @ChildWherePHrase += CASE WHEN @HospitalName IS NOT NULL
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
/****** Object:  StoredProcedure [dbo].[SP_LOAD_SERVICE_IN_HOSPITAL_SERVICE]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  StoredProcedure [dbo].[SP_LOAD_SPECIALITY_BY_HOSPITALID]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_LOAD_SPECIALITY_BY_HOSPITALID]
	@Hospital_ID INT
AS
BEGIN
	SELECT	s.Speciality_ID,s.Speciality_Name
	FROM	Hospital_Speciality AS hs, Speciality AS s
	WHERE	@Hospital_ID=hs.Hospital_ID AND
			hs.Speciality_ID=s.Speciality_ID
END

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO LOAD ALL DOCTOR OF SPECIALITY
-- ANHDTH
IF OBJECT_ID('[SP_LOAD_DOCTOR_BY_SPECIALITYID]') IS NOT NULL
	DROP PROCEDURE [SP_LOAD_DOCTOR_BY_SPECIALITYID]

GO
/****** Object:  StoredProcedure [dbo].[SP_LOAD_SPECIALITY_IN_DOCTOR_SPECIALITY]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  StoredProcedure [dbo].[SP_LOAD_TYPE_OF_HOSPITAL]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  StoredProcedure [dbo].[SP_LOCATION_SEARCH_HOSPITAL]    Script Date: 7/26/2014 7:58:28 PM ******/
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
		   h.Ordinary_End_Time, h.Short_Description, h.Full_Description, h.Holiday_End_Time,
		   h.Is_Allow_Appointment, h.Is_Active, h.Coordinate, h.Holiday_Start_Time,
		   [dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
	FROM Hospital h
	WHERE h.Is_Active = 'True' AND
		  [dbo].[FU_GET_DISTANCE] 
			(CONVERT(FLOAT, SUBSTRING(h.Coordinate, 1, CHARINDEX(',', h.Coordinate) - 1)),
			 CONVERT(FLOAT, SUBSTRING(h.Coordinate, CHARINDEX(',', h.Coordinate) + 1, LEN(h.Coordinate))),
			 @Latitude, @Longitude) <= CONVERT(INT, @Distance)
END
GO
/****** Object:  StoredProcedure [dbo].[SP_NORMAL_SEARCH_HOSPITAL]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_NORMAL_SEARCH_HOSPITAL]
	@WhatPhrase NVARCHAR(128), -- ALWAYS NOT NULL
	@CityID INT,
	@DistrictName NVARCHAR(32)
AS
BEGIN
	-- DEFINE @WherePhrase
	DECLARE @WherePhrase INT
	IF (@CityID != 0 AND @DistrictName IS NOT NULL)
		SET @WherePhrase = 1
	ELSE
		SET @WherePhrase = 0

	-- DEFAULT VALUE TO CONSIDER ANALYZING @WhatPhrase
	DECLARE @Boundary INT = 30

	-- DECLARE TEMPORARY TABLE THAT CONTAIN LIST OF HOSPITALS
	DECLARE @HospitalList TABLE([Priority] INT IDENTITY(1,1) PRIMARY KEY,
							    Hospital_ID INT)

	-- DECLARE VARIABLE TO COUNT NUMBER OF RECORDS IN @HospitalList
	DECLARE @TotalRecordInHospitalList INT =
		(SELECT wh.Hospital_ID
		 FROM WordDictionary w, Word_Hospital wh
		 WHERE w.Word LIKE N'%' + @WhatPhrase + N'%' AND
			   w.[Priority] != 1 AND
			   w.Word_ID = wh.Word_ID)

	IF (@TotalRecordInHospitalList > 0)
	BEGIN
		IF (@WherePhrase = 1)
		BEGIN
			INSERT INTO @HospitalList
			SELECT (SELECT h.Hospital_ID
					FROM Hospital h, District d,
						 (SELECT wh.Hospital_ID
						  FROM WordDictionary w, Word_Hospital wh
						  WHERE w.Word LIKE N'%' + @WhatPhrase + N'%' AND
								w.[Priority] != 1 AND
								w.Word_ID = wh.Word_ID) w
					WHERE h.City_ID = @CityID AND
						  d.District_Name = @DistrictName AND
						  d.District_ID = h.District_ID AND
						  h.Hospital_ID = w.Hospital_ID)
		END
		ELSE
		BEGIN
			-- ADD THE HOSPITALS THAT HAVE CITY CONTAINS IN @WherePhrase
			IF (@CityID != 0)
			BEGIN
				INSERT INTO @HospitalList
				SELECT (SELECT h.Hospital_ID
						FROM Hospital h, 
							 (SELECT wh.Hospital_ID
							  FROM WordDictionary w, Word_Hospital wh
							  WHERE w.Word LIKE N'%' + @WhatPhrase + N'%' AND
									w.[Priority] != 1 AND
									w.Word_ID = wh.Word_ID) w
						WHERE h.City_ID = @CityID AND
							  w.Hospital_ID = h.Hospital_ID)
			END

			-- ADD THE HOSPITALS THAT HAVE DISTRICT CONTAINS IN @WherePhrase
			IF (@DistrictName IS NOT NULL)
			BEGIN
				INSERT INTO @HospitalList
				SELECT (SELECT h.Hospital_ID
						FROM District d, Hospital h,
							 (SELECT wh.Hospital_ID
							  FROM WordDictionary w, Word_Hospital wh
							  WHERE w.Word LIKE N'%' + @WhatPhrase + N'%' AND
									w.[Priority] != 1 AND
									w.Word_ID = wh.Word_ID) w
						WHERE d.District_Name = @DistrictName AND
							  d.District_ID = h.District_ID AND
							  w.Hospital_ID = h.Hospital_ID)
			END
		END
	END

	IF (@TotalRecordInHospitalList > @Boundary)
	BEGIN
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
			   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
			   h.OrDinary_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,
			   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
			   [dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
		FROM Hospital h, @HospitalList list
		WHERE h.Hospital_ID = list.Hospital_ID AND
			  h.Is_Active = 'True'
		ORDER BY list.[Priority] ASC
		RETURN;
	END
	
-------------------------------------------------------------------------------------------

	-- ADD THE HOSPITALS THAT HAVE NAME CONTAINS IN @WhatPhrase
	INSERT INTO @HospitalList
	SELECT (SELECT h.Hospital_ID
			FROM Hospital h
			WHERE h.Hospital_Name LIKE
				  @WhatPhrase)

	-- COUNT NUMBER OF RECORD IN @HospitalList AGAIN
	SET @TotalRecordInHospitalList = (SELECT COUNT([Priority])
									  FROM @HospitalList)
	
	IF (@TotalRecordInHospitalList > @Boundary)
	BEGIN
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
			   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
			   h.Holiday_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,
			   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
			   [dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
		FROM Hospital h, @HospitalList list
		WHERE h.Hospital_ID = list.Hospital_ID AND
			  h.Is_Active = 'True'
		ORDER BY list.[Priority] ASC
		RETURN;
	END

-------------------------------------------------------------------------------------------

	-- ADD THE HOSPITALS THAT HAVE SPECIALITY CONTAINS IN @WhatPhrase
	INSERT INTO @HospitalList
	SELECT (SELECT h.Hospital_ID
			FROM Speciality s, Hospital h, Hospital_Speciality hs
			WHERE s.Speciality_Name LIKE
				  @WhatPhrase AND
				  s.Speciality_ID = hs.Speciality_ID AND
				  h.Hospital_ID = hs.Hospital_ID)

	-- COUNT NUMBER OF RECORD IN @HospitalList AGAIN
	SET @TotalRecordInHospitalList = (SELECT COUNT([Priority])
									  FROM @HospitalList)
	
	IF (@TotalRecordInHospitalList > @Boundary)
	BEGIN
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
			   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
			   h.Holiday_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,
			   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
			   [dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
		FROM Hospital h, @HospitalList list
		WHERE h.Hospital_ID = list.Hospital_ID AND
			  h.Is_Active = 'True'
		ORDER BY list.[Priority] ASC
		RETURN;
	END

-------------------------------------------------------------------------------------------

	-- CHECK IF @WherePhrase IS AVAILABLE
	IF (@WherePhrase = 1)
	BEGIN
		INSERT INTO @HospitalList
		SELECT (SELECT h.Hospital_ID
				FROM Hospital h, District d
				WHERE h.City_ID = @CityID AND
					  d.District_Name = @DistrictName AND
					  d.District_ID = h.District_ID)
	END
	ELSE
	BEGIN
		-- ADD THE HOSPITALS THAT HAVE CITY CONTAINS IN @WherePhrase
		IF (@CityID != 0)
		BEGIN
			INSERT INTO @HospitalList
			SELECT (SELECT h.Hospital_ID
					FROM Hospital h
					WHERE h.City_ID = @CityID)
		END

		-- ADD THE HOSPITALS THAT HAVE DISTRICT CONTAINS IN @WherePhrase
		IF (@DistrictName IS NOT NULL)
		BEGIN
			INSERT INTO @HospitalList
			SELECT (SELECT h.Hospital_ID
					FROM District d, Hospital h
					WHERE d.District_Name = @DistrictName AND
						  d.District_ID = h.District_ID)
		END
	END

	-- COUNT NUMBER OF RECORD IN @HospitalList AGAIN
	SET @TotalRecordInHospitalList = (SELECT COUNT([Priority])
									  FROM @HospitalList)
	

	IF (@TotalRecordInHospitalList > @Boundary)
	BEGIN
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
			   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
			   h.Holiday_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,
			   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
			   [dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
		FROM Hospital h, @HospitalList list
		WHERE h.Hospital_ID = list.Hospital_ID AND
			  h.Is_Active = 'True'
		ORDER BY list.[Priority] ASC
		RETURN;
	END


-------------------------------------------------------------------------------------------

	-- ADD THE HOSPITALS THAT HAVE DISEASE CONTAINS IN @WhatPhrase
	INSERT INTO @HospitalList
	SELECT (SELECT h.Hospital_ID
			FROM Disease d, Speciality_Disease sd,
					Hospital h, Hospital_Speciality hs
			WHERE d.Disease_Name LIKE
				  @WhatPhrase AND
				  d.Disease_ID = sd.Disease_ID AND
				  sd.Speciality_ID = hs.Speciality_ID AND
				  h.Hospital_ID = hs.Hospital_ID)

	-- COUNT NUMBER OF RECORD IN @HospitalList AGAIN
	SET @TotalRecordInHospitalList = (SELECT COUNT([Priority])
									  FROM @HospitalList)
	
	IF (@TotalRecordInHospitalList > @Boundary)
	BEGIN
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
				h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
				h.Holiday_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,
				h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
				[dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
		FROM Hospital h, @HospitalList list
		WHERE h.Hospital_ID = list.Hospital_ID AND
			  h.Is_Active = 'True'
		ORDER BY list.[Priority] ASC
		RETURN;
	END

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------

	-- TRANSFORM @WhatPhrase TO NON-DIACRITIC VIETNAMSE
	SET @WhatPhrase = [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE] (@WhatPhrase)

	-- HOPITAL NAME
	INSERT INTO @HospitalList
	SELECT (SELECT wh.Hospital_ID
			FROM WordDictionary w, Word_Hospital wh
			WHERE w.Word LIKE N'%' + @WhatPhrase + N'%' AND
				  w.[Priority] != 1 AND
				  w.Word_ID = wh.Word_ID)

	-- DECLARE VARIABLE TO COUNT NUMBER OF RECORDS IN @HospitalList
	SET @TotalRecordInHospitalList = (SELECT COUNT([Priority])
									  FROM @HospitalList)

	-- CHECK IF THERE ARE LESS THAN 30 RECORD IN @TotalHospital
	-- IF MORE THAN 30, QUERY DATA IN [Hospital] TABLE AND RETURN
	-- IF NOT, CONTINUE ANALYZING @WhatPhrase AND @WherePhrase
	IF (@TotalRecordInHospitalList > @Boundary)
	BEGIN
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
			   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
			   h.Holiday_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,
			   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
			   [dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
		FROM Hospital h, @HospitalList list
		WHERE h.Hospital_ID = list.Hospital_ID AND
			  h.Is_Active = 'True'
		ORDER BY list.[Priority] ASC
		RETURN;
	END
	
-------------------------------------------------------------------------------------------

	-- ADD THE HOSPITALS THAT HAVE NAME CONTAINS IN @WhatPhrase
	INSERT INTO @HospitalList
	SELECT (SELECT h.Hospital_ID
			FROM Hospital h
			WHERE [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE](h.Hospital_Name) LIKE
				  @WhatPhrase)

	-- COUNT NUMBER OF RECORD IN @HospitalList AGAIN
	SET @TotalRecordInHospitalList = (SELECT COUNT([Priority])
									  FROM @HospitalList)
	
	IF (@TotalRecordInHospitalList > @Boundary)
	BEGIN
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
			   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
			   h.Ordinary_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,
			   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
			   [dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
		FROM Hospital h, @HospitalList list
		WHERE h.Hospital_ID = list.Hospital_ID AND
			  h.Is_Active = 'True'
		ORDER BY list.[Priority] ASC
		RETURN;
	END

-------------------------------------------------------------------------------------------

	-- ADD THE HOSPITALS THAT HAVE SPECIALITY CONTAINS IN @WhatPhrase
	INSERT INTO @HospitalList
	SELECT (SELECT h.Hospital_ID
			FROM Speciality s, Hospital h, Hospital_Speciality hs
			WHERE [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE](s.Speciality_Name) LIKE
				  @WhatPhrase AND
				  s.Speciality_ID = hs.Speciality_ID AND
				  h.Hospital_ID = hs.Hospital_ID)

	-- COUNT NUMBER OF RECORD IN @HospitalList AGAIN
	SET @TotalRecordInHospitalList = (SELECT COUNT([Priority])
									  FROM @HospitalList)
	
	IF (@TotalRecordInHospitalList > @Boundary)
	BEGIN
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
			   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
			   h.Holiday_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,
			   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
			   [dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
		FROM Hospital h, @HospitalList list
		WHERE h.Hospital_ID = list.Hospital_ID AND
			  h.Is_Active = 'True'
		ORDER BY list.[Priority] ASC
		RETURN;
	END

-------------------------------------------------------------------------------------------

	-- CHECK IF @WherePhrase IS AVAILABLE
	SET @DistrictName = [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE] (@DistrictName)

	IF (@WherePhrase = 1)
	BEGIN
		INSERT INTO @HospitalList
		SELECT (SELECT h.Hospital_ID
				FROM Hospital h, District d
				WHERE h.City_ID = @CityID AND
					  [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE] (d.District_Name)
					  LIKE @DistrictName AND
					  d.District_ID = h.District_ID)
	END
	ELSE
	BEGIN
		-- ADD THE HOSPITALS THAT HAVE CITY CONTAINS IN @WherePhrase
		IF (@CityID != 0)
		BEGIN
			INSERT INTO @HospitalList
			SELECT (SELECT h.Hospital_ID
					FROM Hospital h
					WHERE h.City_ID = @CityID)
		END

		-- ADD THE HOSPITALS THAT HAVE DISTRICT CONTAINS IN @WherePhrase
		IF (@DistrictName IS NOT NULL)
		BEGIN
			INSERT INTO @HospitalList
			SELECT (SELECT h.Hospital_ID
					FROM District d, Hospital h
					WHERE [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE] (d.District_Name)
						  LIKE @DistrictName AND
						  d.District_ID = h.District_ID)
		END
	END

	-- COUNT NUMBER OF RECORD IN @HospitalList AGAIN
	SET @TotalRecordInHospitalList = (SELECT COUNT([Priority])
									  FROM @HospitalList)
	

	IF (@TotalRecordInHospitalList > @Boundary)
	BEGIN
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
			   h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
			   h.Holiday_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,
			   h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
			   [dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
		FROM Hospital h, @HospitalList list
		WHERE h.Hospital_ID = list.Hospital_ID AND
			  h.Is_Active = 'True'
		ORDER BY list.[Priority] ASC
		RETURN;
	END

-------------------------------------------------------------------------------------------

	-- ADD THE HOSPITALS THAT HAVE DISEASE CONTAINS IN @WhatPhrase
	INSERT INTO @HospitalList
	SELECT (SELECT h.Hospital_ID
			FROM Disease d, Speciality_Disease sd,
					Hospital h, Hospital_Speciality hs
			WHERE [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE](d.Disease_Name) LIKE
				  @WhatPhrase AND
				  d.Disease_ID = sd.Disease_ID AND
				  sd.Speciality_ID = hs.Speciality_ID AND
				  h.Hospital_ID = hs.Hospital_ID)

	-- COUNT NUMBER OF RECORD IN @HospitalList AGAIN
	SET @TotalRecordInHospitalList = (SELECT COUNT([Priority])
										FROM @HospitalList)
	
	IF (@TotalRecordInHospitalList > @Boundary)
	BEGIN
		SELECT h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, h.District_ID,
				h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website, h.Ordinary_Start_Time,
				h.Holiday_End_Time, h.Coordinate, h.Short_Description, h.Full_Description,
				h.Is_Allow_Appointment, h.Is_Active, h.Holiday_Start_Time, h.Holiday_End_Time,
				[dbo].[FU_CALCULATE_AVERAGE_RATING] (h.Hospital_ID) AS Rating
		FROM Hospital h, @HospitalList list
		WHERE h.Hospital_ID = list.Hospital_ID AND
			  h.Is_Active = 'True'
		ORDER BY list.[Priority] ASC
		RETURN;
	END

-------------------------------------------------------------------------------------------
END
GO
/****** Object:  StoredProcedure [dbo].[SP_RATE_HOSPITAL]    Script Date: 7/26/2014 7:58:28 PM ******/
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
		BEGIN TRAN
		BEGIN TRY
			INSERT INTO Rating (Score, Hospital_ID, Created_Person)
			VALUES (@Score, @Hospital_ID, @User_ID)
			
			DECLARE @Average_Score FLOAT
			SET @Average_Score = [dbo].[FU_CALCULATE_AVERAGE_RATING] (@Hospital_ID)
			
			UPDATE Hospital
			SET Rating = @Average_Score
			WHERE Hospital_ID = @Hospital_ID
						
			COMMIT TRAN
			RETURN @Average_Score
		END TRY
		BEGIN CATCH
			ROLLBACK TRAN
		END CATCH		
	END
END

GO
/****** Object:  StoredProcedure [dbo].[SP_SEARCH_DOCTOR]    Script Date: 7/26/2014 7:58:28 PM ******/
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
GO
/****** Object:  StoredProcedure [dbo].[SP_TAKE_FACILITY_AND_TYPE]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_TAKE_FACILITY_AND_TYPE]
AS
BEGIN
	SELECT f.Facility_ID, f.Facility_Name, t.[Type_Name], t.[Type_ID]
	FROM Facility f, FacilityType t
	WHERE f.Facility_Type = t.[Type_ID]
	ORDER BY t.[Type_ID] ASC
END


GO
/****** Object:  StoredProcedure [dbo].[SP_TAKE_SERVICE_AND_TYPE]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_TAKE_SERVICE_AND_TYPE]
AS
BEGIN
	SELECT s.Service_ID, s.[Service_Name], t.[Type_Name], t.[Type_ID]
	FROM [Service] s, ServiceType t
	WHERE s.Service_Type = t.[Type_ID]
	ORDER BY t.[Type_ID] ASC
END
GO
/****** Object:  StoredProcedure [dbo].[SP_TAKE_TOP_10_RATED_HOSPITAL]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_TAKE_TOP_10_RATED_HOSPITAL]
AS
BEGIN
	SELECT TOP 10 h.Hospital_ID, h.Hospital_Name, h.[Address], h.Ward_ID, 
		   h.District_ID, h.City_ID, h.Phone_Number, h.Fax, h.Email, h.Website,
		   h.Start_Time, h.End_Time, h.Coordinate, h.Short_Description,
		   h.Full_Description, h.Is_Allow_Appointment,
		   [dbo].[FU_CALCULATE_AVERAGE_RATING](h.Hospital_ID) AS AverageScore
	FROM Hospital h
	WHERE Is_Active = 'True'
	ORDER BY ([dbo].[FU_CALCULATE_AVERAGE_RATING](h.Hospital_ID)) DESC
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_AUTO_GENERATE_ENTITIES_CLASS]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_CALCULATE_AVERAGE_RATING]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_CREATE_BAD_MATCH_TABLE]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_GET_DISTANCE]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_GET_RADIUS]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_IS_PATTERN_MATCHED]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_REMOVE_WHITE_SPACE]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_STRING_COMPARE]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_STRING_TOKENIZE]    Script Date: 7/26/2014 7:58:28 PM ******/
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
						  Token NVARCHAR(32))
AS
BEGIN
	DECLARE @Token NVARCHAR(32)
	DECLARE @Position INT
	DECLARE @Id INT = 1

	WHILE CHARINDEX(@Delimeter, @InputStr) > 0
	BEGIN
		SELECT @Position = CHARINDEX(@Delimeter, @InputStr)
		SELECT @Token = SUBSTRING(@InputStr, 1, @Position - 1)

		INSERT INTO @TokenList 
		SELECT @Id, @Token

		SELECT @InputStr = SUBSTRING(@InputStr, @Position + 1, LEN(@InputStr) - @Position)
		SET @Id += 1
	END

	INSERT INTO @TokenList 
	SELECT @Id, @InputStr

	RETURN
END
GO
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_MATCHED_STRING_POSITION]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_PAIRS_OF_LETTER]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_TAKE_PAIRS_OF_LETTER_IN_WORD]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  UserDefinedFunction [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE]
(
      @strInput NVARCHAR(4000)
)
RETURNS NVARCHAR(4000)
AS
BEGIN    
    IF @strInput IS NULL
		RETURN @strInput
    IF @strInput = ''
		RETURN @strInput

    DECLARE @RT NVARCHAR(4000)
    DECLARE @DIACRITIC_CHARS NCHAR(136)
    DECLARE @NON_DIACRITIC_CHARS NCHAR (136)
 
    SET @DIACRITIC_CHARS = N'ăâđêôơưàảãạáằẳẵặắầẩẫậấèẻẽẹéềểễệếìỉĩịíòỏõọóồổỗộốờởỡợớùủũụúừửữựứỳỷỹỵý' +
						   N'ĂÂĐÊÔƠƯÀẢÃẠÁẰẲẴẶẮẦẨẪẬẤÈẺẼẸÉỀỂỄỆẾÌỈĨỊÍÒỎÕỌÓỒỔỖỘỐỜỞỠỢỚÙỦŨỤÚỪỬỮỰỨỲỶỸỴÝ' +
						   NCHAR(272) + NCHAR(208)

    SET @NON_DIACRITIC_CHARS = N'aadeoouaaaaaaaaaaaaaaaeeeeeeeeeeiiiiiooooooooooooooouuuuuuuuuuyyyyy' +
							   N'AADEOOUAAAAAAAAAAAAAAAEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOUUUUUUUUUUYYYYYDD'
 
    DECLARE @COUNTER INT
    DECLARE @COUNTER1 INT
    SET @COUNTER = 1
 
    WHILE (@COUNTER <= LEN(@strInput))
    BEGIN  
		SET @COUNTER1 = 1
		WHILE (@COUNTER1 <= LEN(@DIACRITIC_CHARS) + 1)
		BEGIN
			IF UNICODE(SUBSTRING(@DIACRITIC_CHARS, @COUNTER1, 1)) =
			   UNICODE(SUBSTRING(@strInput,@COUNTER ,1))
				BEGIN          
					IF @COUNTER = 1
						SET @strInput = SUBSTRING(@NON_DIACRITIC_CHARS, @COUNTER1, 1) +
										SUBSTRING(@strInput, @COUNTER + 1,LEN(@strInput) - 1)                  
					ELSE
						SET @strInput = SUBSTRING(@strInput, 1, @COUNTER - 1) +
										SUBSTRING(@NON_DIACRITIC_CHARS, @COUNTER1, 1) +
										SUBSTRING(@strInput, @COUNTER + 1, LEN(@strInput) - @COUNTER)
						BREAK
				END
			SET @COUNTER1 = @COUNTER1 + 1
		END
	SET @COUNTER = @COUNTER + 1
    END

    SET @strInput = REPLACE(@strInput, ' ', ' ')

    RETURN @strInput
END
GO
/****** Object:  Table [dbo].[Appointment]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[City]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Disease]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Disease](
	[Disease_ID] [int] IDENTITY(1,1) NOT NULL,
	[Disease_Name] [nvarchar](64) NULL,
 CONSTRAINT [PK_Disease] PRIMARY KEY CLUSTERED 
(
	[Disease_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[District]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Doctor]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Doctor_Hospital]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Doctor_Speciality]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Facility]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Facility](
	[Facility_ID] [int] IDENTITY(1,1) NOT NULL,
	[Facility_Name] [nvarchar](64) NULL,
	[Facility_Type] [int] NULL,
 CONSTRAINT [PK_Facility] PRIMARY KEY CLUSTERED 
(
	[Facility_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[FacilityType]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Feedback]    Script Date: 7/26/2014 7:58:28 PM ******/
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
 CONSTRAINT [PK_Feedback] PRIMARY KEY CLUSTERED 
(
	[Feedback_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FeedbackType]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Hospital]    Script Date: 7/26/2014 7:58:28 PM ******/
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
	[Short_Description] [nvarchar](128) NULL,
	[Full_Description] [nvarchar](4000) NULL,
	[Is_Allow_Appointment] [bit] NULL,
	[Rating] [float] NULL,
	[Created_Person] [int] NULL,
	[Is_Active] [bit] NULL,
 CONSTRAINT [PK_Hospital] PRIMARY KEY CLUSTERED 
(
	[Hospital_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Hospital_Facility]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Hospital_Service]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Hospital_Speciality]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[HospitalType]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Photo]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Photo](
	[Photo_ID] [int] IDENTITY(1,1) NOT NULL,
	[File_Path] [varchar](128) NULL,
	[Caption] [nvarchar](128) NULL,
	[Add_Date] [datetime] NULL,
	[Target_Type] [int] NULL,
	[Target_ID] [int] NULL,
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
/****** Object:  Table [dbo].[Rating]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Role]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Sentence_Word]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Sentence_Word](
	[Sentence_ID] [int] NOT NULL,
	[Word_ID] [int] NOT NULL,
	[Added_Date] [datetime] NULL,
 CONSTRAINT [PK_Sentence_Word] PRIMARY KEY CLUSTERED 
(
	[Sentence_ID] ASC,
	[Word_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[SentenceDictionary]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SentenceDictionary](
	[Sentence_ID] [int] IDENTITY(1,1) NOT NULL,
	[Sentence] [nvarchar](64) NULL,
	[Search_Date] [datetime] NULL,
 CONSTRAINT [PK_SentenceDictionary] PRIMARY KEY CLUSTERED 
(
	[Sentence_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Service]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Service](
	[Service_ID] [int] IDENTITY(1,1) NOT NULL,
	[Service_Name] [nvarchar](64) NULL,
	[Service_Type] [int] NULL,
 CONSTRAINT [PK_Service] PRIMARY KEY CLUSTERED 
(
	[Service_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ServiceType]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Speciality]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Speciality](
	[Speciality_ID] [int] IDENTITY(1,1) NOT NULL,
	[Speciality_Name] [nvarchar](32) NULL,
 CONSTRAINT [PK_Speciality] PRIMARY KEY CLUSTERED 
(
	[Speciality_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Speciality_Disease]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Speciality_Disease](
	[Speciality_ID] [int] NOT NULL,
	[Disease_ID] [int] NOT NULL,
 CONSTRAINT [PK_Speciality_Disease] PRIMARY KEY CLUSTERED 
(
	[Speciality_ID] ASC,
	[Disease_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[User]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Ward]    Script Date: 7/26/2014 7:58:28 PM ******/
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
/****** Object:  Table [dbo].[Word_Hospital]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Word_Hospital](
	[Word_ID] [int] NOT NULL,
	[Hospital_ID] [int] NOT NULL,
 CONSTRAINT [PK_Table_Word_Hospital] PRIMARY KEY CLUSTERED 
(
	[Hospital_ID] ASC,
	[Word_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[WordDictionary]    Script Date: 7/26/2014 7:58:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WordDictionary](
	[Word_ID] [int] IDENTITY(1,1) NOT NULL,
	[Word] [nvarchar](32) NULL,
	[Priority] [int] NULL,
 CONSTRAINT [PK_WordDictionary] PRIMARY KEY CLUSTERED 
(
	[Word_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

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
ALTER TABLE [dbo].[Photo]  WITH CHECK ADD  CONSTRAINT [FK_Photo_Doctor] FOREIGN KEY([Target_ID])
REFERENCES [dbo].[Doctor] ([Doctor_ID])
GO
ALTER TABLE [dbo].[Photo] CHECK CONSTRAINT [FK_Photo_Doctor]
GO
ALTER TABLE [dbo].[Photo]  WITH CHECK ADD  CONSTRAINT [FK_Photo_Hospital1] FOREIGN KEY([Target_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Photo] CHECK CONSTRAINT [FK_Photo_Hospital1]
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
ALTER TABLE [dbo].[Sentence_Word]  WITH CHECK ADD  CONSTRAINT [FK_Sentence_Word_SentenceDictionary] FOREIGN KEY([Sentence_ID])
REFERENCES [dbo].[SentenceDictionary] ([Sentence_ID])
GO
ALTER TABLE [dbo].[Sentence_Word] CHECK CONSTRAINT [FK_Sentence_Word_SentenceDictionary]
GO
ALTER TABLE [dbo].[Sentence_Word]  WITH CHECK ADD  CONSTRAINT [FK_Sentence_Word_WordDictionary] FOREIGN KEY([Word_ID])
REFERENCES [dbo].[WordDictionary] ([Word_ID])
GO
ALTER TABLE [dbo].[Sentence_Word] CHECK CONSTRAINT [FK_Sentence_Word_WordDictionary]
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
ALTER TABLE [dbo].[Word_Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Word_Hospital_Hospital] FOREIGN KEY([Hospital_ID])
REFERENCES [dbo].[Hospital] ([Hospital_ID])
GO
ALTER TABLE [dbo].[Word_Hospital] CHECK CONSTRAINT [FK_Word_Hospital_Hospital]
GO
ALTER TABLE [dbo].[Word_Hospital]  WITH CHECK ADD  CONSTRAINT [FK_Word_Hospital_WordDictionary] FOREIGN KEY([Word_ID])
REFERENCES [dbo].[WordDictionary] ([Word_ID])
GO
ALTER TABLE [dbo].[Word_Hospital] CHECK CONSTRAINT [FK_Word_Hospital_WordDictionary]
GO

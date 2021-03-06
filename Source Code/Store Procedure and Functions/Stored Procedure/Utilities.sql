.co-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO LOAD DISEASES IN A SPECIFIC SPECIALITY
-- SONNX
IF OBJECT_ID('[SP_LOAD_DISEASE_IN_SPECIALITY]', 'P') IS NOT NULL
	DROP PROCEDURE SP_LOAD_DISEASE_IN_SPECIALITY
GO
CREATE PROCEDURE [dbo].SP_LOAD_DISEASE_IN_SPECIALITY
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
CREATE PROCEDURE [dbo].[SP_LOAD_SPECIALITY_BY_HOSPITALID]
	@Hospital_ID INT
AS
BEGIN
	SELECT	s.Speciality_ID,s.Speciality_Name
	FROM	Hospital_Speciality AS hs, Speciality AS s
	WHERE	@Hospital_ID = hs.Hospital_ID AND
			hs.Speciality_ID = s.Speciality_ID AND
			hs.Is_Active = 'True'
END

EXEC SP_LOAD_SPECIALITY_BY_HOSPITALID 430

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO LOAD ALL DOCTOR OF SPECIALITY
-- ANHDTH
IF OBJECT_ID('[SP_LOAD_DOCTOR_BY_SPECIALITYID]') IS NOT NULL
	DROP PROCEDURE [SP_LOAD_DOCTOR_BY_SPECIALITYID]
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
CREATE PROCEDURE SP_TAKE_TOP_10_RATED_HOSPITAL
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO LOAD ALL DOCTOR OF HOSPITAL
-- ANHDTH


IF OBJECT_ID ('SP_LOAD_DOCTOR_IN_DOCTOR_HOSPITAL') IS NOT NULL
	DROP PROCEDURE [SP_LOAD_DOCTOR_IN_DOCTOR_HOSPITAL]
GO
CREATE PROCEDURE SP_LOAD_DOCTOR_IN_DOCTOR_HOSPITAL
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
CREATE PROCEDURE SP_LOAD_FACILITY_IN_HOSPITAL_FACILITY
	@hospitalID INT
AS
BEGIN
	SELECT	F.Facility_ID,F.Facility_Name,F.Facility_Type,FT.[Type_Name]
	FROM	Facility AS F,Hospital_Facility AS HF,FacilityType AS FT
	WHERE	F.Facility_ID = HF.Facility_ID AND
			F.Facility_Type=FT.[Type_ID] AND
			HF.Hospital_ID=@hospitalID AND
			HF.Is_Active='True'
END

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
--PROCEDURE TO LOAD ALL SERVICES OF HOSPITAL
--ANHDTH
IF OBJECT_ID('SP_LOAD_SERVICE_IN_HOSPITAL_SERVICE') IS NOT NULL
	DROP PROCEDURE [SP_LOAD_SERVICE_IN_HOSPITAL_SERVICE]
GO
CREATE PROCEDURE SP_LOAD_SERVICE_IN_HOSPITAL_SERVICE
	@hospitalID int
AS
BEGIN
	SELECT	S.Service_ID,S.Service_Name,S.Service_Type,ST.[Type_Name]
	FROM	Service AS S, Hospital_Service AS HS,ServiceType AS ST
	WHERE	S.Service_ID=HS.Service_ID AND
			S.Service_Type=ST.[Type_ID] AND
			HS.Hospital_ID=@hospitalID AND
			HS.Is_Active='True'
END

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
--PROCEDURE TO LOAD HOSPITAL TYPE
--ANHDTH
IF OBJECT_ID('SP_LOAD_TYPE_OF_HOSPITAL') IS NOT NULL
	DROP PROCEDURE [SP_LOAD_TYPE_OF_HOSPITAL]
GO
CREATE PROCEDURE SP_LOAD_TYPE_OF_HOSPITAL
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
CREATE PROCEDURE SP_SEARCH_DOCTOR
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
CREATE PROCEDURE SP_CHANGE_HOSPITAL_STATUS
	@HospitalID INT
AS
BEGIN
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO CHECK IF AN USER HAVE BEEN EXISTED IN DATABSE
-- SONNX
IF OBJECT_ID('[SP_CHECK_VALID_USER_IN_CHARGED]', 'P') IS NOT NULL
	DROP PROCEDURE SP_CHECK_VALID_USER_IN_CHARGED
GO
CREATE PROCEDURE SP_CHECK_VALID_USER_IN_CHARGED
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
--PROCEDURE TO GET ALL SPECIALITY OF DOCTOR
--ANHDTH

IF OBJECT_ID('SP_LOAD_SPECIALITY_IN_DOCTOR_SPECIALITY') IS NOT NULL
	DROP PROCEDURE [SP_LOAD_SPECIALITY_IN_DOCTOR_SPECIALITY]
GO
CREATE PROCEDURE SP_LOAD_SPECIALITY_IN_DOCTOR_SPECIALITY
	@doctorID int
AS
BEGIN
	SELECT	S.Speciality_ID,S.Speciality_Name
	FROM	Speciality AS S,Doctor_Speciality AS DS
	WHERE	S.Speciality_ID=DS.Speciality_ID AND
			DS.Doctor_ID=@doctorID AND DS.Is_Active=1
END

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT LOAD ALL SERVICES AND ITS TYPES
-- SONNX
IF OBJECT_ID('[SP_TAKE_SERVICE_AND_TYPE]', 'P') IS NOT NULL
	DROP PROCEDURE SP_TAKE_SERVICE_AND_TYPE
GO
CREATE PROCEDURE SP_TAKE_SERVICE_AND_TYPE
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT LOAD ALL FACILITIES AND ITS TYPES
-- SONNX
IF OBJECT_ID('[SP_TAKE_FACILITY_AND_TYPE]', 'P') IS NOT NULL
	DROP PROCEDURE SP_TAKE_FACILITY_AND_TYPE
GO
CREATE PROCEDURE SP_TAKE_FACILITY_AND_TYPE
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO CHECK IF THERE IS A SIMILAR HOSPITAL WITH NAME AND ADDRESS
-- ARE EQUAL WITH GIVEN DATA FROM USER
-- SONNX
IF OBJECT_ID('[SP_CHECK_NOT_DUPLICATED_HOSPITAL]', 'P') IS NOT NULL
	DROP PROCEDURE SP_CHECK_NOT_DUPLICATED_HOSPITAL
GO
CREATE PROCEDURE SP_CHECK_NOT_DUPLICATED_HOSPITAL
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO INSERT NEW HOSPITAL USER
-- SONNX
IF OBJECT_ID('[SP_INSERT_HOSPITAL_USER]', 'P') IS NOT NULL
	DROP PROCEDURE SP_INSERT_HOSPITAL_USER
GO
CREATE PROCEDURE SP_INSERT_HOSPITAL_USER
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO CHANGE STATUS OF A SPECIFIC SERVICE
-- SONNX
IF OBJECT_ID('SP_CHANGE_SERVICE_STATUS', 'P') IS NOT NULL
	DROP PROCEDURE [SP_CHANGE_SERVICE_STATUS]
GO
CREATE PROCEDURE SP_CHANGE_SERVICE_STATUS
	@ServiceID INT
AS
BEGIN
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT LOAD ALL SPECIALITIES AND ITS STATUS
-- SONNX
IF OBJECT_ID('[SP_TAKE_SPECIALITY_AND_TYPE]', 'P') IS NOT NULL
	DROP PROCEDURE SP_TAKE_SPECIALITY_AND_TYPE
GO
CREATE PROCEDURE SP_TAKE_SPECIALITY_AND_TYPE
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT LOAD ALL DISEASE AND ITS STATUS
-- SONNX
IF OBJECT_ID('[SP_TAKE_DISEASE_AND_TYPE]', 'P') IS NOT NULL
	DROP PROCEDURE SP_TAKE_DISEASE_AND_TYPE
GO
CREATE PROCEDURE SP_TAKE_DISEASE_AND_TYPE
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO CHANGE STATUS OF A SPECIFIC DISEASE
-- SONNX
IF OBJECT_ID('SP_CHANGE_DISEASE_STATUS', 'P') IS NOT NULL
	DROP PROCEDURE [SP_CHANGE_DISEASE_STATUS]
GO
CREATE PROCEDURE SP_CHANGE_DISEASE_STATUS
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO INSERT NEW DISEASE
-- SONNX
IF OBJECT_ID('SP_INSERT_DISEASE', 'P') IS NOT NULL
	DROP PROCEDURE [SP_INSERT_DISEASE]
GO
CREATE PROCEDURE SP_INSERT_DISEASE
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO UPDATE DISEASE
-- SONNX
IF OBJECT_ID('SP_UPDATE_DISEASE', 'P') IS NOT NULL
	DROP PROCEDURE SP_UPDATE_DISEASE
GO
CREATE PROCEDURE SP_UPDATE_DISEASE
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO CHANGE STATUS OF A SPECIFIC FACILITY
-- SONNX
IF OBJECT_ID('SP_CHANGE_FACILITY_STATUS', 'P') IS NOT NULL
	DROP PROCEDURE [SP_CHANGE_FACILITY_STATUS]
GO
CREATE PROCEDURE SP_CHANGE_FACILITY_STATUS
	@FacilityID INT
AS
BEGIN
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO CHANGE STATUS OF A SPECIFIC SPECIALITY
-- SONNX
IF OBJECT_ID('SP_CHANGE_SPECIALITY_STATUS', 'P') IS NOT NULL
	DROP PROCEDURE [SP_CHANGE_SPECIALITY_STATUS]
GO
CREATE PROCEDURE SP_CHANGE_SPECIALITY_STATUS
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO INSERT NEW SERVICE
-- SONNX
IF OBJECT_ID('SP_INSERT_SERVICE', 'P') IS NOT NULL
	DROP PROCEDURE [SP_INSERT_SERVICE]
GO
CREATE PROCEDURE SP_INSERT_SERVICE
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO INSERT NEW FACILITY
-- SONNX
IF OBJECT_ID('SP_INSERT_FACILITY', 'P') IS NOT NULL
	DROP PROCEDURE [SP_INSERT_FACILITY]
GO
CREATE PROCEDURE [SP_INSERT_FACILITY]
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO INSERT NEW SPECIALITY
-- SONNX
IF OBJECT_ID('SP_INSERT_SPECIALITY', 'P') IS NOT NULL
	DROP PROCEDURE [SP_INSERT_SPECIALITY]
GO
CREATE PROCEDURE SP_INSERT_SPECIALITY
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO UPDATE SERVICE
-- SONNX
IF OBJECT_ID('SP_UPDATE_SERVICE', 'P') IS NOT NULL
	DROP PROCEDURE SP_UPDATE_SERVICE
GO
CREATE PROCEDURE SP_UPDATE_SERVICE
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO UPDATE FACILITY
-- SONNX
IF OBJECT_ID('SP_UPDATE_FACILITY', 'P') IS NOT NULL
	DROP PROCEDURE SP_UPDATE_FACILITY
GO
CREATE PROCEDURE SP_UPDATE_FACILITY
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

-----------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
-- SCRIPT TO UPDATE SPECIALITY
-- SONNX
IF OBJECT_ID('SP_UPDATE_SPECIALITY', 'P') IS NOT NULL
	DROP PROCEDURE [SP_UPDATE_SPECIALITY]
GO
CREATE PROCEDURE SP_UPDATE_SPECIALITY
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
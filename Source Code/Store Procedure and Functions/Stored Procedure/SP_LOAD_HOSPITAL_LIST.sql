-- SCRIPT TO LOAD HOSPITAL LIST
-- SONNX
IF OBJECT_ID('[SP_LOAD_HOSPITAL_LIST]', 'P') IS NOT NULL
	DROP PROCEDURE SP_LOAD_HOSPITAL_LIST
GO
CREATE PROCEDURE SP_LOAD_HOSPITAL_LIST
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
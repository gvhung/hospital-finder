USE [HospitalF]
GO
/****** Object:  UserDefinedFunction [dbo].[FU_AUTO_GENERATE_ENTITIES_CLASS]    Script Date: 6/18/2014 2:50:14 PM ******/
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
		REPLACE(@TableName, '_', '') + CHAR(13) + '	{' + CHAR(13)

	SET @result = @result + '		#region ' + @TableName + ' Properties' + CHAR(13) 

	SELECT @result = @result + CHAR(13) +
		   '		/// <summary>' + CHAR(13) +
		   '		/// Property for ' + orgColName + ' attribute' + CHAR(13) +
		   '		/// <summary>' + CHAR(13) +
		   '		public ' +
		   ColumnType + ' ' + ColumnName + ';' + CHAR(13)
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
/****** Object:  UserDefinedFunction [dbo].[FU_TRANSFORM_TO_NON_DIACRITIC_VIETNAMESE]    Script Date: 6/18/2014 2:50:14 PM ******/
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
 
    SET @DIACRITIC_CHARS = N'ăâđêôơưàảãạáằẳẵặắầẩẫậấèẻẽẹéềểễệế
						   ìỉĩịíòỏõọóồổỗộốờởỡợớùủũụúừửữựứỳỷỹỵý
						   ĂÂĐÊÔƠƯÀẢÃẠÁẰẲẴẶẮẦẨẪẬẤÈẺẼẸÉỀỂỄỆẾÌỈĨỊÍ
						   ÒỎÕỌÓỒỔỖỘỐỜỞỠỢỚÙỦŨỤÚỪỬỮỰỨỲỶỸỴÝ' +
						   NCHAR(272) + NCHAR(208)

    SET @NON_DIACRITIC_CHARS = N'aadeoouaaaaaaaaaaaaaaaeeeeeeeeee
							   iiiiiooooooooooooooouuuuuuuuuuyyyyy
							   AADEOOUAAAAAAAAAAAAAAAEEEEEEEEEEIIIII
							   OOOOOOOOOOOOOOOUUUUUUUUUUYYYYYDD'
 
    DECLARE @COUNTER INT
    DECLARE @COUNTER1 INT
    SET @COUNTER = 1
 
    WHILE (@COUNTER <= LEN(@strInput))
    BEGIN  
		SET @COUNTER1 = 1
		WHILE (@COUNTER1 <= LEN(@DIACRITIC_CHARS)+1)
		BEGIN
			IF UNICODE(SUBSTRING(@DIACRITIC_CHARS, @COUNTER1, 1)) =
			   UNICODE(SUBSTRING(@strInput,@COUNTER ,1))
				BEGIN          
					IF @COUNTER = 1
						SET @strInput = SUBSTRING(@NON_DIACRITIC_CHARS, @COUNTER1, 1) +
										SUBSTRING(@strInput, @COUNTER + 1,LEN(@strInput) - 1)                  
					ELSE
						SET @strInput = SUBSTRING(@strInput, 1, @COUNTER - 1) +
										SUBSTRING(@NON_DIACRITIC_CHARS, @COUNTER1,1) +
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
/****** Object:  Table [dbo].[Appointment]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[City]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Disease]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[District]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Doctor]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Doctor_Hospital]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Doctor_Speciality]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Facility]    Script Date: 6/18/2014 2:50:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Facility](
	[Facility_ID] [int] IDENTITY(1,1) NOT NULL,
	[Facility_Name] [nvarchar](64) NULL,
 CONSTRAINT [PK_Facility] PRIMARY KEY CLUSTERED 
(
	[Facility_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Feedback]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[FeedbackType]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Hospital]    Script Date: 6/18/2014 2:50:14 PM ******/
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
	[Phone_Number] [varchar](32) NULL,
	[Fax] [varchar](16) NULL,
	[Email] [varchar](64) NULL,
	[Website] [varchar](64) NULL,
	[Start_Time] [time](7) NULL,
	[End_Time] [time](7) NULL,
	[Coordinate] [varchar](26) NULL,
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
/****** Object:  Table [dbo].[Hospital_Facility]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Hospital_Service]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Hospital_Speciality]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[HospitalType]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Photo]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Rating]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Role]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Sentence_Word]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[SentenceDictionary]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Service]    Script Date: 6/18/2014 2:50:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Service](
	[Service_ID] [int] IDENTITY(1,1) NOT NULL,
	[Service_Name] [nvarchar](64) NULL,
 CONSTRAINT [PK_Service] PRIMARY KEY CLUSTERED 
(
	[Service_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Speciality]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Speciality_Disease]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[User]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Ward]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[Word_Hospital]    Script Date: 6/18/2014 2:50:14 PM ******/
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
/****** Object:  Table [dbo].[WordDictionary]    Script Date: 6/18/2014 2:50:14 PM ******/
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

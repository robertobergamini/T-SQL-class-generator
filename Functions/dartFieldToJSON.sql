
/****** Object:  UserDefinedFunction [dbo].[dartToJSON]    Script Date: 03/11/2022 11:13:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author		: Broc
-- Create date	: 30/10/2022
-- Description	: gets single item for converting class to json in Dart
-- =============================================
create function [dbo].[dartFieldToJSON]
(
	@sqlType varchar(50),
	@columnName varchar(50),
	@isNullable bit
)
returns varchar(50)
AS
BEGIN

	declare @rettype varchar(50)

	set @rettype = 'this.' + @columnName 
            
	return(@rettype)

END

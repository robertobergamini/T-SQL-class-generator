
/****** Object:  UserDefinedFunction [dbo].[dartFieldDefaultValue]    Script Date: 03/11/2022 11:12:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author		: Broc
-- Create date	: 30/10/2022
-- Description	: Gets default value for fields in dart language
-- =============================================
ALTER function [dbo].[dartFieldDefaultValue]
(
	@sqlType varchar(50),
	@isNullable bit
)
returns varchar(50)
AS
BEGIN
/*
select dbo.dartFieldDefaultValue('String', 0)
*/
	declare @defaultvalueset varchar(50)



	set @defaultvalueset = ''

	if @isNullable = 0
		begin

			set @defaultvalueset = case @sqlType 
				when 'int'		then '0'
				
				when 'bool'		then '0'
				when 'String'	then ''''''
				when 'Date'		then 'DateTime.fromMicrosecondsSinceEpoch(0)'
				
				when 'Decimal'	then '0'
				when 'float'	then '0'
				when 'double'	then '0'

				
				else '' end
		
		end

	if @defaultvalueset <> ''
		set @defaultvalueset = ' = ' + @defaultvalueset 

	return(@defaultvalueset)

END

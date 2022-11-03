
/****** Object:  UserDefinedFunction [dbo].[toDartDataType]    Script Date: 03/11/2022 09:19:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author	: Broc
-- Create date	: 30/10/2022
-- Description	: Convert sql data type to C# data type
-- =============================================
ALTER FUNCTION [dbo].[toDartDataType]
(
	@sqlType varchar(50),
	@isNullable bit
)
returns varchar(50)
AS
BEGIN

	declare @rettype varchar(50)

	set @rettype = case @sqlType 
            when 'bigint'			then 'int'
            when 'binary'			then 'Uint8List'
            when 'bit'				then 'bool'
            when 'char'				then 'String'
            when 'date'				then 'DateTime'
            when 'datetime'			then 'DateTime'
            when 'datetime2'			then 'DateTime'
            when 'datetimeoffset'		then 'DateTimeOffset'
            when 'decimal'			then 'Decimal'
            when 'float'			then 'double'
            when 'image'			then 'Uint8List'
            when 'int'				then 'int'
            when 'money'			then 'Decimal'
            when 'nchar'			then 'String'
            when 'ntext'			then 'String'
            when 'numeric'			then 'Decimal'
            when 'nvarchar'			then 'String'
            when 'real'				then 'double'
            when 'smalldatetime'		then 'DateTime'
            when 'smallint'			then 'int'
            when 'smallmoney'			then 'decimal'
            when 'text'				then 'String'
            when 'time'				then 'TimeSpan'
            when 'timestamp'			then 'int'
            when 'tinyint'			then 'int'
            when 'uniqueidentifier' 		then 'Uint8List'
            when 'varbinary'			then 'Uint8List'
            when 'varchar'			then 'String'
            else 				'UNKNOWN_' + @sqlType end

	if @isNullable = 1 
		set @rettype = @rettype + '?'

	return(@rettype)

END

GO



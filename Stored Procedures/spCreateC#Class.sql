USE [ITALPIZZA_EXT]
GO
/****** Object:  StoredProcedure [dbo].[spCreateClassC#]    Script Date: 03/11/2022 11:20:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Broc
-- Create date: 03/11/2022
-- Description:	Create C# Poco from database table
-- =============================================
ALTER PROCEDURE [dbo].[spCreateClassC#]
	@TableName varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	/*

	exec spCreateClassC# 'MenuSettings'
	
	*/

	declare @tab char, @eol char(2)
	declare @txt varchar(max)

	set @tab = char(9)
	set @eol = char(13) + char(10)
	set @txt = 'public partial class ' + @TableName + @eol + '{' + @eol

	select @txt = @txt + @tab + ' public ' + col.ColumnType +  ' ' + ColumnName + ' { get; set; } ' + @eol
	from
	(
		select 
			replace(col.name, ' ', '_') ColumnName,
			column_id ColumnId,
			dbo.toC#DataType(typ.name, typ.is_nullable) As ColumnType
		from sys.columns col
			join sys.types typ on
				col.system_type_id = typ.system_type_id AND col.user_type_id = typ.user_type_id
		where 
			object_id = object_id(@TableName)
	) col

	set @txt = @txt + '}' + @eol

	print @txt
END


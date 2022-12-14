
/****** Object:  StoredProcedure [dbo].[spCreateClassDart]    Script Date: 03/11/2022 11:30:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Broc
-- Create date: long time ago... 
-- Description:	create Dart class for a database table
-- =============================================
create procedure [dbo].[spCreateDartClass]
	@DatabaseName varchar(50),
	@TableName varchar(50)
as
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	/*

	exec spCreateClassDart 'ITALPIZZA_EXT', 'MenuSettings'


	*/

	declare @tab char, @eol char(2)
	declare @txt varchar(max)
	declare @sql varchar(max)

	declare @tbl table (
		Id int identity(1,1),
		ColumnName varchar(50),
		ColumnId int,
		IsNullable bit,
		ColumnType varchar(50),
		SqlColumnType varchar(50)
	)

	if @DatabaseName is not null
		begin

			set @sql = '
			select 
				replace(col.name, '' '', ''_'') ColumnName,
				column_id ColumnId,
				col.is_nullable,
				dbo.toDartDataType(typ.name, col.is_nullable) As ColumnType,
				typ.name As SqlColumnType
			from 
				' + @DatabaseName + '.sys.tables tab
				INNER JOIN ' + @DatabaseName + '.sys.columns col ON 
					col.object_id = tab.object_id
				join ' + @DatabaseName + '.sys.types typ on
					col.system_type_id = typ.system_type_id and
					col.user_type_id = typ.user_type_id
			where 
				tab.name = ''' + @TableName + ''' '


		end
	else
		begin

			set @sql = '
			select 
				replace(col.name, '' '', ''_'') ColumnName,
				column_id ColumnId,
				col.is_nullable,
				dbo.toDartDataType(typ.name, col.is_nullable) As ColumnType,
				typ.name As SqlColumnType
			from 
				sys.tables tab
				INNER JOIN ' + @DatabaseName + '.sys.columns col ON 
					col.object_id = tab.object_id
				join ' + @DatabaseName + '.sys.types typ on
					col.system_type_id = typ.system_type_id and
					col.user_type_id = typ.user_type_id
			where 
				tab.name = ''' + @TableName + ''' '

		end


	insert into @tbl 
	(
		ColumnName,
		ColumnId,
		IsNullable,
		ColumnType,
		SqlColumnType
	)
	exec (@sql)


	set @tab = char(9)
	set @eol = char(13) + char(10)

	set @txt = 'import ''dart:core'';' + @eol + @eol
	set @txt = @txt + 'class ' + @TableName + @eol + '{' + @eol

	select @txt = @txt + @tab + col.ColumnType +  ' ' + ColumnName + dbo.dartFieldDefaultValue(col.ColumnType, col.IsNullable) + ';' + @eol
	from
	(
		select 
			ColumnName,
			ColumnId,
			IsNullable,
			ColumnType 
		from @tbl
			
	) col
	set @txt = @txt + @eol

	-- Constuctor
	set @txt = @txt + @tab + @TableName + '({' + @eol
	select @txt = @txt + @tab + @tab + 'this.' + ColumnName + dbo.dartFieldDefaultValue(col.ColumnType, col.IsNullable) + ',' + @eol
	from
	(
		select 
			ColumnName,
			ColumnId,
			IsNullable,
			ColumnType 
		from @tbl
	) col

	set @txt = substring(@txt,0,len(@txt)-len(@eol)) + @tab + '});' + @eol
	set @txt = @txt + @eol

	-- to JSON
	set @txt = @txt + @tab +  'Map toJson() => {' + @eol
	select @txt = @txt + @tab + @tab + '''' + ColumnName +  ''' : ' + dbo.dartFieldToJSON(col.ColumnType, col.ColumnName, col.IsNullable) + ',' + @eol
	from
	(
		select 
			ColumnName,
			ColumnId,
			IsNullable,
			ColumnType 
		from @tbl
	) col

	set @txt = @txt + @tab + '};' + @eol
	set @txt = @txt + @eol

	-- from JSON
	set @txt = @txt + @tab +  'factory ' + @TableName + '.fromJson(Map json) {' + @eol
	set @txt = @txt + @tab +  @tab + @TableName + ' itm = ' + @TableName + '();' + @eol
	set @txt = @txt + @eol
	select @txt = @txt + @tab + @tab + 'itm.' + col.ColumnName +  ' = json[''' + col.ColumnName + '''] as ' + col.ColumnType + ';' + @eol
	from
	(
		select 
			ColumnName,
			ColumnId,
			IsNullable,
			ColumnType 
		from @tbl
	) col

	set @txt = @txt + @tab + @tab +'return itm;' + @eol
	set @txt = @txt + @tab + '}' + @eol
	set @txt = @txt + @eol


	set @txt = @txt + '}' + @eol

	print @txt
END



/****** Object:  StoredProcedure [dbo].[spCreateClassDart]    Script Date: 02/11/2022 20:08:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author		: Broc
-- Create date	: long time ago... 
-- Description	:	create Dart class for a database table
-- =============================================
alter procedure [dbo].[spCreateDartRepository]
	@DatabaseName varchar(50),
	@TableName varchar(50)
as
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	/*

	exec spCreateDartRepository '<DatabaseName>', '<TableName>'
	
	
	*/

	declare @tab char, @eol char(2)
	declare @txt varchar(max)
	declare @temp varchar(max)
	declare @sql varchar(max)
	declare @index int

	
	declare @tblindexes table (
		id int identity(1,1),
		object_id bigint,
		index_name varchar(100),
		column_index int,
		column_name varchar(100),
		table_name varchar(100)
	)



	set @sql = ' select
		i.object_id,
		i.name As index_name,
		ic.index_column_id AS column_index,
		c.name As column_name,
		t.name As table_name
		-- , *
	 from
		 ' + @DatabaseName + '.sys.indexes i 
		 inner join ' + @DatabaseName + '.sys.index_columns ic on 
			ic.object_id = i.object_id
		 inner join ' + @DatabaseName + '.sys.columns c on 
			c.object_id = ic.object_id
			and c.column_id = ic.column_id
		 inner join ' + @DatabaseName + '.sys.tables t on 
			t.object_id = i .object_id

		inner join ' + @DatabaseName + '.sys.objects o on 
			o.object_id = t.object_id 

	 where
		i.is_primary_key = 1 and t.name = ''' + @TableName + ''' '
		-- and c.name = @FieldName
		print @sql

	insert into @tblindexes 
	(
		object_id,
		index_name,
		column_index,
		column_name ,
		table_name 
	)
	exec (@sql)

	select * from @tblindexes

	declare @tblfields table (
		Id int identity(1,1),
		column_name varchar(50),
		column_id int,
		is_nullable bit,
		is_key bit,
		column_type varchar(50),
		sql_column_type varchar(50)
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

	-- print @sql

	insert into @tblfields
	(
		column_name,
		column_id,
		is_nullable,
		is_key,
		column_type,
		sql_column_type
	)
	exec (@sql)

	-- select * from @tbl

	set @tab = char(9)
	set @eol = char(13) + char(10)

	set @txt = 'import ''dart:core'';' + @eol + @eol

	-- Abstract repository
	set @txt = @txt + 'abstract class ' + @TableName + 'Repository {' + @eol
	set @txt = @txt + @tab + 'Future<List<' + @TableName + '>> list' + @TableName + 'ForFilters({required ' + @TableName + 'Filter filters});'+ @eol
    
	set @txt = @txt + @tab + 'Future<List<' + @TableName + '>> ins' + @TableName + '({required ' + @TableName + ' itm});' + @eol
	set @txt = @txt + @tab + 'Future<List<' + @TableName + '>> upd' + @TableName + '({required ' + @TableName + ' itm});' + @eol
	set @txt = @txt + @tab + 'Future<List<' + @TableName + '>> insupd' + @TableName + '({required ' + @TableName + ' itm});' + @eol
	set @txt = @txt + @tab + 'Future<bool> del' + @TableName + '({required ' + @TableName + ' itm});' + @eol
	set @txt = @txt + '}' + @eol

	-- Http repository
	set @txt = 'class Http' + @TableName + 'Repository implements ' + @TableName + 'Repository {'+ @eol

    set @txt = @txt + @tab + 'late APIParameters apiParameters; ' + @eol
    set @txt = @txt + @tab + 'HttpMenuSettingRepository(this.apiParameters) {}' + @eol

	-- list
    set @txt = @txt + @tab + '@override' + @eol
    set @txt = @txt + @tab + 'Future<List<' + @TableName + '>> list' + @TableName + 'ForFilters({required ' + @TableName + 'Filter filters}) async { ' + @eol

    set @txt = @txt + @tab + 'List<' + @TableName + '> list = <' + @TableName + '> [];' + @eol
    set @txt = @txt + @tab + 'var params = filters.toJson();' + @eol
    set @txt = @txt + @tab + 'Uri url = Uri.parse(apiParameters.baseUrl + ''<insert url here>''' + @eol
    set @txt = @txt + @tab + 'var response = await http.post(url, ' + @eol
    set @txt = @txt + @tab + @tab + 'headers : <String, String>{''Content-Type'': ''application/json; charset=UTF-8''},'+ @eol
    set @txt = @txt + @tab + @tab + 'body: jsonEncode(params) );' + @eol
	set @txt = @txt + @tab + 'if (response.statusCode == 200) {' + @eol
	set @txt = @txt + @tab + @tab + 'var list1 = jsonDecode(response.body) as List<dynamic>;' + @eol
	set @txt = @txt + @tab + @tab + 'List<MenuSetting> list = list1.map((value) => MenuSetting.fromJson(value)).toList();' + @eol
	set @txt = @txt + @tab + @tab + 'return list;' + @eol
    set @txt = @txt + @tab + '} else {' + @eol
    set @txt = @txt + @tab + @tab + 'return list;' + @eol
    set @txt = @txt + @tab + '}' + @eol
	set @txt = @txt + '}' + @eol

    

    set @txt = @txt + @tab + 'Future<' + @TableName + '?> get' + @TableName + '({' 
	
	select @temp = ',required ' + dbo.tocamelCase(t.column_name) + ' ' from @tblfields t where is_key = 1
	set @temp = right(@temp, len(@temp)-1)
	print @temp

	set @txt = @txt + @temp + ') async {' + @eol
    set @txt = @txt + @tab + 'Uri url = Uri.https(apiParameters.baseUrl , ''/' + @TableName + '/Get' + @TableName + '?'');' + @eol

		
	select @temp = ',&' + t.column_name + '=' + dbo.tocamelCase(t.column_name) from @tblfields t where is_key = 1
	set @temp = right(@temp, len(@temp)-1)
	set @txt = @txt + @temp + @eol

	print @temp

    set @txt = @txt + @tab + 'var response = await http.get(url, headers : <String, String>{' + @eol
    set @txt = @txt + @tab + @tab + '''Content-Type'': ''application/json; charset=UTF-8'' }); ' + @eol

	set @txt = @txt + @tab + @tab + 'if (response.statusCode == 200) {' + @eol
    set @txt = @txt + @tab + @tab + @tab + 'return ' + @TableName + '.fromJson(json.decode(response.body));' + @eol
    set @txt = @txt + @tab + @tab + '} else {' + @eol
    set @txt = @txt + @tab + @tab + @tab + 'throw Exception(''Error while getting data from server.'');' + @eol
    set @txt = @txt + @tab + @tab + '}' + @eol
	set @txt = @txt + @tab + '}' + @eol
    
	-- insert
    set @txt = @txt + @tab + 'Future<' + @TableName + '> ins' + @TableName + '({required ' + @TableName + ' itm}) async {' + @eol
	set @txt = @txt + @tab + @tab + 'Uri url = Uri.https( apiParameters.baseUrl , ''/' + + @TableName + '/Ins'');' + @eol
    set @txt = @txt + @tab + @tab + @tab + 'var response = await http.put(url,' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + 'headers : <String, String>{' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + @tab + '''Content-Type'': ''application/json; charset=UTF-8'',' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + '},' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + 'body: convert.jsonEncode(itm)' + @eol
	set @txt = @txt + @tab + @tab + @tab + ');' + @eol

    set @txt = @txt + @tab + @tab + @tab + 'if (response.statusCode == 200) {' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + 'return MenuSetting.fromJson(json.decode(response.body));' + @eol
    set @txt = @txt + @tab + @tab + @tab + '} else {' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + '} throw Exception(''Error while inserting in table ' + @TableName + '''.);' + @eol
    set @txt = @txt + @tab + @tab + @tab + '}' + @eol
	set @txt = @txt + @tab + '}' + @eol

	-- update
	set @txt = @txt + @tab + 'Future<' + @TableName + '> upd' + @TableName + '({required ' + @TableName + ' itm}) async {' + @eol
	set @txt = @txt + @tab + @tab + 'Uri url = Uri.https( apiParameters.baseUrl , ''/' + + @TableName + '/Ins'');' + @eol
    set @txt = @txt + @tab + @tab + @tab + 'var response = await http.put(url,' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + 'headers : <String, String>{' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + @tab + '''Content-Type'': ''application/json; charset=UTF-8'',' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + '},' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + 'body: convert.jsonEncode(itm)' + @eol
	set @txt = @txt + @tab + @tab + @tab + ');' + @eol

    set @txt = @txt + @tab + @tab + @tab + 'if (response.statusCode == 200) {' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + 'return MenuSetting.fromJson(json.decode(response.body));' + @eol
    set @txt = @txt + @tab + @tab + @tab + '} else {' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + '} throw Exception(''Error while inserting in table ' + @TableName + '''.);' + @eol
    set @txt = @txt + @tab + @tab + @tab + '}' + @eol
	set @txt = @txt + @tab + '}' + @eol

	-- delete
	set @txt = @txt + @tab + 'Future<bool> upd' + @TableName + '({required ' + @TableName + ' itm}) async {' + @eol
	set @txt = @txt + @tab + @tab + 'Uri url = Uri.https( apiParameters.baseUrl , ''/' + + @TableName + '/Ins'');' + @eol
    set @txt = @txt + @tab + @tab + @tab + 'var response = await http.put(url,' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + 'headers : <String, String>{' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + @tab + '''Content-Type'': ''application/json; charset=UTF-8'',' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + '},' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + 'body: convert.jsonEncode(itm)' + @eol
	set @txt = @txt + @tab + @tab + @tab + ');' + @eol

    set @txt = @txt + @tab + @tab + @tab + 'if (response.statusCode == 200) {' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + 'return MenuSetting.fromJson(json.decode(response.body));' + @eol
    set @txt = @txt + @tab + @tab + @tab + '} else {' + @eol
    set @txt = @txt + @tab + @tab + @tab + @tab + '} throw Exception(''Error while inserting in table ' + @TableName + '''.);' + @eol
    set @txt = @txt + @tab + @tab + @tab + '}' + @eol
	set @txt = @txt + @tab + '}' + @eol

	set @txt = @txt + '}' + @eol



	print @txt
END


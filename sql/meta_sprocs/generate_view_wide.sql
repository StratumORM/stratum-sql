print '
Generating template dynamic view (wide)...'


IF OBJECT_ID('[orm_meta].[generate_template_view_wide]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[generate_template_view_wide]
go


create procedure [orm_meta].[generate_template_view_wide]
	@template_guid uniqueidentifier
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	declare @string_columns nvarchar(max)
		,	@integer_columns nvarchar(max)
		,	@decimal_columns nvarchar(max)
		,	@datetime_columns nvarchar(max)
		,	@instance_columns nvarchar(max)

		,	@pivot_query_template nvarchar(max)
		,	@resolved_pivot_template nvarchar(max)
		,	@pivot_sub_query nvarchar(max)
		,	@query nvarchar(max)

		,	@template_name nvarchar(250)

	set @template_name = (select name from [orm_meta].[templates] where template_guid = @template_guid)

	set @string_columns =	(	select QUOTENAME(name) + ',' 
								from [orm_meta].[properties] as p
								where	p.datatype_guid = 0x00000000000000000000000000000001
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_guid = @template_guid 
								for xml path(''))

	set @integer_columns =	(	select QUOTENAME(name) + ','
								from [orm_meta].[properties] as p
								where	p.datatype_guid = 0x00000000000000000000000000000002
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_guid = @template_guid 
								for xml path(''))

	set @decimal_columns =	(	select QUOTENAME(name) + ','
								from [orm_meta].[properties] as p
								where	p.datatype_guid = 0x00000000000000000000000000000003 
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_guid = @template_guid 
								for xml path(''))

	set @datetime_columns =	(	select QUOTENAME(name) + ','
								from [orm_meta].[properties] as p
								where	p.datatype_guid = 0x00000000000000000000000000000004
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_guid = @template_guid 
								for xml path(''))

	set @instance_columns =	(	select QUOTENAME(name) + ','
								from [orm_meta].[properties] as p
								where   p.datatype_guid > 0x00000000000000000000000000000004
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_guid = @template_guid 
								for xml path(''))


	IF OBJECT_ID('[dbo].' + QUOTENAME(@template_name), 'V') IS NOT NULL
		set @query = 'alter'
	else
		set @query = 'create'

	set @query = @query + ' view ' + QUOTENAME(@template_name) + '
	as
	select	o.name as Instance_name '

	set @pivot_query_template = '
		left join
			( 	select	o.instance_guid
					,	p.name as Property
					,	v.value
				from	[orm_meta].[instances] as o 
					inner join [orm_meta].[properties] as p
						on o.template_guid = p.template_guid
					inner join @@@META_VALUES_TABLE@@@ as v
						on 	p.property_guid = v.property_guid
						and	v.instance_guid = o.instance_guid
				where (p.is_extended is NULL or p.is_extended = 0)
					and p.datatype_guid = @@@DATATYPE_GUID@@@
			) as src
			pivot
			(
				max (value)
				for Property in (@@@VALUES_COLUMNS@@@)
			) as @@@META_VALUES_TABLE_SANITIZED@@@_pivot
			on o.instance_guid = @@@META_VALUES_TABLE_SANITIZED@@@_pivot.instance_guid
		'
	set @pivot_sub_query = ''

	if isnull(@string_columns, '') <> ''
	begin
		set @string_columns = left(@string_columns, len(@string_columns)-1)

		set @query = @query + '
		,	' + @string_columns

		set @resolved_pivot_template = replace(@pivot_query_template, '@@@META_VALUES_TABLE@@@', '[orm_meta].[values_string]')
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@META_VALUES_TABLE_SANITIZED@@@', '_orm_meta___values_string_')
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@VALUES_COLUMNS@@@', @string_columns)
		set @resolved_pivot_template = replace(@resolved_pivot_template, 'p.datatype_guid = @@@DATATYPE_GUID@@@', 'p.datatype_guid = 0x00000000000000000000000000000001')

		set @pivot_sub_query = @pivot_sub_query + @resolved_pivot_template
	end


	if isnull(@integer_columns, '') <> ''
	begin
		set @integer_columns = left(@integer_columns, len(@integer_columns)-1)

		set @query = @query + '
		,	' + @integer_columns

		set @resolved_pivot_template = replace(@pivot_query_template, '@@@META_VALUES_TABLE@@@', '[orm_meta].[values_integer]')
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@META_VALUES_TABLE_SANITIZED@@@', '_orm_meta___values_integer_')
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@VALUES_COLUMNS@@@', @integer_columns)
		set @resolved_pivot_template = replace(@resolved_pivot_template, 'p.datatype_guid = @@@DATATYPE_GUID@@@', 'p.datatype_guid = 0x00000000000000000000000000000002')

		set @pivot_sub_query = @pivot_sub_query + @resolved_pivot_template
	end


	if isnull(@decimal_columns, '') <> ''
	begin
		set @decimal_columns = left(@decimal_columns, len(@decimal_columns)-1)

		set @query = @query + '
		,	' + @decimal_columns

		set @resolved_pivot_template = replace(@pivot_query_template, '@@@META_VALUES_TABLE@@@', '[orm_meta].[values_decimal]')
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@META_VALUES_TABLE_SANITIZED@@@', '_orm_meta___values_decimal_')
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@VALUES_COLUMNS@@@', @decimal_columns)
		set @resolved_pivot_template = replace(@resolved_pivot_template, 'p.datatype_guid = @@@DATATYPE_GUID@@@', 'p.datatype_guid = 0x00000000000000000000000000000003')

		set @pivot_sub_query = @pivot_sub_query + @resolved_pivot_template
	end


	if isnull(@datetime_columns, '') <> ''
	begin
		set @datetime_columns = left(@datetime_columns, len(@datetime_columns)-1)

		set @query = @query + '
		,	' + @datetime_columns

		set @resolved_pivot_template = replace(@pivot_query_template, '@@@META_VALUES_TABLE@@@', '[orm_meta].[values_datetime]')
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@META_VALUES_TABLE_SANITIZED@@@', '_orm_meta___values_datetime_')
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@VALUES_COLUMNS@@@', @datetime_columns)
		set @resolved_pivot_template = replace(@resolved_pivot_template, 'p.datatype_guid = @@@DATATYPE_GUID@@@', 'p.datatype_guid = 0x00000000000000000000000000000004')

		set @pivot_sub_query = @pivot_sub_query + @resolved_pivot_template
	end

	
	if isnull(@instance_columns, '') <> ''
	begin
		set @instance_columns = left(@instance_columns, len(@instance_columns)-1)

		set @query = @query + '
		,	' + @instance_columns

		set @resolved_pivot_template = replace(@pivot_query_template, '@@@META_VALUES_TABLE@@@', '[orm_meta].[values_instance]')
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@META_VALUES_TABLE_SANITIZED@@@', '_orm_meta___values_instance_')
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@VALUES_COLUMNS@@@', @instance_columns)
		set @resolved_pivot_template = replace(@resolved_pivot_template, 'p.datatype_guid = @@@DATATYPE_GUID@@@', 'p.datatype_guid > 0x00000000000000000000000000000004')

		set @pivot_sub_query = @pivot_sub_query + @resolved_pivot_template
	end


	set @query = @query + ' , o.Instance_guid as Instance_guid
	from	[orm_meta].[instances] as o
		inner join [orm_meta].[sub_templates](''' + convert(nvarchar(36), @template_guid) + ''') as sub_templates
			on o.template_guid = sub_templates.template_guid
	' + @pivot_sub_query

	-- print @query

	exec sp_executesql @query

	exec [orm_meta].[generate_template_view_triggers] @template_guid

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go

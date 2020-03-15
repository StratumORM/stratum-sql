print '
Generating template dynamic view (wide)...'


IF OBJECT_ID('[orm_meta].[generate_template_view_wide]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[generate_template_view_wide]
go


create procedure [orm_meta].[generate_template_view_wide]
	@template_id int
as
begin

	declare @string_columns nvarchar(max)
		,	@integer_columns nvarchar(max)
		,	@decimal_columns nvarchar(max)
		,	@datetime_columns nvarchar(max)
		,	@instance_columns nvarchar(max)

		,	@pivot_query_template nvarchar(max)
		,	@resolved_pivot_template nvarchar(max)
		,	@pivot_sub_query nvarchar(max)
		,	@query nvarchar(max)

		,	@template_name varchar(250)

	set @template_name = (select top 1 name from [orm_meta].[templates] where template_id = @template_id)

	set @string_columns =	(	select QUOTENAME(name) + ',' 
								from [orm_meta].[properties] as p
								where	p.datatype_id = 1 
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_id = @template_id 
								for xml path(''))

	set @integer_columns =	(	select QUOTENAME(name) + ','
								from [orm_meta].[properties] as p
								where	p.datatype_id = 2 
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_id = @template_id 
								for xml path(''))

	set @decimal_columns =	(	select QUOTENAME(name) + ','
								from [orm_meta].[properties] as p
								where	p.datatype_id = 3 
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_id = @template_id 
								for xml path(''))

	set @datetime_columns =	(	select QUOTENAME(name) + ','
								from [orm_meta].[properties] as p
								where	p.datatype_id = 4
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_id = @template_id 
								for xml path(''))

	set @instance_columns =	(	select QUOTENAME(name) + ','
								from [orm_meta].[properties] as p
								where	not p.datatype_id in (1,2,3,4)
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_id = @template_id 
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
			( 	select	o.instance_id
					,	p.name as Property
					,	v.value
				from	[orm_meta].[instances] as o 
					inner join [orm_meta].[properties] as p
						on o.template_id = p.template_id
					inner join @@@META_VALUES_TABLE@@@ as v
						on 	p.property_id = v.property_id
						and	v.instance_id = o.instance_id
				where (p.is_extended is NULL or p.is_extended = 0)
					and p.datatype_id = @@@DATATYPE_ID@@@ 
			) as src
			pivot
			(
				max (value)
				for Property in (@@@VALUES_COLUMNS@@@)
			) as @@@META_VALUES_TABLE_SANITIZED@@@_pivot
			on o.instance_id = @@@META_VALUES_TABLE_SANITIZED@@@_pivot.instance_id
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
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@DATATYPE_ID@@@', convert(nvarchar(10), 1))

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
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@DATATYPE_ID@@@', convert(nvarchar(10), 2))

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
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@DATATYPE_ID@@@', convert(nvarchar(10), 3))

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
		set @resolved_pivot_template = replace(@resolved_pivot_template, '@@@DATATYPE_ID@@@', convert(nvarchar(10), 4))

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
		set @resolved_pivot_template = replace(@resolved_pivot_template, 'p.datatype_id = @@@DATATYPE_ID@@@', 'p.datatype_id > 4')

		set @pivot_sub_query = @pivot_sub_query + @resolved_pivot_template
	end


	set @query = @query + ' , o.Instance_id as Instance_id
	from	[orm_meta].[instances] as o
		inner join [orm_meta].[sub_templates](' + convert(nvarchar(100), @template_id) + ') as sub_templates
			on o.template_id = sub_templates.template_id
	' + @pivot_sub_query

	-- print @query

	exec sp_executesql @query

	exec [orm_meta].[generate_template_view_triggers] @template_id

end
go

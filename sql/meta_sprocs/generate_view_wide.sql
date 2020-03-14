print '
Generating template dynamic view (wide)...'


IF OBJECT_ID('[dbo].[orm_meta_generate_template_view_wide]', 'P') IS NOT NULL
	DROP PROCEDURE [dbo].orm_meta_generate_template_view_wide
go


create procedure [dbo].[orm_meta_generate_template_view_wide]
	@templateID int
as
begin

	declare @stringColumns nvarchar(max)
		,	@integerColumns nvarchar(max)
		,	@decimalColumns nvarchar(max)
		,	@datetimeColumns nvarchar(max)
		,	@instanceColumns nvarchar(max)

		,	@pivotQueryTemplate nvarchar(max)
		,	@resolvedPivotTemplate nvarchar(max)
		,	@pivotSubQuery nvarchar(max)
		,	@query nvarchar(max)

		,	@templateName varchar(250)

	set @templateName = (select top 1 name from orm_meta_templates where templateID = @templateID)

	set @stringColumns =	(	select '[' + name + '],' 
								from orm_meta_properties as p
								where	p.datatypeID = 1 
									and (p.isExtended is NULL or p.isExtended = 0) 
									and p.templateID = @templateID 
								for xml path(''))

	set @integerColumns =	(	select '[' + name + '],' 
								from orm_meta_properties as p
								where	p.datatypeID = 2 
									and (p.isExtended is NULL or p.isExtended = 0) 
									and p.templateID = @templateID 
								for xml path(''))

	set @decimalColumns =	(	select '[' + name + '],' 
								from orm_meta_properties as p
								where	p.datatypeID = 3 
									and (p.isExtended is NULL or p.isExtended = 0) 
									and p.templateID = @templateID 
								for xml path(''))

	set @datetimeColumns =	(	select '[' + name + '],' 
								from orm_meta_properties as p
								where	p.datatypeID = 4
									and (p.isExtended is NULL or p.isExtended = 0) 
									and p.templateID = @templateID 
								for xml path(''))

	set @instanceColumns =	(	select '[' + name + '],' 
								from orm_meta_properties as p
								where	not p.datatypeID in (1,2,3,4)
									and (p.isExtended is NULL or p.isExtended = 0) 
									and p.templateID = @templateID 
								for xml path(''))


	IF OBJECT_ID('dbo.' + @templateName + '', 'V') IS NOT NULL
		set @query = 'alter'
	else
		set @query = 'create'

	set @query = @query + ' view ' + @templateName + '
	as
	select	o.name as InstanceName '

	set @pivotQueryTemplate = '
		left join
			( 	select	o.instanceID
					,	p.name as Property
					,	v.value
				from	orm_meta_instances as o 
					inner join orm_meta_properties as p
						on o.templateID = p.templateID
					inner join @@@META_VALUES_TABLE@@@ as v
						on 	p.propertyID = v.propertyID
						and	v.instanceID = o.instanceID
				where (p.isExtended is NULL or p.isExtended = 0)
					and p.datatypeID = @@@DATATYPE_ID@@@ 
			) as src
			pivot
			(
				max (value)
				for Property in (@@@VALUES_COLUMNS@@@)
			) as @@@META_VALUES_TABLE@@@_pivot
			on o.instanceID = @@@META_VALUES_TABLE@@@_pivot.instanceID
		'
	set @pivotSubQuery = ''

	if isnull(@stringColumns, '') <> ''
	begin
		set @stringColumns = left(@stringColumns, len(@stringColumns)-1)

		set @query = @query + '
		,	' + @stringColumns

		set @resolvedPivotTemplate = replace(@pivotQueryTemplate, '@@@META_VALUES_TABLE@@@', 'orm_meta_values_string')
		set @resolvedPivotTemplate = replace(@resolvedPivotTemplate, '@@@VALUES_COLUMNS@@@', @stringColumns)
		set @resolvedPivotTemplate = replace(@resolvedPivotTemplate, '@@@DATATYPE_ID@@@', convert(nvarchar(10), 1))

		set @pivotSubQuery = @pivotSubQuery + @resolvedPivotTemplate
	end


	if isnull(@integerColumns, '') <> ''
	begin
		set @integerColumns = left(@integerColumns, len(@integerColumns)-1)

		set @query = @query + '
		,	' + @integerColumns

		set @resolvedPivotTemplate = replace(@pivotQueryTemplate, '@@@META_VALUES_TABLE@@@', 'orm_meta_values_integer')
		set @resolvedPivotTemplate = replace(@resolvedPivotTemplate, '@@@VALUES_COLUMNS@@@', @integerColumns)
		set @resolvedPivotTemplate = replace(@resolvedPivotTemplate, '@@@DATATYPE_ID@@@', convert(nvarchar(10), 2))

		set @pivotSubQuery = @pivotSubQuery + @resolvedPivotTemplate
	end


	if isnull(@decimalColumns, '') <> ''
	begin
		set @decimalColumns = left(@decimalColumns, len(@decimalColumns)-1)

		set @query = @query + '
		,	' + @decimalColumns

		set @resolvedPivotTemplate = replace(@pivotQueryTemplate, '@@@META_VALUES_TABLE@@@', 'orm_meta_values_decimal')
		set @resolvedPivotTemplate = replace(@resolvedPivotTemplate, '@@@VALUES_COLUMNS@@@', @decimalColumns)
		set @resolvedPivotTemplate = replace(@resolvedPivotTemplate, '@@@DATATYPE_ID@@@', convert(nvarchar(10), 3))

		set @pivotSubQuery = @pivotSubQuery + @resolvedPivotTemplate
	end


	if isnull(@datetimeColumns, '') <> ''
	begin
		set @datetimeColumns = left(@datetimeColumns, len(@datetimeColumns)-1)

		set @query = @query + '
		,	' + @datetimeColumns

		set @resolvedPivotTemplate = replace(@pivotQueryTemplate, '@@@META_VALUES_TABLE@@@', 'orm_meta_values_datetime')
		set @resolvedPivotTemplate = replace(@resolvedPivotTemplate, '@@@VALUES_COLUMNS@@@', @datetimeColumns)
		set @resolvedPivotTemplate = replace(@resolvedPivotTemplate, '@@@DATATYPE_ID@@@', convert(nvarchar(10), 4))

		set @pivotSubQuery = @pivotSubQuery + @resolvedPivotTemplate
	end

	
	if isnull(@instanceColumns, '') <> ''
	begin
		set @instanceColumns = left(@instanceColumns, len(@instanceColumns)-1)

		set @query = @query + '
		,	' + @instanceColumns

		set @resolvedPivotTemplate = replace(@pivotQueryTemplate, '@@@META_VALUES_TABLE@@@', 'orm_meta_values_instance')
		set @resolvedPivotTemplate = replace(@resolvedPivotTemplate, '@@@VALUES_COLUMNS@@@', @instanceColumns)
		set @resolvedPivotTemplate = replace(@resolvedPivotTemplate, 'p.datatypeID = @@@DATATYPE_ID@@@', 'not p.datatypeID in (1,2,3,4)')

		set @pivotSubQuery = @pivotSubQuery + @resolvedPivotTemplate
	end


	set @query = @query + ' , o.InstanceID as InstanceID
	from	orm_meta_instances as o
		inner join dbo.orm_meta_subTemplates(' + convert(nvarchar(100), @templateID) + ') as subTemplates
			on o.templateID = subTemplates.templateID
	' + @pivotSubQuery

	exec sp_executesql @query

	exec orm_meta_generate_template_view_triggers @templateID

end
go
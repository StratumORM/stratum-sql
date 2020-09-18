print '
Generating template dynamic view (tall listing)...'


IF OBJECT_ID('[orm_meta].[generate_template_view_listing]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[generate_template_view_listing]
go

create procedure [orm_meta].[generate_template_view_listing]
	@template_guid uniqueidentifier
as
begin
	-- Generate the tall view that's five columns wide, one for
	-- (template, instance, property, value, datatype)

	declare @view_query nvarchar(max), @view_name nvarchar(max), @template_name nvarchar(250)

		set @template_name = (select name from [orm_meta].[templates] where template_guid = @template_guid)
		set @view_name = '[orm_meta].' + quotename(@template_name + ' listing')

		set @view_query = (select VIEW_DEFINITION from INFORMATION_SCHEMA.VIEWS	where TABLE_NAME = '[orm_meta].[all_values_listing]')

	-- modify the name of the view to match the template
	set @view_query = replace(@view_query, '[orm_meta].[all_values_listing]', @view_name)

	-- modify the join to filter for our subclassed instances
	set @view_query = replace(@view_query, 'inner join [orm_meta].[properties] as p
			on o.template_guid = p.template_guid', '
		-- include instances from templates that inherit from this one
		inner join [orm_meta].[sub_templates](''' + convert(nvarchar(36), @template_guid) + ''') as sub_templates
			on o.template_guid = sub_templates.template_guid
		
		-- ... but only allow names relevant to this one
		inner join [orm_meta].[properties] as p_names
			on p_names.template_guid = ''' + convert(nvarchar(36), @template_guid) + '''

		-- ... and then filter that list to values that exist
		inner join [orm_meta].[properties] as p
			on	p_names.name = p.name
			and o.template_guid = p.template_guid')
	
	set @view_query = replace(@view_query, 't.name as [Template],', '')

	exec sp_executesql @view_query

end
go

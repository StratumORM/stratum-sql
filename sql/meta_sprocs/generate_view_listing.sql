print '
Generating template dynamic view (tall listing)...'


IF OBJECT_ID('[orm_meta].[generate_template_view_listing]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[generate_template_view_listing]
go

create procedure [orm_meta].[generate_template_view_listing]
	@template_id int
as
begin
	-- Generate the tall view that's five columns wide, one for
	-- (template, instance, property, value, datatype)

	declare @view_query nvarchar(max), @view_name nvarchar(max), @template_name varchar(250)

		set @template_name = (select top 1 name from [orm_meta].[templates] where template_id = @template_id)
		set @view_name = 'orm_' + @template_name + '_listing'

	select @view_query = VIEW_DEFINITION
	from INFORMATION_SCHEMA.VIEWS
	where TABLE_NAME = '[orm_meta].[all_values_listing]'

	-- modify the name of the view to match the template
	set @view_query = replace(@view_query, '[orm_meta].[all_values_listing]', @view_name)

	-- modify the join to filter for our subclassed instances
	set @view_query = replace(@view_query, 'inner join [orm_meta].[properties] as p
			on o.template_id = p.template_id', '
		-- include instances from templates that inherit from this one
		inner join [orm_meta].[sub_templates](' + convert(nvarchar(100), @template_id) + ') as sub_templates
			on o.template_id = sub_templates.template_id
		
		-- ... but only allow names relevant to this one
		inner join [orm_meta].[properties] as p_names
			on p_names.template_id = ' + convert(nvarchar(100), @template_id) + '

		-- ... and then filter that list to values that exist
		inner join [orm_meta].[properties] as p
			on	p_names.name = p.name
			and o.template_id = p.template_id')
	
	set @view_query = replace(@view_query, 't.name as [Template],', '')

	exec sp_executesql @view_query

end
go

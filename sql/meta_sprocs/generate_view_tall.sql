print '
Generating template dynamic view (tall)...'


IF OBJECT_ID('[orm_meta].[generate_template_view_tall]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[generate_template_view_tall]
go

create procedure [orm_meta].[generate_template_view_tall]
	@template_id int
as
begin
	-- Generate the tall view that looks like the Ignition historian data view.
	-- (This is simply a filtered version of the all-values view.)
	
	declare @view_query nvarchar(max), @view_declaration nvarchar(max), @template_name varchar(250)

		set @template_name = (select top 1 name from [orm_meta].[templates] where template_id = @template_id)
		set @view_declaration = 'create view orm_' + @template_name + '_values'

	select @view_query = VIEW_DEFINITION
	from INFORMATION_SCHEMA.VIEWS
	where TABLE_NAME = '[orm_meta].[all_values]'

	-- modify the name of the view to match
	set @view_query = replace(@view_query, 'create view [orm_meta].[all_values]', @view_declaration)

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

	exec sp_executesql @view_query

end
go










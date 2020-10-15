print '
Generating template dynamic view (tall)...'


IF OBJECT_ID('[orm_meta].[generate_template_view_tall]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[generate_template_view_tall]
go

create procedure [orm_meta].[generate_template_view_tall]
	@template_guid uniqueidentifier
as
begin
	set nocount on;

	-- Generate the tall view that looks like the Ignition historian data view.
	-- (This is simply a filtered version of the all-values view.)
	
	declare @view_query nvarchar(max), @view_declaration nvarchar(max), @template_name nvarchar(250)

		set @template_name = (select top 1 name from [orm_meta].[templates] where template_guid = @template_guid)
		set @view_declaration = 'create view [orm_meta].' + quotename(@template_name + ' values')

		set @view_query = (select VIEW_DEFINITION from INFORMATION_SCHEMA.VIEWS	where TABLE_NAME = '[orm_meta].[all_values]')

	-- modify the name of the view to match
	set @view_query = replace(@view_query, 'create view [orm_meta].[all_values]', @view_declaration)

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

	exec sp_executesql @view_query

end
go










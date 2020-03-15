print '
Generating template dynamic view (tall listing)...'


IF OBJECT_ID('[orm].[orm_meta_generate_template_view_listing]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_meta_generate_template_view_listing
go

create procedure [orm].[orm_meta_generate_template_view_listing]
	@templateID int
as
begin
	-- Generate the tall view that's five columns wide, one for
	-- (template, instance, property, value, datatype)

	declare @viewQuery nvarchar(max), @viewName nvarchar(max), @templateName varchar(250)

		set @templateName = (select top 1 name from orm_meta_templates where templateID = @templateID)
		set @viewName = 'orm_' + @templateName + '_listing'

	select @viewQuery = VIEW_DEFINITION
	from INFORMATION_SCHEMA.VIEWS
	where TABLE_NAME = 'orm_meta_all_values_listing'

	-- modify the name of the view to match the template
	set @viewQuery = replace(@viewQuery, 'orm_meta_all_values_listing', @viewName)

	-- modify the join to filter for our subclassed instances
	set @viewQuery = replace(@viewQuery, 'inner join orm_meta_properties as p
			on o.templateID = p.templateID', '
		-- include instances from templates that inherit from this one
		inner join [orm].orm_meta_subTemplates(' + convert(nvarchar(100), @templateID) + ') as subTemplates
			on o.templateID = subTemplates.templateID
		
		-- ... but only allow names relevant to this one
		inner join orm_meta_properties as pNames
			on pNames.templateID = ' + convert(nvarchar(100), @templateID) + '

		-- ... and then filter that list to values that exist
		inner join orm_meta_properties as p
			on	pNames.name = p.name
			and o.templateID = p.templateID')
	
	set @viewQuery = replace(@viewQuery, 't.name as [Template],', '')

	exec sp_executesql @viewQuery

end
go

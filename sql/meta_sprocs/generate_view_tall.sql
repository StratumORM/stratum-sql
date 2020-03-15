print '
Generating template dynamic view (tall)...'


IF OBJECT_ID('[orm_meta].[generate_template_view_tall]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[generate_template_view_tall]
go

create procedure [orm_meta].[generate_template_view_tall]
	@templateID int
as
begin
	-- Generate the tall view that looks like the Ignition historian data view.
	-- (This is simply a filtered version of the all-values view.)
	
	declare @viewQuery nvarchar(max), @viewDeclaration nvarchar(max), @templateName varchar(250)

		set @templateName = (select top 1 name from [orm_meta].[templates] where templateID = @templateID)
		set @viewDeclaration = 'create view orm_' + @templateName + '_values'

	select @viewQuery = VIEW_DEFINITION
	from INFORMATION_SCHEMA.VIEWS
	where TABLE_NAME = '[orm_meta].[all_values]'

	-- modify the name of the view to match
	set @viewQuery = replace(@viewQuery, 'create view [orm_meta].[all_values]', @viewDeclaration)

	-- modify the join to filter for our subclassed instances
	set @viewQuery = replace(@viewQuery, 'inner join [orm_meta].[properties] as p
			on o.templateID = p.templateID', '
		-- include instances from templates that inherit from this one
		inner join [orm_meta].[subTemplates](' + convert(nvarchar(100), @templateID) + ') as subTemplates
			on o.templateID = subTemplates.templateID
		
		-- ... but only allow names relevant to this one
		inner join [orm_meta].[properties] as pNames
			on pNames.templateID = ' + convert(nvarchar(100), @templateID) + '

		-- ... and then filter that list to values that exist
		inner join [orm_meta].[properties] as p
			on	pNames.name = p.name
			and o.templateID = p.templateID')

	exec sp_executesql @viewQuery

end
go










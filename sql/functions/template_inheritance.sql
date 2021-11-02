print '
Generating template inheritance functions...'



if object_id('[orm_meta].[sub_templates]', 'IF') is not null
	drop function [orm_meta].[sub_templates]
go

create function [orm_meta].[sub_templates]
(	
	@template_guid uniqueidentifier
)
RETURNS TABLE 
AS
RETURN 
(
	with included_templates as
	(
		select t.template_guid, 0 as echelon
		from orm_meta.templates as t
		where t.template_guid = @template_guid

		union all

		select i.child_template_guid, echelon - 1
		from included_templates as it
			inner join [orm_meta].[inheritance] as i
				on it.template_guid = i.parent_template_guid
	)
	select distinct template_guid, echelon
	from included_templates
)
GO


if object_id('[orm_meta].[super_templates]', 'IF') is not null
	drop function [orm_meta].[super_templates]
go

create function [orm_meta].[super_templates]
(	
	@template_guid uniqueidentifier
)
RETURNS TABLE 
AS
RETURN 
(
	with included_templates as
	(
		select t.template_guid, 0 as echelon
		from orm_meta.templates as t
		where t.template_guid = @template_guid

		union all

		select i.parent_template_guid, echelon + 1
		from included_templates as it
			inner join [orm_meta].[inheritance] as i
				on it.template_guid = i.child_template_guid
	)
	select distinct template_guid, echelon
	from included_templates
)
GO


if object_id('[orm_meta].[template_tree]', 'IF') is not null
	drop function [orm_meta].[template_tree]
go

create function [orm_meta].[template_tree]
(	
	@template_guid uniqueidentifier
)
RETURNS TABLE 
AS
RETURN 
(
	select template_guid, echelon
	from (	select template_guid, echelon
			from [orm_meta].[sub_templates](@template_guid) as subs
			
			union
			
			select template_guid, echelon
			from [orm_meta].[super_templates](@template_guid) as supers
		) as structure			
)
GO


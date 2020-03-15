print '
Generating template inheritance functions...'



if object_id('[orm_meta].[sub_templates]', 'IF') is not null
	drop function [orm_meta].[sub_templates]
go

create function [orm_meta].[sub_templates]
(	
	@template_id int
)
RETURNS TABLE 
AS
RETURN 
(
	with included_templates as
	(
		select @template_id as template_id, 0 as echelon

		union all

		select i.child_template_id, echelon - 1
		from included_templates as it
			inner join [orm_meta].[inheritance] as i
				on it.template_id = i.parent_template_id
	)
	select template_id, echelon
	from included_templates
)
GO


if object_id('[orm_meta].[super_templates]', 'IF') is not null
	drop function [orm_meta].[super_templates]
go

create function [orm_meta].[super_templates]
(	
	@template_id int
)
RETURNS TABLE 
AS
RETURN 
(
	with included_templates as
	(
		select @template_id as template_id, 0 as echelon

		union all

		select i.parent_template_id, echelon + 1
		from included_templates as it
			inner join [orm_meta].[inheritance] as i
				on it.template_id = i.child_template_id
	)
	select template_id, echelon
	from included_templates
)
GO


if object_id('[orm_meta].[template_tree]', 'IF') is not null
	drop function [orm_meta].[template_tree]
go

create function [orm_meta].[template_tree]
(	
	@template_id int
)
RETURNS TABLE 
AS
RETURN 
(
	select template_id, echelon
	from (	select template_id, echelon
			from [orm_meta].[sub_templates](@template_id) as subs
			
			union
			
			select template_id, echelon
			from [orm_meta].[super_templates](@template_id) as supers
		) as structure			
)
GO


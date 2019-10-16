print '
Generating template inheritance functions...'



if object_id('[dbo].[orm_meta_subTemplates]', 'IF') is not null
	drop function dbo.orm_meta_subTemplates
go

create function dbo.orm_meta_subTemplates
(	
	@templateID int
)
RETURNS TABLE 
AS
RETURN 
(
	with includedTemplates as
	(
		select @templateID as templateID, 0 as echelon

		union all

		select i.childTemplateID, echelon - 1
		from includedTemplates as it
			inner join orm_meta_inheritance as i
				on it.templateID = i.parentTemplateID
	)
	select templateID, echelon
	from includedTemplates
)
GO


if object_id('[dbo].[orm_meta_superTemplates]', 'IF') is not null
	drop function dbo.orm_meta_superTemplates
go

create function dbo.orm_meta_superTemplates
(	
	@templateID int
)
RETURNS TABLE 
AS
RETURN 
(
	with includedTemplates as
	(
		select @templateID as templateID, 0 as echelon

		union all

		select i.parentTemplateID, echelon + 1
		from includedTemplates as it
			inner join orm_meta_inheritance as i
				on it.templateID = i.childTemplateID
	)
	select templateID, echelon
	from includedTemplates
)
GO


if object_id('[dbo].[orm_meta_templateTree]', 'IF') is not null
	drop function dbo.orm_meta_templateTree
go

create function dbo.orm_meta_templateTree
(	
	@templateID int
)
RETURNS TABLE 
AS
RETURN 
(
	select templateID, echelon
	from (	select templateID, echelon
			from dbo.orm_meta_subTemplates(@templateID) as subs
			
			union
			
			select templateID, echelon
			from dbo.orm_meta_superTemplates(@templateID) as supers
		) as structure			
)
GO


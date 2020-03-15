print '
Generating template inheritance functions...'



if object_id('[orm_meta].[subTemplates]', 'IF') is not null
	drop function [orm_meta].[subTemplates]
go

create function [orm_meta].[subTemplates]
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
			inner join [orm_meta].[inheritance] as i
				on it.templateID = i.parentTemplateID
	)
	select templateID, echelon
	from includedTemplates
)
GO


if object_id('[orm_meta].[superTemplates]', 'IF') is not null
	drop function [orm_meta].[superTemplates]
go

create function [orm_meta].[superTemplates]
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
			inner join [orm_meta].[inheritance] as i
				on it.templateID = i.childTemplateID
	)
	select templateID, echelon
	from includedTemplates
)
GO


if object_id('[orm_meta].[templateTree]', 'IF') is not null
	drop function [orm_meta].[templateTree]
go

create function [orm_meta].[templateTree]
(	
	@templateID int
)
RETURNS TABLE 
AS
RETURN 
(
	select templateID, echelon
	from (	select templateID, echelon
			from [orm_meta].[subTemplates](@templateID) as subs
			
			union
			
			select templateID, echelon
			from [orm_meta].[superTemplates](@templateID) as supers
		) as structure			
)
GO


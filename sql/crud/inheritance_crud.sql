print '
Generating template inheritance CRUD definitions...'


IF OBJECT_ID('[orm].[orm_inherit_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_inherit_add
go

IF OBJECT_ID('[orm_meta].[inherit_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[inherit_add]
go


create procedure [orm_meta].[inherit_add]
	@parentTemplateID int
,	@childTemplateID int
,	@ordinal int = null 	
as
begin

	-- by default we'll tack the ordinal to the end, so get the largest value + 1
	if @ordinal is null 	set @ordinal = (	select isnull(max(ordinal), 0) + 1
												from [orm_meta].[inheritance] as i
												where childTemplateID = @childTemplateID	)

	-- Perform a merge in case the ordinal is merely changing
	-- Triggers will take care of the resolution of the properties.
	merge into [orm_meta].[inheritance] as d
	using (	select	@parentTemplateID as parentTemplateID
				,	@childTemplateID as childTemplateID
				,	@ordinal as ordinal) as s
		on d.parentTemplateID = s.parentTemplateID
		and d.childTemplateID = s.childTemplateID
	when matched then
		update
		set d.ordinal = s.ordinal
	when not matched then
		insert (parentTemplateID, childTemplateID, ordinal)
		values (s.parentTemplateID, s.childTemplateID, s.ordinal)
	;

end
go


create procedure orm_inherit_add
	@parentTemplateName varchar(250)
,	@childTemplateName varchar(250)
,	@ordinal int = null 	
as
begin
	
	-- resolve the IDs so that the meta sproc can take care of the rest
	declare @parentTemplateID int, @childTemplateID int
		set @parentTemplateID = (select top 1 templateID from [orm_meta].[templates] where name = @parentTemplateName)
		set @childTemplateID = (select top 1 templateID from [orm_meta].[templates] where name = @childTemplateName)

	exec [orm_meta].[inherit_add] @parentTemplateID, @childTemplateID, @ordinal

end
go


IF OBJECT_ID('[orm].[orm_inherit_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_inherit_remove
go

IF OBJECT_ID('[orm_meta].[inherit_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[inherit_remove]
go

create procedure [orm_meta].[inherit_remove]
	@parentTemplateID int
,	@childTemplateID int
as
begin

	delete [orm_meta].[inheritance]
	where 	parentTemplateID = @parentTemplateID
		and	childTemplateID = @childTemplateID

end
go


create procedure orm_inherit_remove
	@parentTemplateName varchar(250)
,	@childTemplateName varchar(250)
as
begin
	
	-- resolve the IDs so that the meta sproc can take care of the rest
	declare @parentTemplateID int, @childTemplateID int
		set @parentTemplateID = (select top 1 templateID from [orm_meta].[templates] where name = @parentTemplateName)
		set @childTemplateID = (select top 1 templateID from [orm_meta].[templates] where name = @childTemplateName)

	exec [orm_meta].[inherit_remove] @parentTemplateID, @childTemplateID

end
go

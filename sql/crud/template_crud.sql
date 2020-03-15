print '
Generating template CRUD definitions...'



IF OBJECT_ID('[orm].[orm_template_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_template_add
go

create procedure orm_template_add
	@newTemplateName varchar(250)
,	@signature nvarchar(max) = NULL
as
begin
	SET NOCOUNT ON;

	insert orm_meta_templates (name, signature)
	values (@newTemplateName, @signature)

    return @@identity
end
go


IF OBJECT_ID('[orm].[orm_template_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_template_remove
go

IF OBJECT_ID('[orm].[orm_meta_template_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_meta_template_remove
go


create procedure orm_template_remove
	@templateName varchar(250)
as
begin
	SET NOCOUNT ON;

	delete orm_meta_templates
	where name = @templateName

end
go


create procedure orm_meta_template_remove
	@templateID int
as
begin

	delete orm_meta_templates
	where templateID = @templateID

end
go

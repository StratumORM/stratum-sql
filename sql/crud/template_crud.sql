print '
Generating template CRUD definitions...'



IF OBJECT_ID('[orm].[template_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[template_add]
go

create procedure [orm].[template_add]
	@new_template_name varchar(250)
,	@signature nvarchar(max) = NULL
as
begin
	set nocount on;

	insert [orm_meta].[templates] (name, signature)
	values (@new_template_name, @signature)

    return @@identity
end
go


IF OBJECT_ID('[orm].[template_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[template_remove]
go

IF OBJECT_ID('[orm_meta].[template_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[template_remove]
go


create procedure [orm].[template_remove]
	@template_name varchar(250)
as
begin
	set nocount on;

	delete [orm_meta].[templates]
	where name = @template_name

end
go


create procedure [orm_meta].[template_remove]
	@template_guid uniqueidentifier
as
begin
	set nocount on;

	delete [orm_meta].[templates]
	where template_guid = @template_guid

end
go

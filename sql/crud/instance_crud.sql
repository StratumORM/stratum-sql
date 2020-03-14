print '
Generating instance CRUD definitions...'


IF OBJECT_ID('[dbo].[orm_instance_add]', 'P') IS NOT NULL
	DROP PROCEDURE [dbo].orm_instance_add
go

create procedure orm_instance_add
	@templateName varchar(250)
,	@newInstanceName varchar(250)
as
begin
	SET NOCOUNT ON;

	declare @templateID int, @instanceID int
		select @templateID = templateID
		from orm_meta_templates
		where name = @templateName
	
	-- Make sure the instance doesn't already exist
	select instanceID from orm_meta_instances where name = @newInstanceName and templateID = @templateID
	if @@ROWCOUNT <> 0 raiserror('instance already exists.', 16, 1)
	
	insert orm_meta_instances (templateID, name)
	values (@templateID, @newInstanceName)	

	set @instanceID = @@identity

    return @instanceID
end
go


IF OBJECT_ID('[dbo].[orm_instance_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [dbo].orm_instance_remove
go

create procedure orm_instance_remove
	@templateName varchar(250)
,	@oldInstanceName varchar(250)
as
begin
	SET NOCOUNT ON;

	declare @templateID int, @instanceID int
		select @templateID = templateID
		from orm_meta_templates
		where name = @templateName
	
	-- Make sure the instance doesn't already exist
	delete orm_meta_instances
	where name = @oldInstanceName
		and templateID = @templateID

end
go

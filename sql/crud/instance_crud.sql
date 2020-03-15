print '
Generating instance CRUD definitions...'


IF OBJECT_ID('[orm].[instance_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[instance_add]
go

create procedure [orm].[instance_add]
	@template_name varchar(250)
,	@new_instance_name varchar(250)
as
begin
	SET NOCOUNT ON;

	declare @template_id int, @instance_id int
		select @template_id = template_id
		from [orm_meta].[templates]
		where name = @template_name
	
	-- Make sure the instance doesn't already exist
	select instance_id from [orm_meta].[instances] where name = @new_instance_name and template_id = @template_id
	if @@ROWCOUNT <> 0 raiserror('instance already exists.', 16, 1)
	
	insert [orm_meta].[instances] (template_id, name)
	values (@template_id, @new_instance_name)	

	set @instance_id = @@identity

    return @instance_id
end
go


IF OBJECT_ID('[orm].[instance_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[instance_remove]
go

create procedure [orm].[instance_remove]
	@template_name varchar(250)
,	@old_instance_name varchar(250)
as
begin
	SET NOCOUNT ON;

	declare @template_id int, @instance_id int
		select @template_id = template_id
		from [orm_meta].[templates]
		where name = @template_name
	
	-- Make sure the instance doesn't already exist
	delete [orm_meta].[instances]
	where name = @old_instance_name
		and template_id = @template_id

end
go


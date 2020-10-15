print '
Generating instance CRUD definitions...'


IF OBJECT_ID('[orm].[instance_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[instance_add]
go

create procedure [orm].[instance_add]
	@template_name varchar(250)
,	@instance_name varchar(250)
as
begin
	set nocount on;

	declare @template_guid uniqueidentifier
		
		set @template_guid = (select template_guid
							  from [orm_meta].[templates]
							  where name = @template_name )
	
	-- Make sure the instance doesn't already exist
	if (
		select instance_guid 
		from [orm_meta].[instances] 
		where name = @instance_name 
		  and template_guid = @template_guid
		) is not null
	begin
		raiserror('instance already exists.', 16, 1)
	end
	
	insert [orm_meta].[instances] (template_guid, name)
	values (@template_guid, @instance_name)	

    return @@identity
end
go


IF OBJECT_ID('[orm].[instance_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[instance_remove]
go

create procedure [orm].[instance_remove]
	@template_name varchar(250)
,	@instance_name varchar(250)
as
begin
	set nocount on;

	declare @template_guid uniqueidentifier
		set @template_guid = (select template_guid
							  from [orm_meta].[templates]
							  where name = @template_name )
	
	-- Make sure the instance doesn't already exist
	delete [orm_meta].[instances]
	where name = @instance_name
		and template_guid = @template_guid

end
go


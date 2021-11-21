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
  set nocount on; set xact_abort on;
begin try
begin transaction -- orm_instance_add

	declare @template_guid uniqueidentifier
		,	@message nvarchar(1000)
		
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
			set @message = 'Instance "' + @instance_name + '" already exists for template "' + @template_name + '"'
			;throw 51000, @message, 1;
		end
	
	insert [orm_meta].[instances] (template_guid, name)
	values (@template_guid, @instance_name)	

  commit transaction -- orm_instance_add

  return @@identity

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID --, @tx = 'orm_instance_add'
end catch
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
  set nocount on; set xact_abort on;
begin try
begin transaction

	declare @template_guid uniqueidentifier
		set @template_guid = (select template_guid
							  from [orm_meta].[templates]
							  where name = @template_name )
	
	-- Make sure the instance doesn't already exist
	delete [orm_meta].[instances]
	where name = @instance_name
		and template_guid = @template_guid

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


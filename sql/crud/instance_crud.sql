print '
Generating instance CRUD definitions...'


IF OBJECT_ID('[orm].[instance_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[instance_add]
go

IF OBJECT_ID('[orm_meta].[instance_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[instance_add]
go


create procedure [orm].[instance_add]
	@template_name varchar(250)
,	@new_instance_name varchar(250)
,	@signature nvarchar(max) = NULL
as
begin
begin try
begin transaction -- orm_instance_add

  set nocount on; set xact_abort on;

	declare @template_guid uniqueidentifier		
		set @template_guid = (select template_guid
							  from [orm_meta].[templates]
							  where name = @template_name )
		
	insert [orm_meta].[instances] 
			( template_guid,               name,  signature)
	values  (@template_guid, @new_instance_name, @signature)	

  commit transaction -- orm_instance_add

  return @@identity

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID --, @tx = 'orm_instance_add'
end catch
end
go


create procedure [orm_meta].[instance_add]
	@template_guid varchar(250)
,	@new_instance_name varchar(250)
,	@new_instance_guid uniqueidentifier = NULL
,	@signature nvarchar(max) = NULL
as
begin
begin try
begin transaction -- orm_instance_add

  set nocount on; set xact_abort on;

	if @new_instance_guid is NULL
  		begin	
			insert [orm_meta].[instances] 
					( template_guid,               name,  signature)
			values  (@template_guid, @new_instance_name, @signature)	
		end
	else
		begin
			insert [orm_meta].[instances] 
					( template_guid,      instance_guid,               name,  signature)
			values  (@template_guid, @new_instance_guid, @new_instance_name, @signature)
		end

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

IF OBJECT_ID('[orm_meta].[instance_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[instance_remove]
go


create procedure [orm].[instance_remove]
	@template_name varchar(250)
,	@instance_name varchar(250)
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	declare @template_guid uniqueidentifier
		set @template_guid = (select template_guid
							  from [orm_meta].[templates]
							  where name = @template_name )
	
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


create procedure [orm_meta].[instance_remove]
	@instance_guid varchar(250)
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;
	
	delete [orm_meta].[instances]
	where instance_guid = @instance_guid

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


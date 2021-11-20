print '
Generating template inheritance CRUD definitions...'


IF OBJECT_ID('[orm].[inherit_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[inherit_add]
go

IF OBJECT_ID('[orm_meta].[inherit_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[inherit_add]
go


create procedure [orm_meta].[inherit_add]
	@parent_template_guid uniqueidentifier
,	@child_template_guid uniqueidentifier
,	@ordinal int = null 	
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	-- by default we'll tack the ordinal to the end, so get the largest value + 1
	if @ordinal is null 	set @ordinal = (	select isnull(max(ordinal), 0) + 1
												from [orm_meta].[inheritance] as i
												where child_template_guid = @child_template_guid	)

	-- Perform a merge in case the ordinal is merely changing
	-- Triggers will take care of the resolution of the properties.
	merge into [orm_meta].[inheritance] as d
	using (	select	@parent_template_guid as parent_template_guid
				,	@child_template_guid as child_template_guid
				,	@ordinal as ordinal) as s
		on d.parent_template_guid = s.parent_template_guid
		and d.child_template_guid = s.child_template_guid
	when matched then
		update
		set d.ordinal = s.ordinal
	when not matched then
		insert (  parent_template_guid,   child_template_guid,   ordinal)
		values (s.parent_template_guid, s.child_template_guid, s.ordinal)
	;

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


create procedure [orm].[inherit_add]
	@parent_template_name varchar(250)
,	@child_template_name varchar(250)
,	@ordinal int = null 	
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;
	
	-- resolve the IDs so that the meta sproc can take care of the rest
	declare @parent_template_guid uniqueidentifier
		, 	@child_template_guid uniqueidentifier
		set @parent_template_guid = (select top 1 template_guid 
									 from [orm_meta].[templates] 
									 where name = @parent_template_name)
		set @child_template_guid = (select top 1 template_guid 
									from [orm_meta].[templates] 
									where name = @child_template_name)

	exec [orm_meta].[inherit_add] @parent_template_guid, @child_template_guid, @ordinal

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


IF OBJECT_ID('[orm].[inherit_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[inherit_remove]
go

IF OBJECT_ID('[orm_meta].[inherit_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[inherit_remove]
go

create procedure [orm_meta].[inherit_remove]
	@parent_template_guid uniqueidentifier
,	@child_template_guid uniqueidentifier
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	delete [orm_meta].[inheritance]
	where 	parent_template_guid = @parent_template_guid
		and	child_template_guid = @child_template_guid

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


create procedure [orm].[inherit_remove]
	@parent_template_name varchar(250)
,	@child_template_name varchar(250)
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;
	
	-- resolve the IDs so that the meta sproc can take care of the rest
	declare @parent_template_guid uniqueidentifier
		, 	@child_template_guid uniqueidentifier
		set @parent_template_guid = (select top 1 template_guid 
									 from [orm_meta].[templates] 
									 where name = @parent_template_name)
		set @child_template_guid = (select top 1 template_guid 
									from [orm_meta].[templates] 
									where name = @child_template_name)

	exec [orm_meta].[inherit_remove] @parent_template_guid, @child_template_guid

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go

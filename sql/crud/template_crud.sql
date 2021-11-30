print '
Generating template CRUD definitions...'



IF OBJECT_ID('[orm].[template_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[template_add]
go

IF OBJECT_ID('[orm_meta].[template_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[template_add]
go


create procedure [orm].[template_add]
	@new_template_name varchar(250)
,	@no_auto_view int = NULL
,	@signature nvarchar(max) = NULL
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	insert [orm_meta].[templates] (name, no_auto_view, signature)
	values (@new_template_name, @no_auto_view, @signature)

  commit transaction

  return @@identity

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go



create procedure [orm_meta].[template_add]
	@new_template_name varchar(250)
,	@new_tempalte_guid uniqueidentifier = NULL
,	@no_auto_view int = NULL
,	@signature nvarchar(max) = NULL
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

  if @new_tempalte_guid is NULL
	  begin
			insert [orm_meta].[templates] 
				   (              name,  no_auto_view,  signature)
			values (@new_template_name, @no_auto_view, @signature)
		end 
	else 
		begin
			insert [orm_meta].[templates] 
				   (              name,      template_guid,  no_auto_view,  signature)
			values (@new_template_name, @new_tempalte_guid, @no_auto_view, @signature)
		end

  commit transaction

  return @@identity

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end



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
begin try
begin transaction

  set nocount on; set xact_abort on;

	delete [orm_meta].[templates]
	where name = @template_name

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


create procedure [orm_meta].[template_remove]
	@template_guid uniqueidentifier
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	delete [orm_meta].[templates]
	where template_guid = @template_guid

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go



IF OBJECT_ID('[orm].[template_info]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[template_info]
go

create procedure [orm].[template_info]
	@template_name varchar(250)
as
begin
	set nocount on;
	
    select t.name as template
    	,  t.no_auto_view
    	,  t.signature
        ,  t.template_guid
    from orm_meta.templates as t
	where t.name = @template_name
end
go
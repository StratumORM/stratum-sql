print '
Prepping the XO tables...'



/*
	NOTE: These tables aren't indexed or anything because they're purely
	      here for rebuilding on database wipe.
*/



IF OBJECT_ID('[orm_xo].[create_init_tables]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_xo].[create_init_tables]
go


create procedure [orm_xo].[create_init_tables]
	@cutoff datetimeoffset(7) = null
as
begin
begin try

  set nocount on;

    if [orm_meta].[check_context]('overwrite init backups') <> 1
	begin             -- (NOTE: when setting master ON, interlock automatically turns on!)
		;throw 51000, 'Can not create init tables - set overwrite interlock.', 1;
	end


  	IF OBJECT_ID('[orm_xo].[init_templates]', 'U') IS NOT NULL
		drop table [orm_xo].[init_templates]
  	IF OBJECT_ID('[orm_xo].[init_inheritance]', 'U') IS NOT NULL
		drop table [orm_xo].[init_inheritance]
  	IF OBJECT_ID('[orm_xo].[init_properties]', 'U') IS NOT NULL
		drop table [orm_xo].[init_properties]


	select 	template_id
		,	template_guid
		,   name
		,   no_auto_view
		,   signature
	into [orm_xo].[init_templates]
	from [orm_meta].[templates]


	select 	parent_template_guid
		,	child_template_guid
		,	ordinal
	into [orm_xo].[init_inheritance]
	from [orm_meta].[inheritance]


	select 	property_id
		,	property_guid
		,	template_guid
		,	name
		,	datatype_guid
		,	is_extended
		,	no_history
		,	signature
	into [orm_xo].[init_properties]
	from [orm_meta].[properties]


end try
begin catch
	-- clear the purge setup for safety reasons
	exec [orm_meta].[apply_context] 'overwrite init backups', 0
	exec [orm_meta].[handle_error] @@PROCID

end catch
end
go





IF OBJECT_ID('[orm_xo].[restore_init_tables]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_xo].[restore_init_tables]
go


create procedure [orm_xo].[restore_init_tables]
	@cutoff datetimeoffset(7) = null
as
begin
begin try

  set nocount on;

    if [orm_meta].[check_context]('restore init backups') <> 1
	begin             -- (NOTE: when setting master ON, interlock automatically turns on!)
		;throw 51000, 'Can not dump from stored init - set restore interlock.', 1;
	end

  set identity_insert [orm_meta].[templates] on

  	merge into [orm_meta].[templates] as d 
  		using [orm_xo].[init_templates] as s
  			on d.template_guid = s.template_guid
  	when not matched then
		insert (  template_id, template_guid,   name,   no_auto_view,   signature)
		values (s.template_id, template_guid, s.name, s.no_auto_view, s.signature)
  	when matched then 
		update set 
		--	template_id = s.template_id -- this can't be updated since it's the table's PK
			name         = s.name
		,	no_auto_view = s.no_auto_view
		,	signature    = s.signature
  	;

  set identity_insert [orm_meta].[templates] off


  	merge into [orm_meta].[inheritance] as d
  		using [orm_xo].[init_inheritance] as s
  			on d.parent_template_guid = s.parent_template_guid
  			and d.child_template_guid = d.child_template_guid
  	when not matched then
  		insert (  parent_template_guid,   child_template_guid,   ordinal)
  		values (s.parent_template_guid, s.child_template_guid, s.ordinal)
  	when matched then
  		update set
  			ordinal = s.ordinal
  	;


--  set identity_insert [orm_meta].[properties] on

  	merge into [orm_meta].[properties] as d
  		using [orm_xo].[init_properties] as s
  			on d.property_guid = s.property_guid
  	when not matched then
		insert (  property_guid,   template_guid,   name,   datatype_guid,   is_extended,   no_history,   signature)
		values (s.property_guid, s.template_guid, s.name, s.datatype_guid, s.is_extended, s.no_history, s.signature)
	when matched then
		update set
			template_guid = s.template_guid
		,	name          = s.name
		,	datatype_guid = s.datatype_guid
		,	is_extended   = s.is_extended
		,	no_history    = s.no_history
		,	signature     = s.signature
	;

--  set identity_insert [orm_meta].[properties] off

end try
begin catch
	-- clear the purge setup for safety reasons
	exec [orm_meta].[apply_context] 'restore init backups', 0
	exec [orm_meta].[handle_error] @@PROCID

end catch
end
go



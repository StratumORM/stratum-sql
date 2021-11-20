print '
Generating template dynamic view triggers...'


IF OBJECT_ID('[orm_meta].[generate_template_view_triggers]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[generate_template_view_triggers]
go


create procedure [orm_meta].[generate_template_view_triggers]
	@template_guid uniqueidentifier
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	declare @message                  nvarchar(255)
		,	@string_columns           nvarchar(max)
		,	@integer_columns          nvarchar(max)
		,	@decimal_columns          nvarchar(max)
		,	@datetime_columns         nvarchar(max)
		,	@instance_columns         nvarchar(max)

		,	@action_check             nvarchar(20)

		,	@delete_trigger_sql       nvarchar(max)

		,	@update_trigger_sql       nvarchar(max)
		,	@update_merge_template    nvarchar(max)
		,	@update_merge             nvarchar(max)

		,	@insert_trigger_sql       nvarchar(max)
		,	@insert_merge_template    nvarchar(max)
		,	@insert_merge             nvarchar(max)

		,	@template_name            nvarchar(max)
		,	@template_name_quoted     nvarchar(max)
		,	@template_name_unquoted   nvarchar(max)
		,	@template_name_sanitized  nvarchar(max)

	set @template_name = (select top 1 name from [orm_meta].[templates] where template_guid = @template_guid)
	set @template_name_quoted = quotename(@template_name)
	set @template_name_unquoted = substring(@template_name_quoted, 2,len(@template_name_quoted)-2) -- remove the brackets
	set @template_name_sanitized = orm_meta.sanitize_string(@template_name_quoted)

	set @string_columns =	(	select quotename(name) + ',' 
								from [orm_meta].[properties] as p
								where	p.datatype_guid = 0x00000000000000000000000000000001 
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_guid = @template_guid 
								for xml path(''))

		if len(@string_columns) > 1
			set @string_columns = substring(@string_columns,1, len(@string_columns)-1)
		else
			set @string_columns = ''

	set @integer_columns =	(	select quotename(name) + ',' 
								from [orm_meta].[properties] as p
								where	p.datatype_guid = 0x00000000000000000000000000000002
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_guid = @template_guid 
								for xml path(''))

		if len(@integer_columns) > 1
			set @integer_columns = substring(@integer_columns,1, len(@integer_columns)-1)
		else
			set @integer_columns = ''

	set @decimal_columns =	(	select quotename(name) + ',' 
								from [orm_meta].[properties] as p
								where	p.datatype_guid = 0x00000000000000000000000000000003
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_guid = @template_guid 
								for xml path(''))

		if len(@decimal_columns) > 1
			set @decimal_columns = substring(@decimal_columns,1, len(@decimal_columns)-1)
		else
			set @decimal_columns = ''

	set @datetime_columns =	(	select quotename(name) + ',' 
								from [orm_meta].[properties] as p
								where	p.datatype_guid = 0x00000000000000000000000000000004
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_guid = @template_guid 
								for xml path(''))
		
		if len(@datetime_columns) > 1
			set @datetime_columns = substring(@datetime_columns,1, len(@datetime_columns)-1)
		else
			set @datetime_columns = ''

	set @instance_columns =	(	select quotename(name) + ',' 
								from [orm_meta].[properties] as p
								where   p.datatype_guid > 0x00000000000000000000000000000004
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_guid = @template_guid 
								for xml path(''))
		
		if len(@instance_columns) > 1
			set @instance_columns = substring(@instance_columns,1, len(@instance_columns)-1)
		else
			set @instance_columns = ''


	-- delete trigger
	-- @@@_ACTION_CHECK_@@@
	-- @@@_META_TEMPLATE_NAME_@@@
	-- @@@_META_TEMPLATE_GUID_@@@
	IF OBJECT_ID('trigger_orm_meta_view_' + @template_name_sanitized + '_delete', 'TR') IS NOT NULL
		set @action_check = 'alter'
	else
		set @action_check = 'create'

	set @delete_trigger_sql = '
		@@@_ACTION_CHECK_@@@ trigger trigger_orm_meta_view_@@@_META_TEMPLATE_NAME_SANITIZED_@@@_delete
			on [dbo].@@@_META_TEMPLATE_NAME_@@@
			instead of delete
		as 
		begin
		begin try
		begin transaction

		  set nocount on; set xact_abort on;

			declare @template_guid uniqueidentifier
				set @template_guid = ''@@@_META_TEMPLATE_GUID_@@@''

			delete omi
			from [orm_meta].[instances] as omi
				inner join deleted as d
					on d.Instance_guid = omi.instance_guid
		
		  commit transaction
		
		end try
		begin catch
			exec [orm_meta].[handle_error] @@PROCID
		end catch
		end
	'
	set @delete_trigger_sql = replace(@delete_trigger_sql, '@@@_ACTION_CHECK_@@@', @action_check)
	set @delete_trigger_sql = replace(@delete_trigger_sql, '@@@_META_TEMPLATE_NAME_@@@', @template_name_quoted)
	set @delete_trigger_sql = replace(@delete_trigger_sql, '@@@_META_TEMPLATE_NAME_SANITIZED_@@@', @template_name_sanitized)
	set @delete_trigger_sql = replace(@delete_trigger_sql, '@@@_META_TEMPLATE_GUID_@@@', @template_guid)


	-- update trigger
	-- @@@_ACTION_CHECK_@@@
	-- @@@_META_TEMPLATE_NAME_@@@
	-- @@@_META_TEMPLATE_NAME_UNQUOTED_@@@
	-- @@@_META_TEMPLATE_GUID_@@@
	IF OBJECT_ID('trigger_orm_meta_view_' + @template_name_sanitized + '_update', 'TR') IS NOT NULL
		set @action_check = 'alter'
	else
		set @action_check = 'create'

	set @update_trigger_sql = '
		@@@_ACTION_CHECK_@@@ trigger trigger_orm_meta_view_@@@_META_TEMPLATE_NAME_SANITIZED_@@@_update
			on [dbo].@@@_META_TEMPLATE_NAME_@@@
			instead of update
		as 
		begin
		begin try
		begin transaction

		  set nocount on; set xact_abort on;

			declare @template_guid uniqueidentifier
				set @template_guid = ''@@@_META_TEMPLATE_GUID_@@@''

			-- This will be useful later on for smarter filtering
			declare @updated_columns table (column_name varchar(100), property_guid uniqueidentifier)
				insert into @updated_columns (column_name, property_guid)
				select ducb.COLUMN_NAME, p.property_guid
				from [orm_meta].[decode_updated_columns_bitmask]( columns_updated(), ''@@@_META_TEMPLATE_NAME_UNQUOTED_@@@'' ) as ducb
					inner join [orm_meta].[properties] as p
						on p.name = ducb.COLUMN_NAME
				where p.template_guid = @template_guid

			if (update(instance_guid))
				begin
					;throw 51000, ''The instance id and guid can not be written (for internal use only). Simply remove it from the update statement.'', 5;
				end

			-- fix the instance names before doing anything else
			if (columns_updated() & 1) = 1
				begin
					update omi 
					set omi.name = ins.instance_name
					from [orm_meta].[instances] as omi
						inner join inserted as ins 
							on omi.instance_guid = ins.instance_guid
				end	

			-- Rotate the table to prep for merging into the values tables
			-- Note we will need an unpivot for each of the four main types
	'

	set @update_trigger_sql = replace(@update_trigger_sql,'@@@_ACTION_CHECK_@@@', @action_check)
	set @update_trigger_sql = replace(@update_trigger_sql, '@@@_META_TEMPLATE_NAME_@@@', @template_name_quoted)
	set @update_trigger_sql = replace(@update_trigger_sql, '@@@_META_TEMPLATE_NAME_UNQUOTED_@@@', @template_name_unquoted)
	set @update_trigger_sql = replace(@update_trigger_sql, '@@@_META_TEMPLATE_NAME_SANITIZED_@@@', @template_name_sanitized)
	set @update_trigger_sql = replace(@update_trigger_sql,'@@@_META_TEMPLATE_GUID_@@@', @template_guid)

	set @update_merge_template = '
		------------------------------------
		--	@@@_BASE_TYPE_@@@
		------------------------------------
		begin try

		;with updated_values as
		(
			select	instance_name
			,	property_name
			,	value
			,	instances.instance_guid
			,	properties.property_guid
			from inserted unpivot
					(	value
						for property_name 
						in (@@@_TYPE_COLUMNS_@@@)
					) unpivoted
				inner join [orm_meta].[properties] as properties
					on unpivoted.property_name = properties.name
				inner join [orm_meta].[instances] as instances
					on unpivoted.Instance_name = instances.name
			where properties.template_guid = @template_guid
				and properties.datatype_guid @@@_BASE_DATATYPE_GUID_FILTER_@@@
				and instances.template_guid = @template_guid
		)
		-- UNPIVOT will not include the NULLs, so we need to add them back
		,	possible_values as
		(
			select NULL as value
				,	i.instance_guid
				,	uc.property_guid
			from inserted as i
				cross join @updated_columns as uc
		)
		,	update_set as
		(
			select	uv.value
				,	pv.instance_guid
				,	pv.property_guid
			from possible_values as pv
				left join updated_values as uv
					on  pv.instance_guid = uv.instance_guid
					and pv.property_guid = uv.property_guid
		)
		merge into [orm_meta].[values_@@@_BASE_TYPE_@@@] as d
		using update_set as s
			on	d.instance_guid = s.instance_guid
			and	d.property_guid = s.property_guid
		when not matched and (s.value is not null) then
			insert (  instance_guid,   property_guid,   value)
			values (s.instance_guid, s.property_guid, s.value)
		when matched and (s.value is null) then
			delete
		when matched and (not s.value is null) then
			update
			set d.value = s.value
		;

		end try
		begin catch
			exec [orm_meta].[handle_error] ''trigger_orm_meta_view_@@@_META_TEMPLATE_NAME_SANITIZED_@@@_update: @@@_BASE_TYPE_@@@'', null
		end catch
	'

	set @update_merge_template = replace(@update_merge_template, '@@@_META_TEMPLATE_NAME_SANITIZED_@@@', @template_name_sanitized)

	-- string
	if @string_columns <> ''
	begin
		set @update_merge = replace(@update_merge_template,'@@@_BASE_TYPE_@@@', 'string')
		set @update_merge = replace(@update_merge,'@@@_TYPE_COLUMNS_@@@', @string_columns)
		set @update_merge = replace(@update_merge,'@@@_BASE_DATATYPE_GUID_FILTER_@@@', ' = 0x00000000000000000000000000000001')

		set @update_trigger_sql = @update_trigger_sql + @update_merge
	end

	-- integers
	if @integer_columns <> ''
	begin
		set @update_merge = replace(@update_merge_template,'@@@_BASE_TYPE_@@@', 'integer')
		set @update_merge = replace(@update_merge,'@@@_TYPE_COLUMNS_@@@', @integer_columns)
		set @update_merge = replace(@update_merge,'@@@_BASE_DATATYPE_GUID_FILTER_@@@', ' = 0x00000000000000000000000000000002')

		set @update_trigger_sql = @update_trigger_sql + @update_merge
	end

	-- decimals
	if @decimal_columns <> ''
	begin
		set @update_merge = replace(@update_merge_template,'@@@_BASE_TYPE_@@@', 'decimal')
		set @update_merge = replace(@update_merge,'@@@_TYPE_COLUMNS_@@@', @decimal_columns)
		set @update_merge = replace(@update_merge,'@@@_BASE_DATATYPE_GUID_FILTER_@@@', ' = 0x00000000000000000000000000000003')

		set @update_trigger_sql = @update_trigger_sql + @update_merge
	end

	-- datetime
	if @datetime_columns <> ''
	begin
		set @update_merge = replace(@update_merge_template,'@@@_BASE_TYPE_@@@', 'datetime')
		set @update_merge = replace(@update_merge,'@@@_TYPE_COLUMNS_@@@', @datetime_columns)
		set @update_merge = replace(@update_merge,'@@@_BASE_DATATYPE_GUID_FILTER_@@@', ' = 0x00000000000000000000000000000004')

		set @update_trigger_sql = @update_trigger_sql + @update_merge
	end

	-- instances
	if @instance_columns <> ''
	begin

		set @update_merge = replace(@update_merge_template,'@@@_BASE_TYPE_@@@', 'instance')
		set @update_merge = replace(@update_merge,'@@@_TYPE_COLUMNS_@@@', @instance_columns)
		set @update_merge = replace(@update_merge,'@@@_BASE_DATATYPE_GUID_FILTER_@@@', ' > 0x00000000000000000000000000000004')

		set @update_trigger_sql = @update_trigger_sql + @update_merge
	end

	set @update_trigger_sql = @update_trigger_sql + '
	
	  commit transaction

	end try
	begin catch
		exec [orm_meta].[handle_error] @@PROCID
	end catch
	end
	'


	-- insert trigger
	-- @@@_ACTION_CHECK_@@@
	-- @@@_META_TEMPLATE_NAME_@@@
	-- @@@_META_TEMPLATE_GUID_@@@
	IF OBJECT_ID('trigger_orm_meta_view_' + @template_name_sanitized + '_insert', 'TR') IS NOT NULL
		set @action_check = 'alter'
	else
		set @action_check = 'create'

	set @insert_trigger_sql = '
	@@@_ACTION_CHECK_@@@ trigger trigger_orm_meta_view_@@@_META_TEMPLATE_NAME_SANITIZED_@@@_insert
		on [dbo].@@@_META_TEMPLATE_NAME_@@@
		instead of insert
	as 
	begin
	begin try
	begin transaction

	  set nocount on; set xact_abort on;
	
		declare @template_guid uniqueidentifier
			set @template_guid = ''@@@_META_TEMPLATE_GUID_@@@''

		-- if there is no specific instances being inserted, raise an error (there is nothing to attach values to!)
		if (columns_updated() & 1) = 0
			begin
				;throw 51000, ''Can not insert without an instance to attach values to.'', 5;
			end

		-- verify that all the instances does not already exist (this aint an update statement!)
		if (exists(	select ins.instance_name
					from inserted as ins
						inner join [orm_meta].[instances] as omi
							on ins.instance_name = omi.name
					where omi.template_guid = @template_guid))
			begin
				;throw 51000, ''Can not insert duplicate Instance_name (new instances should be added via an insert).'', 5;
			end

		-- Add any instances not yet tracked in the instance table
		merge into [orm_meta].[instances] as d
		using (	select instance_name as name
				from inserted	) as s 
		on d.name = s.name
		when not matched then
			insert ( template_guid,   name)
			values (@template_guid, s.name)
		;

		-- Rotate the table to prep for merging into the values tables
		-- Note we will need an unpivot for each of the four main types
				
		-- Also note: we want to raise an error if we attempt to insert an already set
		-- value, so on a match we will insert an invalid record (violates a primary key)
		-- and add our own error message
	'

	set @insert_trigger_sql = replace(@insert_trigger_sql,'@@@_ACTION_CHECK_@@@', @action_check)
	set @insert_trigger_sql = replace(@insert_trigger_sql, '@@@_META_TEMPLATE_NAME_@@@', @template_name_quoted)
	set @insert_trigger_sql = replace(@insert_trigger_sql, '@@@_META_TEMPLATE_NAME_SANITIZED_@@@', @template_name_sanitized)
	set @insert_trigger_sql = replace(@insert_trigger_sql,'@@@_META_TEMPLATE_GUID_@@@', @template_guid)


	set @insert_merge_template = '
		------------------------------------
		--	@@@_BASE_TYPE_@@@
		------------------------------------
		begin try
				
			;with insert_values as
			(
				select	instance_name
				,	property_name
				,	value
				,	instances.instance_guid
				,	properties.property_guid
				from inserted unpivot
						(	value
							for property_name in (@@@_TYPE_COLUMNS_@@@)
						) unpivoted
					inner join [orm_meta].[properties] as properties
						on unpivoted.property_name = properties.name
					inner join [orm_meta].[instances] as instances
						on unpivoted.Instance_name = instances.name
				where properties.template_guid = @template_guid
					and properties.datatype_guid @@@_BASE_DATATYPE_GUID_FILTER_@@@
					and instances.template_guid = @template_guid
					and value is not null
			)
			merge into [orm_meta].[values_@@@_BASE_TYPE_@@@] as d
			using (	select	instance_guid
						,	property_guid
						,	value
					from insert_values	) as s
				on	d.instance_guid = s.instance_guid
				and	d.property_guid = s.property_guid
			when not matched then
				insert (  instance_guid,   property_guid,   value)
				values (s.instance_guid, s.property_guid, s.value)
			when matched then -- throw error!
				update
				set d.value = convert(nvarchar(max), d.value) + convert(nvarchar(max), 0/0)
			;

		end try
		begin catch
			exec [orm_meta].[handle_error] ''trigger_orm_meta_view_@@@_META_TEMPLATE_NAME_SANITIZED_@@@_insert: @@@_BASE_TYPE_@@@'', null
		end catch
	'

		set @insert_merge_template = replace(@insert_merge_template, '@@@_META_TEMPLATE_NAME_SANITIZED_@@@', @template_name_sanitized)

	-- string
	if @string_columns <> ''
	begin
		set @insert_merge = replace(@insert_merge_template,'@@@_BASE_TYPE_@@@', 'string')
		set @insert_merge = replace(@insert_merge,'@@@_TYPE_COLUMNS_@@@', @string_columns)
		set @insert_merge = replace(@insert_merge,'@@@_BASE_DATATYPE_GUID_FILTER_@@@', ' = 0x00000000000000000000000000000001')

		set @insert_trigger_sql = @insert_trigger_sql + @insert_merge
	end

	-- integers
	if @integer_columns <> ''
	begin
		set @insert_merge = replace(@insert_merge_template,'@@@_BASE_TYPE_@@@', 'integer')
		set @insert_merge = replace(@insert_merge,'@@@_TYPE_COLUMNS_@@@', @integer_columns)
		set @insert_merge = replace(@insert_merge,'@@@_BASE_DATATYPE_GUID_FILTER_@@@', ' = 0x00000000000000000000000000000002')

		set @insert_trigger_sql = @insert_trigger_sql + @insert_merge
	end

	-- decimal
	if @decimal_columns <> ''
	begin
		set @insert_merge = replace(@insert_merge_template,'@@@_BASE_TYPE_@@@', 'decimal')
		set @insert_merge = replace(@insert_merge,'@@@_TYPE_COLUMNS_@@@', @decimal_columns)
		set @insert_merge = replace(@insert_merge,'@@@_BASE_DATATYPE_GUID_FILTER_@@@', ' = 0x00000000000000000000000000000003')

		set @insert_trigger_sql = @insert_trigger_sql + @insert_merge
	end

	-- datetime
	if @datetime_columns <> ''
	begin
		set @insert_merge = replace(@insert_merge_template,'@@@_BASE_TYPE_@@@', 'datetime')
		set @insert_merge = replace(@insert_merge,'@@@_TYPE_COLUMNS_@@@', @datetime_columns)
		set @insert_merge = replace(@insert_merge,'@@@_BASE_DATATYPE_GUID_FILTER_@@@', ' = 0x00000000000000000000000000000004')

		set @insert_trigger_sql = @insert_trigger_sql + @insert_merge
	end
	
	-- instances
	if @instance_columns <> ''
	begin

		set @insert_merge = replace(@insert_merge_template,'@@@_BASE_TYPE_@@@', 'instance')
		set @insert_merge = replace(@insert_merge,'@@@_TYPE_COLUMNS_@@@', @instance_columns)
		set @insert_merge = replace(@insert_merge,'@@@_BASE_DATATYPE_GUID_FILTER_@@@', ' > 0x00000000000000000000000000000004')

		set @insert_trigger_sql = @insert_trigger_sql + @insert_merge
	end

	set @insert_trigger_sql = @insert_trigger_sql + '
	
	  commit transaction

	end try
	begin catch
		exec [orm_meta].[handle_error] @@PROCID
	end catch
	end
	'
	
	begin try
	begin transaction generate_triggers

		-- Apply the templates
		exec sp_executesql @delete_trigger_sql
		exec sp_executesql @update_trigger_sql
		exec sp_executesql @insert_trigger_sql

		commit transaction generate_triggers

	end try
	begin catch
		set @message = 'Generating (' + @action_check + ') the template triggers failed for ' + @template_name_quoted
		exec [orm_meta].[handle_error] @message
	end catch
	
  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go

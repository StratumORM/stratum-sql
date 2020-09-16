print '
Generating template dynamic view triggers...'


IF OBJECT_ID('[orm_meta].[generate_template_view_triggers]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[generate_template_view_triggers]
go


create procedure [orm_meta].[generate_template_view_triggers]
	@template_id int
as
begin

	declare @string_columns nvarchar(max)
		,	@integer_columns nvarchar(max)
		,	@decimal_columns nvarchar(max)
		,	@datetime_columns nvarchar(max)
		,	@instance_columns nvarchar(max)

		,	@action_check nvarchar(20)

		,	@delete_trigger_sql nvarchar(max)

		,	@update_trigger_sql nvarchar(max)
		,	@update_merge_template nvarchar(max)
		,	@update_merge nvarchar(max)

		,	@insert_trigger_sql nvarchar(max)
		,	@insert_merge_template nvarchar(max)
		,	@insert_merge nvarchar(max)

		,	@template_name varchar(250)
		,	@template_name_quoted varchar(250)
		,	@template_name_unquoted varchar(250)
		,	@template_name_sanitized varchar(250)

	set @template_name = (select top 1 name from [orm_meta].[templates] where template_id = @template_id)
	set @template_name_quoted = QUOTENAME(@template_name)
	set @template_name_unquoted = substring(@template_name_quoted, 2,len(@template_name_quoted)-2) -- remove the brackets
	set @template_name_sanitized = orm_meta.sanitize_string(@template_name_quoted)

	set @string_columns =	(	select QUOTENAME(name) + ',' 
								from [orm_meta].[properties] as p
								where	p.datatype_id = 1 
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_id = @template_id 
								for xml path(''))

		if len(@string_columns) > 1
			set @string_columns = substring(@string_columns,1, len(@string_columns)-1)
		else
			set @string_columns = ''

	set @integer_columns =	(	select QUOTENAME(name) + ',' 
								from [orm_meta].[properties] as p
								where	p.datatype_id = 2 
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_id = @template_id 
								for xml path(''))

		if len(@integer_columns) > 1
			set @integer_columns = substring(@integer_columns,1, len(@integer_columns)-1)
		else
			set @integer_columns = ''

	set @decimal_columns =	(	select QUOTENAME(name) + ',' 
								from [orm_meta].[properties] as p
								where	p.datatype_id = 3 
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_id = @template_id 
								for xml path(''))

		if len(@decimal_columns) > 1
			set @decimal_columns = substring(@decimal_columns,1, len(@decimal_columns)-1)
		else
			set @decimal_columns = ''

	set @datetime_columns =	(	select QUOTENAME(name) + ',' 
								from [orm_meta].[properties] as p
								where	p.datatype_id = 4
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_id = @template_id 
								for xml path(''))
		
		if len(@datetime_columns) > 1
			set @datetime_columns = substring(@datetime_columns,1, len(@datetime_columns)-1)
		else
			set @datetime_columns = ''

	set @instance_columns =	(	select QUOTENAME(name) + ',' 
								from [orm_meta].[properties] as p
								where	not p.datatype_id in (1,2,3,4)
									and (p.is_extended is NULL or p.is_extended = 0) 
									and p.template_id = @template_id 
								for xml path(''))


	-- delete trigger
	-- @@@_ACTION_CHECK_@@@
	-- @@@_META_TEMPLATE_NAME_@@@
	-- @@@_META_TEMPLATE_ID_@@@
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
			declare @template_id int
				set @template_id = @@@_META_TEMPLATE_ID_@@@

			delete omi
			from [orm_meta].[instances] as omi
				inner join deleted as d
					on d.Instance_id = omi.instance_id
		end
	'
	set @delete_trigger_sql = replace(@delete_trigger_sql, '@@@_ACTION_CHECK_@@@', @action_check)
	set @delete_trigger_sql = replace(@delete_trigger_sql, '@@@_META_TEMPLATE_NAME_@@@', @template_name_quoted)
	set @delete_trigger_sql = replace(@delete_trigger_sql, '@@@_META_TEMPLATE_NAME_SANITIZED_@@@', @template_name_sanitized)
	set @delete_trigger_sql = replace(@delete_trigger_sql, '@@@_META_TEMPLATE_ID_@@@', @template_id)


	-- update trigger
	-- @@@_ACTION_CHECK_@@@
	-- @@@_META_TEMPLATE_NAME_@@@
	-- @@@_META_TEMPLATE_NAME_UNQUOTED_@@@
	-- @@@_META_TEMPLATE_ID_@@@
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
			
			declare @template_id int
				set @template_id = @@@_META_TEMPLATE_ID_@@@

			-- This will be useful later on for smarter filtering
			declare @updated_columns table (column_name varchar(100), property_id int)
				insert into @updated_columns (column_name, property_id)
				select ducb.COLUMN_NAME, p.property_id
				from [orm_meta].[decode_updated_columns_bitmask]( columns_updated(), ''@@@_META_TEMPLATE_NAME_UNQUOTED_@@@'' ) as ducb
					inner join [orm_meta].[properties] as p
						on p.name = ducb.COLUMN_NAME
				where p.template_id = @template_id

			if (update(Instance_id))
				begin	
					rollback transaction	
					raiserror(''The Instance_id can not be written (for internal use only). Simply remove it from the update statement.'', 16, 5)
					return
				end	

			-- fix the instance names before doing anything else
			if (columns_updated() & 1) = 1
				begin
					update omi 
					set omi.name = ins.Instance_name
					from [orm_meta].[instances] as omi
						inner join inserted as ins 
							on omi.instance_id = ins.Instance_id
				end	

			-- Rotate the table to prep for merging into the values tables
			-- Note we will need an unpivot for each of the four main types
	'

	set @update_trigger_sql = replace(@update_trigger_sql,'@@@_ACTION_CHECK_@@@', @action_check)
	set @update_trigger_sql = replace(@update_trigger_sql, '@@@_META_TEMPLATE_NAME_@@@', @template_name_quoted)
	set @update_trigger_sql = replace(@update_trigger_sql, '@@@_META_TEMPLATE_NAME_UNQUOTED_@@@', @template_name_unquoted)
	set @update_trigger_sql = replace(@update_trigger_sql, '@@@_META_TEMPLATE_NAME_SANITIZED_@@@', @template_name_sanitized)
	set @update_trigger_sql = replace(@update_trigger_sql,'@@@_META_TEMPLATE_ID_@@@', @template_id)

	set @update_merge_template = '
		------------------------------------
		--	@@@_BASE_TYPE_@@@
		------------------------------------
		;with updated_values as
		(
			select	instance_name
			,	property_name
			,	value
			,	instances.instance_id
			,	properties.property_id
			from inserted unpivot
					(	value
						for property_name 
						in (@@@_TYPE_COLUMNS_@@@)
					) unpivoted
				inner join [orm_meta].[properties] as properties
					on unpivoted.property_name = properties.name
				inner join [orm_meta].[instances] as instances
					on unpivoted.Instance_name = instances.name
			where properties.template_id = @template_id
				and properties.datatype_id @@@_BASE_DATATYPE_ID_FILTER_@@@
				and instances.template_id = @template_id
		)
		-- UNPIVOT will not include the NULLs, so we need to add them back
		,	possible_values as
		(
			select NULL as value
				,	i.Instance_id
				,	uc.property_id
			from inserted as i
				cross join @updated_columns as uc
		)
		,	update_set as
		(
			select	uv.value
				,	pv.Instance_id
				,	pv.property_id
			from possible_values as pv
				left join updated_values as uv
					on pv.Instance_id = uv.instance_id
					and pv.property_id = uv.property_id
		)
		merge into [orm_meta].[values_@@@_BASE_TYPE_@@@] as d
		using update_set as s
			on	d.instance_id = s.instance_id
			and	d.property_id = s.property_id
		when not matched and (s.value is not null) then
			insert (instance_id, property_id, value)
			values (s.instance_id, s.property_id, s.value)
		when matched and (s.value is null) then
			delete
		when matched and (not s.value is null) then
			update
			set d.value = s.value
		;
	'

	-- string
	if @string_columns <> ''
	begin
		set @update_merge = replace(@update_merge_template,'@@@_BASE_TYPE_@@@', 'string')
		set @update_merge = replace(@update_merge,'@@@_TYPE_COLUMNS_@@@', @string_columns)
		set @update_merge = replace(@update_merge,'@@@_BASE_DATATYPE_ID_FILTER_@@@', ' = 1')

		set @update_trigger_sql = @update_trigger_sql + @update_merge
	end

	-- integers
	if @integer_columns <> ''
	begin
		set @update_merge = replace(@update_merge_template,'@@@_BASE_TYPE_@@@', 'integer')
		set @update_merge = replace(@update_merge,'@@@_TYPE_COLUMNS_@@@', @integer_columns)
		set @update_merge = replace(@update_merge,'@@@_BASE_DATATYPE_ID_FILTER_@@@', ' = 2')

		set @update_trigger_sql = @update_trigger_sql + @update_merge
	end

	-- decimals
	if @decimal_columns <> ''
	begin
		set @update_merge = replace(@update_merge_template,'@@@_BASE_TYPE_@@@', 'decimal')
		set @update_merge = replace(@update_merge,'@@@_TYPE_COLUMNS_@@@', @decimal_columns)
		set @update_merge = replace(@update_merge,'@@@_BASE_DATATYPE_ID_FILTER_@@@', ' = 3')

		set @update_trigger_sql = @update_trigger_sql + @update_merge
	end

	-- datetime
	if @datetime_columns <> ''
	begin
		set @update_merge = replace(@update_merge_template,'@@@_BASE_TYPE_@@@', 'datetime')
		set @update_merge = replace(@update_merge,'@@@_TYPE_COLUMNS_@@@', @datetime_columns)
		set @update_merge = replace(@update_merge,'@@@_BASE_DATATYPE_ID_FILTER_@@@', ' = 4')

		set @update_trigger_sql = @update_trigger_sql + @update_merge
	end

	-- instances
	if @instance_columns <> ''
	begin

		set @update_merge = replace(@update_merge_template,'@@@_BASE_TYPE_@@@', 'instances')
		set @update_merge = replace(@update_merge,'@@@_TYPE_COLUMNS_@@@', @instance_columns)
		set @update_merge = replace(@update_merge,'@@@_BASE_DATATYPE_ID_FILTER_@@@', ' > 4')

		set @update_trigger_sql = @update_trigger_sql + @update_merge
	end

	set @update_trigger_sql = @update_trigger_sql + '
	end
	'


	-- insert trigger
	-- @@@_ACTION_CHECK_@@@
	-- @@@_META_TEMPLATE_NAME_@@@
	-- @@@_META_TEMPLATE_ID_@@@
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

		declare @template_id int
			set @template_id = @@@_META_TEMPLATE_ID_@@@

		-- if there is no specific instances being inserted, raise an error (there is nothing to attach values to!)
		if (columns_updated() & 1) = 0
			begin	
				rollback transaction	
				raiserror(''Can not insert without an instance to attach values to.'', 16, 5)
				return
			end	

		-- verify that all the instances does not already exist (this aint an update statement!)
		if (exists(	select ins.instance_name
					from inserted as ins
						inner join [orm_meta].[instances] as omi
							on ins.Instance_name = omi.name
					where omi.template_id = @template_id))
			begin	
				rollback transaction	
				raiserror(''Can not insert duplicate Instance_name (new instances should be added via an insert).'', 16, 5)
				return
			end	

		-- Add any instances not yet tracked in the instance table
		merge into [orm_meta].[instances] as d
		using (	select instance_name as name
				from inserted	) as s 
		on d.name = s.name
		when not matched then
			insert (template_id, name)
			values (@template_id, s.name)
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
	set @insert_trigger_sql = replace(@insert_trigger_sql,'@@@_META_TEMPLATE_ID_@@@', @template_id)


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
				,	instances.instance_id
				,	properties.property_id
				from inserted unpivot
						(	value
							for property_name in (@@@_TYPE_COLUMNS_@@@)
						) unpivoted
					inner join [orm_meta].[properties] as properties
						on unpivoted.property_name = properties.name
					inner join [orm_meta].[instances] as instances
						on unpivoted.Instance_name = instances.name
				where properties.template_id = @template_id
					and properties.datatype_id @@@_BASE_DATATYPE_ID_FILTER_@@@
					and instances.template_id = @template_id
					and value is not null
			)
			merge into [orm_meta].[values_@@@_BASE_TYPE_@@@] as d
			using (	select	instance_id
						,	property_id
						,	value
					from insert_values	) as s
				on	d.instance_id = s.instance_id
				and	d.property_id = s.property_id
			when not matched then
				insert (instance_id, property_id, value)
				values (s.instance_id, s.property_id, s.value)
			when matched then
				update
				set d.value = d.value + convert(nvarchar(max), 0/0)
			;

		end try
		begin catch
			rollback transaction	
			raiserror(''Can not insert over an existing value. Use update instead.'', 16, 5)
			return
		end catch
	'

	-- string
	if @string_columns <> ''
	begin
		set @insert_merge = replace(@insert_merge_template,'@@@_BASE_TYPE_@@@', 'string')
		set @insert_merge = replace(@insert_merge,'@@@_TYPE_COLUMNS_@@@', @string_columns)
		set @insert_merge = replace(@insert_merge,'@@@_BASE_DATATYPE_ID_FILTER_@@@', ' = 1')

		set @insert_trigger_sql = @insert_trigger_sql + @insert_merge
	end

	-- integers
	if @integer_columns <> ''
	begin
		set @insert_merge = replace(@insert_merge_template,'@@@_BASE_TYPE_@@@', 'integer')
		set @insert_merge = replace(@insert_merge,'@@@_TYPE_COLUMNS_@@@', @integer_columns)
		set @insert_merge = replace(@insert_merge,'@@@_BASE_DATATYPE_ID_FILTER_@@@', ' = 2')

		set @insert_trigger_sql = @insert_trigger_sql + @insert_merge
	end

	-- decimal
	if @decimal_columns <> ''
	begin
		set @insert_merge = replace(@insert_merge_template,'@@@_BASE_TYPE_@@@', 'decimal')
		set @insert_merge = replace(@insert_merge,'@@@_TYPE_COLUMNS_@@@', @decimal_columns)
		set @insert_merge = replace(@insert_merge,'@@@_BASE_DATATYPE_ID_FILTER_@@@', ' = 3')

		set @insert_trigger_sql = @insert_trigger_sql + @insert_merge
	end

	-- datetime
	if @datetime_columns <> ''
	begin
		set @insert_merge = replace(@insert_merge_template,'@@@_BASE_TYPE_@@@', 'datetime')
		set @insert_merge = replace(@insert_merge,'@@@_TYPE_COLUMNS_@@@', @datetime_columns)
		set @insert_merge = replace(@insert_merge,'@@@_BASE_DATATYPE_ID_FILTER_@@@', ' = 4')

		set @insert_trigger_sql = @insert_trigger_sql + @insert_merge
	end
	
	-- instances
	if @instance_columns <> ''
	begin

		set @insert_merge = replace(@insert_merge_template,'@@@_BASE_TYPE_@@@', 'instances')
		set @insert_merge = replace(@insert_merge,'@@@_TYPE_COLUMNS_@@@', @instance_columns)
		set @insert_merge = replace(@insert_merge,'@@@_BASE_DATATYPE_ID_FILTER_@@@', ' > 4')

		set @insert_trigger_sql = @insert_trigger_sql + @insert_merge
	end

	set @insert_trigger_sql = @insert_trigger_sql + '
	end
	'
	
	--begin transaction generate_triggers
	--begin try

		-- Apply the templates
		exec sp_executesql @delete_trigger_sql
		exec sp_executesql @update_trigger_sql
		exec sp_executesql @insert_trigger_sql

	--	commit transaction generate_triggers

	--end try
	--begin catch
	--	rollback transaction generate_triggers
	--	raiserror('Generating the template triggers failed.', 16, 5)
	--	return
	--end catch
end
go

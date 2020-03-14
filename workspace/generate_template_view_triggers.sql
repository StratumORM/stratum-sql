print '
Generating template dynamic view triggers...'


IF OBJECT_ID('[dbo].[orm_meta_generate_template_view_triggers]', 'P') IS NOT NULL
	DROP PROCEDURE [dbo].orm_meta_generate_template_view_triggers
go


create procedure [dbo].[orm_meta_generate_template_view_triggers]
	@templateID int
as
begin

	declare @stringColumns nvarchar(max)
		,	@integerColumns nvarchar(max)
		,	@decimalColumns nvarchar(max)
		,	@datetimeColumns nvarchar(max)
		,	@instanceColumns nvarchar(max)

		,	@actionCheck nvarchar(20)

		,	@deleteTriggerSQL nvarchar(max)

		,	@updateTriggerSQL nvarchar(max)
		,	@updateMergeTemplate nvarchar(max)
		,	@updateMerge nvarchar(max)

		,	@insertTriggerSQL nvarchar(max)
		,	@insertMergeTemplate nvarchar(max)
		,	@insertMerge nvarchar(max)

		,	@templateName varchar(250)

	set @templateName = (select top 1 name from orm_meta_templates where templateID = @templateID)

	set @stringColumns =	(	select '[' + name + '],' 
								from orm_meta_properties as p
								where	p.datatypeID = 1 
									and (p.isExtended is NULL or p.isExtended = 0) 
									and p.templateID = @templateID 
								for xml path(''))

		if len(@stringColumns) > 1
			set @stringColumns = substring(@stringColumns,1, len(@stringColumns)-1)
		else
			set @stringColumns = ''

	set @integerColumns =	(	select '[' + name + '],' 
								from orm_meta_properties as p
								where	p.datatypeID = 2 
									and (p.isExtended is NULL or p.isExtended = 0) 
									and p.templateID = @templateID 
								for xml path(''))

		if len(@integerColumns) > 1
			set @integerColumns = substring(@integerColumns,1, len(@integerColumns)-1)
		else
			set @integerColumns = ''

	set @decimalColumns =	(	select '[' + name + '],' 
								from orm_meta_properties as p
								where	p.datatypeID = 3 
									and (p.isExtended is NULL or p.isExtended = 0) 
									and p.templateID = @templateID 
								for xml path(''))

		if len(@decimalColumns) > 1
			set @decimalColumns = substring(@decimalColumns,1, len(@decimalColumns)-1)
		else
			set @decimalColumns = ''

	set @datetimeColumns =	(	select '[' + name + '],' 
								from orm_meta_properties as p
								where	p.datatypeID = 4
									and (p.isExtended is NULL or p.isExtended = 0) 
									and p.templateID = @templateID 
								for xml path(''))
		
		if len(@datetimeColumns) > 1
			set @datetimeColumns = substring(@datetimeColumns,1, len(@datetimecolumns)-1)
		else
			set @datetimeColumns = ''

	set @instanceColumns =	(	select '[' + name + '],' 
								from orm_meta_properties as p
								where	not p.datatypeID in (1,2,3,4)
									and (p.isExtended is NULL or p.isExtended = 0) 
									and p.templateID = @templateID 
								for xml path(''))


	-- delete trigger
	-- @@@_ACTION_CHECK_@@@
	-- @@@_META_TEMPLATE_NAME_@@@
	-- @@@_META_TEMPLATE_ID_@@@
	IF OBJECT_ID('dbo.trigger_orm_meta_view_' + @templateName + '_delete', 'TR') IS NOT NULL
		set @actionCheck = 'alter'
	else
		set @actionCheck = 'create'

	set @deleteTriggerSQL = '
		@@@_ACTION_CHECK_@@@ trigger trigger_orm_meta_view_@@@_META_TEMPLATE_NAME_@@@_delete
			on dbo.@@@_META_TEMPLATE_NAME_@@@
			instead of delete
		as 
		begin
			declare @templateID int
				set @templateID = @@@_META_TEMPLATE_ID_@@@

			delete omi
			from orm_meta_instances as omi
				inner join deleted as d
					on d.InstanceID = omi.instanceID
		end
	'
	set @deleteTriggerSQL = replace(@deleteTriggerSQL, '@@@_ACTION_CHECK_@@@', @actionCheck)
	set @deleteTriggerSQL = replace(@deleteTriggerSQL, '@@@_META_TEMPLATE_NAME_@@@', @templateName)
	set @deleteTriggerSQL = replace(@deleteTriggerSQL, '@@@_META_TEMPLATE_ID_@@@', @templateID)


	-- update trigger
	-- @@@_ACTION_CHECK_@@@
	-- @@@_META_TEMPLATE_NAME_@@@
	-- @@@_META_TEMPLATE_ID_@@@
	IF OBJECT_ID('dbo.trigger_orm_meta_view_' + @templateName + '_update', 'TR') IS NOT NULL
		set @actionCheck = 'alter'
	else
		set @actionCheck = 'create'

	set @updateTriggerSQL = '
		@@@_ACTION_CHECK_@@@ trigger trigger_orm_meta_view_@@@_META_TEMPLATE_NAME_@@@_update
			on dbo.@@@_META_TEMPLATE_NAME_@@@
			instead of update
		as 
		begin
			
			declare @templateID int
				set @templateID = @@@_META_TEMPLATE_ID_@@@

			-- This will be useful later on for smarter filtering
			declare @updatedColumns table (columnName varchar(100), propertyID int)
				insert into @updatedColumns (columnName, propertyID)
				select ducb.COLUMN_NAME, p.propertyID
				from orm_meta_decodeUpdatedColumnsBitmask( columns_updated(), ''@@@_META_TEMPLATE_NAME_@@@'' ) as ducb
					inner join orm_meta_properties as p
						on p.name = ducb.COLUMN_NAME
				where p.templateID = @templateID

			if (update(InstanceID))
				begin	
					rollback transaction	
					raiserror(''The InstanceID can not be written (for internal use only). Simply remove it from the update statement.'', 16, 5)
					return
				end	

			-- fix the instance names before doing anything else
			if (columns_updated() & 1) = 1
				begin
					update omi 
					set omi.name = ins.InstanceName
					from orm_meta_instances as omi
						inner join inserted as ins 
							on omi.instanceID = ins.InstanceID
				end	

			-- Rotate the table to prep for merging into the values tables
			-- Note we will need an unpivot for each of the four main types
	'

	set @updateTriggerSQL = replace(@updateTriggerSQL,'@@@_ACTION_CHECK_@@@', @actionCheck)
	set @updateTriggerSQL = replace(@updateTriggerSQL,'@@@_META_TEMPLATE_NAME_@@@', @templateName)
	set @updateTriggerSQL = replace(@updateTriggerSQL,'@@@_META_TEMPLATE_ID_@@@', @templateID)

	set @updateMergeTemplate = '
	------------------------------------
	--	@@@_BASE_TYPE_@@@
	------------------------------------
	;with updatedValues as
	(
		select	instanceName
		,	propertyName
		,	value
		,	instances.instanceID
		,	properties.propertyID
		from inserted unpivot
				(	value
					for propertyName 
					in (@@@_TYPE_COLUMNS_@@@)
				) unpivoted
			inner join orm_meta_properties as properties
				on unpivoted.propertyName = properties.name
			inner join orm_meta_instances as instances
				on unpivoted.InstanceName = instances.name
		where properties.templateID = @templateID
			and properties.datatypeID = @@@_BASE_DATATYPE_ID_@@@
			and instances.templateID = @templateID
	)
	-- UNPIVOT will not include the NULLs, so we need to add them back
	,	possibleValues as
	(
		select NULL as value
			,	i.InstanceID
			,	uc.propertyID
		from inserted as i
			cross join @updatedColumns as uc
	)
	,	updateSet as
	(
		select	uv.value
			,	pv.InstanceID
			,	pv.propertyID
		from possibleValues as pv
			left join updatedValues as uv
				on pv.InstanceID = uv.instanceID
				and pv.propertyID = uv.propertyID
	)
	merge into orm_meta_values_@@@_BASE_TYPE_@@@ as d
	using updateSet as s
		on	d.instanceID = s.instanceID
		and	d.propertyID = s.propertyID
	when not matched and (s.value is not null) then
		insert (instanceID, propertyID, value)
		values (s.instanceID, s.propertyID, s.value)
	when matched and (s.value is null) then
		delete
	when matched and (not s.value is null) then
		update
		set d.value = s.value
	;




	'

	-- string
	if @stringColumns <> ''
	begin
		set @updateMerge = replace(@updateMergeTemplate,'@@@_BASE_TYPE_@@@', 'string')
		set @updateMerge = replace(@updateMerge,'@@@_TYPE_COLUMNS_@@@', @stringColumns)
		set @updateMerge = replace(@updateMerge,'@@@_BASE_DATATYPE_ID_@@@', 1)

		set @updateTriggerSQL = @updateTriggerSQL + @updateMerge
	end

	-- integers
	if @integerColumns <> ''
	begin
		set @updateMerge = replace(@updateMergeTemplate,'@@@_BASE_TYPE_@@@', 'integer')
		set @updateMerge = replace(@updateMerge,'@@@_TYPE_COLUMNS_@@@', @integerColumns)
		set @updateMerge = replace(@updateMerge,'@@@_BASE_DATATYPE_ID_@@@', 2)

		set @updateTriggerSQL = @updateTriggerSQL + @updateMerge
	end

	-- decimals
	if @decimalColumns <> ''
	begin
		set @updateMerge = replace(@updateMergeTemplate,'@@@_BASE_TYPE_@@@', 'decimal')
		set @updateMerge = replace(@updateMerge,'@@@_TYPE_COLUMNS_@@@', @decimalColumns)
		set @updateMerge = replace(@updateMerge,'@@@_BASE_DATATYPE_ID_@@@', 3)

		set @updateTriggerSQL = @updateTriggerSQL + @updateMerge
	end

	-- datetime
	if @datetimeColumns <> ''
	begin
		set @updateMerge = replace(@updateMergeTemplate,'@@@_BASE_TYPE_@@@', 'datetime')
		set @updateMerge = replace(@updateMerge,'@@@_TYPE_COLUMNS_@@@', @datetimeColumns)
		set @updateMerge = replace(@updateMerge,'@@@_BASE_DATATYPE_ID_@@@', 4)

		set @updateTriggerSQL = @updateTriggerSQL + @updateMerge
	end

	set @updateTriggerSQL = @updateTriggerSQL + '
	end
	'


	-- insert trigger
	-- @@@_ACTION_CHECK_@@@
	-- @@@_META_TEMPLATE_NAME_@@@
	-- @@@_META_TEMPLATE_ID_@@@
	IF OBJECT_ID('dbo.trigger_orm_meta_view_' + @templateName + '_insert', 'TR') IS NOT NULL
		set @actionCheck = 'alter'
	else
		set @actionCheck = 'create'

	set @insertTriggerSQL = '
	@@@_ACTION_CHECK_@@@ trigger trigger_orm_meta_view_@@@_META_TEMPLATE_NAME_@@@_insert
		on dbo.@@@_META_TEMPLATE_NAME_@@@
		instead of insert
	as 
	begin

		declare @templateID int
			set @templateID = @@@_META_TEMPLATE_ID_@@@

		-- if there is no specific instances being inserted, raise an error (there is nothing to attach values to!)
		if (columns_updated() & 1) = 0
			begin	
				rollback transaction	
				raiserror(''Can not insert without an instance to attach values to.'', 16, 5)
				return
			end	

		-- verify that all the instances does not already exist (this aint an update statement!)
		if (exists(	select ins.instanceName
					from inserted as ins
						inner join orm_meta_instances as omi
							on ins.InstanceName = omi.name
					where omi.templateID = @templateID))
			begin	
				rollback transaction	
				raiserror(''Can not insert duplicate InstanceName (new instances should be added via an insert).'', 16, 5)
				return
			end	

		-- Add any instances not yet tracked in the instance table
		merge into orm_meta_instances as d
		using (	select instanceName as name
				from inserted	) as s 
		on d.name = s.name
		when not matched then
			insert (templateID, name)
			values (@templateID, s.name)
		;

		-- Rotate the table to prep for merging into the values tables
		-- Note we will need an unpivot for each of the four main types
				
		-- Also note: we want to raise an error if we attempt to insert an already set
		-- value, so on a match we will insert an invalid record (violates a primary key)
		-- and add our own error message
	'

	set @insertTriggerSQL = replace(@insertTriggerSQL,'@@@_ACTION_CHECK_@@@', @actionCheck)
	set @insertTriggerSQL = replace(@insertTriggerSQL,'@@@_META_TEMPLATE_NAME_@@@', @templateName)
	set @insertTriggerSQL = replace(@insertTriggerSQL,'@@@_META_TEMPLATE_ID_@@@', @templateID)


	set @insertMergeTemplate = '
	------------------------------------
	--	@@@_BASE_TYPE_@@@
	------------------------------------
	begin try
			
		;with insertValues as
		(
			select	instanceName
			,	propertyName
			,	value
			,	instances.instanceID
			,	properties.propertyID
			from inserted unpivot
					(	value
						for propertyName in (@@@_TYPE_COLUMNS_@@@)
					) unpivoted
				inner join orm_meta_properties as properties
					on unpivoted.propertyName = properties.name
				inner join orm_meta_instances as instances
					on unpivoted.InstanceName = instances.name
			where properties.templateID = @templateID
				and properties.datatypeID = @@@_BASE_DATATYPE_ID_@@@
				and instances.templateID = @templateID
				and value is not null
		)
		merge into orm_meta_values_@@@_BASE_TYPE_@@@ as d
		using (	select	instanceID
					,	propertyID
					,	value
				from insertValues	) as s
			on	d.instanceID = s.instanceID
			and	d.propertyID = s.propertyID
		when not matched then
			insert (instanceID, propertyID, value)
			values (s.instanceID, s.propertyID, s.value)
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
	if @stringColumns <> ''
	begin
		set @insertMerge = replace(@insertMergeTemplate,'@@@_BASE_TYPE_@@@', 'string')
		set @insertMerge = replace(@insertMerge,'@@@_TYPE_COLUMNS_@@@', @stringColumns)
		set @insertMerge = replace(@insertMerge,'@@@_BASE_DATATYPE_ID_@@@', 1)

		set @insertTriggerSQL = @insertTriggerSQL + @insertMerge
	end

	-- integers
	if @integerColumns <> ''
	begin
		set @insertMerge = replace(@insertMergeTemplate,'@@@_BASE_TYPE_@@@', 'integer')
		set @insertMerge = replace(@insertMerge,'@@@_TYPE_COLUMNS_@@@', @integerColumns)
		set @insertMerge = replace(@insertMerge,'@@@_BASE_DATATYPE_ID_@@@', 2)

		set @insertTriggerSQL = @insertTriggerSQL + @insertMerge
	end

	-- decimal
	if @decimalColumns <> ''
	begin
		set @insertMerge = replace(@insertMergeTemplate,'@@@_BASE_TYPE_@@@', 'decimal')
		set @insertMerge = replace(@insertMerge,'@@@_TYPE_COLUMNS_@@@', @decimalColumns)
		set @insertMerge = replace(@insertMerge,'@@@_BASE_DATATYPE_ID_@@@', 3)

		set @insertTriggerSQL = @insertTriggerSQL + @insertMerge
	end

	-- datetime
	if @datetimeColumns <> ''
	begin
		set @insertMerge = replace(@insertMergeTemplate,'@@@_BASE_TYPE_@@@', 'datetime')
		set @insertMerge = replace(@insertMerge,'@@@_TYPE_COLUMNS_@@@', @datetimeColumns)
		set @insertMerge = replace(@insertMerge,'@@@_BASE_DATATYPE_ID_@@@', 4)

		set @insertTriggerSQL = @insertTriggerSQL + @insertMerge
	end

	set @insertTriggerSQL = @insertTriggerSQL + '
	end
	'

	--begin transaction generate_triggers
	--begin try

		-- Apply the templates
		exec sp_executesql @deleteTriggerSQL
		exec sp_executesql @updateTriggerSQL
		exec sp_executesql @insertTriggerSQL

	--	commit transaction generate_triggers

	--end try
	--begin catch
	--	rollback transaction generate_triggers
	--	raiserror('Generating the template triggers failed.', 16, 5)
	--	return
	--end catch
end
go
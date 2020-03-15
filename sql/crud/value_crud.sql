print '
Generating all value change sprocs...'


IF OBJECT_ID('[orm].[orm_value_change_string]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_value_change_string
go

IF OBJECT_ID('[orm_meta].[value_change_string]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_string]
go

create procedure [orm_meta].[value_change_string]
	@instanceID int
,	@propertyID int
,	@value nvarchar(max)
as
begin

	merge into [orm_meta].[values_string] as d
	using ( select	@instanceID as instanceID
				,	@propertyID as propertyID) as s 
		on	d.instanceID = s.instanceID
		and	d.propertyID = s.propertyID
	
	when not matched and @value is not null then
		insert (instanceID, propertyID, value)
		values (s.instanceID, s.propertyID, @value)
	
	when matched and @value is null then
		delete 

	when matched and @value is not null then
		update set d.value = @value
	;
end
go

create procedure orm_value_change_string
	@templateName varchar(250)
,	@instanceName varchar(250)
,	@propertyName varchar(250)
,	@value nvarchar(max)
as
begin
	
	declare @templateID int, @instanceID int, @propertyID int
		set @templateID		= (select top 1 templateID from [orm_meta].[templates] where name = @templateName)
		set @instanceID	= (select top 1 instanceID from [orm_meta].[instances] where name = @instanceName and templateID = @templateID)
		set @propertyID	= (select top 1 propertyID from [orm_meta].[properties] where name = @propertyName and templateID = @templateID)

	exec [orm_meta].[value_change_string] @instanceID, @propertyID, @value
end
go


IF OBJECT_ID('[orm].[orm_value_change_integer]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_value_change_integer
go

IF OBJECT_ID('[orm_meta].[value_change_integer]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_integer]
go

create procedure [orm_meta].[value_change_integer]
	@instanceID int
,	@propertyID int
,	@value bigint
as
begin

	merge into [orm_meta].[values_integer] as d
	using ( select	@instanceID as instanceID
				,	@propertyID as propertyID) as s 
		on	d.instanceID = s.instanceID
		and	d.propertyID = s.propertyID
	
	when not matched and not @value is null then
		insert (instanceID, propertyID, value)
		values (s.instanceID, s.propertyID, @value)
	
	when matched and @value is null then
		delete 

	when matched and not @value is null then
		update set d.value = @value
	;
end
go

create procedure orm_value_change_integer
	@templateName varchar(250)
,	@instanceName varchar(250)
,	@propertyName varchar(250)
,	@value bigint
as
begin
	
	declare @templateID int, @instanceID int, @propertyID int
		set @templateID		= (select top 1 templateID from [orm_meta].[templates] where name = @templateName)
		set @instanceID	= (select top 1 instanceID from [orm_meta].[instances] where name = @instanceName and templateID = @templateID)
		set @propertyID	= (select top 1 propertyID from [orm_meta].[properties] where name = @propertyName and templateID = @templateID)

	exec [orm_meta].[value_change_integer] @instanceID, @propertyID, @value
end
go


IF OBJECT_ID('[orm].[orm_value_change_decimal]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_value_change_decimal
go

IF OBJECT_ID('[orm_meta].[value_change_decimal]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_decimal]
go

create procedure [orm_meta].[value_change_decimal]
	@instanceID int
,	@propertyID int
,	@value decimal(19,8)
as
begin

	merge into [orm_meta].[values_decimal] as d
	using ( select	@instanceID as instanceID
				,	@propertyID as propertyID) as s 
		on	d.instanceID = s.instanceID
		and	d.propertyID = s.propertyID
	
	when not matched and not @value is null then
		insert (instanceID, propertyID, value)
		values (s.instanceID, s.propertyID, @value)
	
	when matched and @value is null then
		delete 

	when matched and not @value is null then
		update set d.value = @value
	;
end
go

create procedure orm_value_change_decimal
	@templateName varchar(250)
,	@instanceName varchar(250)
,	@propertyName varchar(250)
,	@value decimal(19,8)
as
begin
	
	declare @templateID int, @instanceID int, @propertyID int
		set @templateID		= (select top 1 templateID from [orm_meta].[templates] where name = @templateName)
		set @instanceID	= (select top 1 instanceID from [orm_meta].[instances] where name = @instanceName and templateID = @templateID)
		set @propertyID	= (select top 1 propertyID from [orm_meta].[properties] where name = @propertyName and templateID = @templateID)

	exec [orm_meta].[value_change_decimal] @instanceID, @propertyID, @value
end
go


IF OBJECT_ID('[orm].[orm_value_change_datetime]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_value_change_datetime
go

IF OBJECT_ID('[orm_meta].[value_change_datetime]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_datetime]
go

create procedure [orm_meta].[value_change_datetime]
	@instanceID int
,	@propertyID int
,	@value datetime
as
begin

	merge into [orm_meta].[values_datetime] as d
	using ( select	@instanceID as instanceID
				,	@propertyID as propertyID) as s 
		on	d.instanceID = s.instanceID
		and	d.propertyID = s.propertyID
	
	when not matched and not @value is null then
		insert (instanceID, propertyID, value)
		values (s.instanceID, s.propertyID, @value)
	
	when matched and @value is null then
		delete 

	when matched and not @value is null then
		update set d.value = @value
	;
end
go

create procedure orm_value_change_datetime
	@templateName varchar(250)
,	@instanceName varchar(250)
,	@propertyName varchar(250)
,	@value datetime
as
begin
	
	declare @templateID int, @instanceID int, @propertyID int
		set @templateID		= (select top 1 templateID from [orm_meta].[templates] where name = @templateName)
		set @instanceID	= (select top 1 instanceID from [orm_meta].[instances] where name = @instanceName and templateID = @templateID)
		set @propertyID	= (select top 1 propertyID from [orm_meta].[properties] where name = @propertyName and templateID = @templateID)

	exec [orm_meta].[value_change_datetime] @instanceID, @propertyID, @value
end
go


IF OBJECT_ID('[orm].[orm_value_change_instance]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_value_change_instance
go

IF OBJECT_ID('[orm_meta].[value_change_instance]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_instance]
go

create procedure [orm_meta].[value_change_instance]
	@instanceID int
,	@propertyID int
,	@value varchar(250)
,	@clearProperty bit = 0
as
begin

	-- Instances are bit different from the other 4 base types.
	-- We can have multiple relevant entries for them
	-- so we'll need to use the merge a bit differently.
	-- We can:
	--		add a new value
	-- 		remove a specific value
	--  	clear all values
	if @value is null
	begin
		if @clearProperty = 1
			delete [orm_meta].[values_instance]
			where 	instanceID = @instanceID
				and	propertyID = @propertyID
	end
	else
	begin
		if @clearProperty = 1
			delete [orm_meta].[values_instance]
			where 	instanceID = @instanceID
				and	propertyID = @propertyID
				and value = @value
		else
			merge into [orm_meta].[values_instance] as d
			using ( select	@instanceID as instanceID
						,	@propertyID as propertyID
						,	@value as value) as s 
				on	d.instanceID = s.instanceID
				and	d.propertyID = s.propertyID
				and d.value = s.value

			when not matched then
				insert (instanceID, propertyID, value)
				values (s.instanceID, s.propertyID, @value)
			;
	end

end
go

create procedure orm_value_change_instance
	@templateName varchar(250)
,	@instanceName varchar(250)
,	@propertyName varchar(250)
,	@value varchar(250)
,	@clearProperty bit = 0
as
begin
	
	declare @templateID int, @instanceID int, @propertyID int
		set @templateID		= (select top 1 templateID from [orm_meta].[templates] where name = @templateName)
		set @instanceID	= (select top 1 instanceID from [orm_meta].[instances] where name = @instanceName and templateID = @templateID)
		set @propertyID	= (select top 1 propertyID from [orm_meta].[properties] where name = @propertyName and templateID = @templateID)

	exec [orm_meta].[value_change_instance] @instanceID, @propertyID, @value, @clearProperty
end
go


if OBJECT_ID('[orm].[orm_value_change]','P') is not null
	drop procedure [orm].orm_value_change
go

create procedure orm_value_change
	@templateName varchar(250)
,	@instanceName varchar(250)
,	@propertyName varchar(250)
,	@value nvarchar(max) = NULL
,	@clearProperty bit = 0
as
begin
begin try
begin transaction -- We'll want to make this a transaction to prevent errors from breaking the update

	declare @templateID int, @instanceID int, @propertyID int, @dataTypeID int
		set @templateID		= (select top 1 templateID from [orm_meta].[templates] where name = @templateName)
		set @instanceID	= (select top 1 instanceID from [orm_meta].[instances] where name = @instanceName and templateID = @templateID)
		set @propertyID	= (select top 1 propertyID from [orm_meta].[properties] where name = @propertyName and templateID = @templateID)
		set @dataTypeID	= (select top 1 datatypeID from [orm_meta].[properties] where propertyID = @propertyID and templateID = @templateID)

	-- As this switch structure is traversed, we'll only want to cast the value if it's NOT null
	-- If it is NULL, that can count as the hint to delete that value.

	if	not @dataTypeID in (1,2,3,4)	-- instance
	begin
		-- Instances are a bit special, and while they're a string like @value, we want to cast it first.
		-- That way, if the cast truncates, we can raise an error instead of blindly contaminating
		-- We also can have multiple instance values for a given property (effecting a list),
		--   hence the need for the @clearValue field.
		declare @instanceValue varchar(250)
			if not @value is null set @instanceValue = convert(varchar(250), @value)
		if @instanceValue <> @value raiserror('Instance name truncated. Aborting setting value. Be sure to keep names under 250 characters.', 16,1)

		exec [orm_meta].[value_change_instance] @instanceID, @propertyID, @value, @clearProperty
	end

	-- The remaining 4 base types are simpler: clear on NULL
	if @clearProperty = 1 set @value = NULL

	if		@dataTypeID = 1 -- nvarchar(max)
	begin
		exec [orm_meta].[value_change_string]	@instanceID, @propertyID, @value
	end

	if	@dataTypeID = 2 -- bigint
	begin
		declare @bigintValue bigint
			if not @value is null set @bigintValue = convert(bigint, @value)
		exec [orm_meta].[value_change_integer]	@instanceID, @propertyID, @bigintValue
	end
	
	if	@dataTypeID = 3 -- decimal(19,8)
	begin
		declare @decimalValue decimal(19,8)
			if not @value is null set @decimalValue = convert(decimal(19,8), @value)
		exec [orm_meta].[value_change_decimal] @instanceID, @propertyID, @decimalValue
	end

	if	@dataTypeID = 4 -- datetime
	begin
		declare @datetimeValue datetime
			if not @value is null set @datetimeValue = convert(datetime, @value, 121) -- ODBC canonical
		exec [orm_meta].[value_change_datetime] @instanceID, @propertyID, @datetimeValue
	end

	commit transaction
	
end try
begin catch
    declare @ErrorMessage nvarchar(max), @ErrorSeverity int, @ErrorState int
    select @ErrorMessage = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5)), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()
    rollback transaction
    raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState)
end catch
end
go


IF OBJECT_ID('[orm].[orm_value_read]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_value_read
go

create procedure orm_value_read
	@templateName varchar(250)
,	@instanceName varchar(250) = NULL
as
begin

	-- Helper sproc to get values for a template and/or instance
	--	in the format similar to Ignition's historian
	-- A NULL for the instance name results in all instances
	select	Name 
		,	Property 
		,	IntValue 
		,	FloatValue
		,	StringValue
		,	DateValue 
		,	instanceValue 
		,	instanceID
		,	propertyID
	from [orm].orm_values(@templateName) as v
	where @instanceName is NULL 
		or v.Name = @instanceName

end
go


IF OBJECT_ID('[orm].[orm_value_read_listing]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_value_read_listing
go

create procedure orm_value_read_listing
	@templateName varchar(250)
,	@instanceName varchar(250) = NULL
as
begin

	-- Helper sproc to get values for a template and/or instance
	--	in a handy stringly-typed format (good for looping over properties)
	-- A NULL for the instance name results in all instances
	set @instanceName = isnull(@instanceName,'')

	-- Note that this is a little different from the [orm_values_listing] function:
	--	this returns a blank for ALL relevant properties, 
	--	and an extra blank for instance lists (so you can always add by modifing a blank cell in a table)
	-- This is done by left joining the values and UNIONing a set of blanks to the instance values table
	select 
			o.name as [Instance]
		,	p.name as Property
		,	isnull(v.value,'') as Value
		,	d.name as Datatype
	
	from	[orm_meta].[instances] as o
		inner join [orm_meta].[templates] as t
			on o.templateID = t.templateID
		inner join [orm_meta].[properties] as p
			on o.templateID = p.templateID
		inner join [orm_meta].[templates] as d
			on p.datatypeID = d.templateID
		left join
		(	select instanceID, propertyID, convert(nvarchar(max),value) as value
			from [orm_meta].[values_integer]
			
			union

			select instanceID, propertyID, convert(nvarchar(max),value) as value
			from [orm_meta].[values_decimal]

			union

			select instanceID, propertyID, convert(nvarchar(max),value) as value
			from [orm_meta].[values_string]

			union
						-- convert the datetime to ODBC canonical yyyy-mm-dd hh:mi:ss.mmm
			select instanceID, propertyID, convert(nvarchar(max),value, 121) as value
			from [orm_meta].[values_datetime]

			union

			select instanceID, propertyID, convert(nvarchar(max),value) as value
			from [orm_meta].[values_instance]

			union 

			select instanceID, propertyID, '' as value
			from [orm_meta].[values_instance]

		) as v
			on	o.instanceID   = v.instanceID
			and	p.propertyID = v.propertyID
	where t.name = @templateName
		and	(@instanceName = '' or o.name = @instanceName)
	order by o.name, p.name, v.value

end
go

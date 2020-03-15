print '
Generating all value change sprocs...'


IF OBJECT_ID('[orm].[value_change_string]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_change_string]
go

IF OBJECT_ID('[orm_meta].[value_change_string]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_string]
go

create procedure [orm_meta].[value_change_string]
	@instance_id int
,	@property_id int
,	@value nvarchar(max)
as
begin

	merge into [orm_meta].[values_string] as d
	using ( select	@instance_id as instance_id
				,	@property_id as property_id) as s 
		on	d.instance_id = s.instance_id
		and	d.property_id = s.property_id
	
	when not matched and @value is not null then
		insert (instance_id, property_id, value)
		values (s.instance_id, s.property_id, @value)
	
	when matched and @value is null then
		delete 

	when matched and @value is not null then
		update set d.value = @value
	;
end
go

create procedure [orm].[value_change_string]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value nvarchar(max)
as
begin
	
	declare @template_id int, @instance_id int, @property_id int
		set @template_id		= (select top 1 template_id from [orm_meta].[templates] where name = @template_name)
		set @instance_id	= (select top 1 instance_id from [orm_meta].[instances] where name = @instance_name and template_id = @template_id)
		set @property_id	= (select top 1 property_id from [orm_meta].[properties] where name = @property_name and template_id = @template_id)

	exec [orm_meta].[value_change_string] @instance_id, @property_id, @value
end
go


IF OBJECT_ID('[orm].[value_change_integer]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_change_integer]
go

IF OBJECT_ID('[orm_meta].[value_change_integer]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_integer]
go

create procedure [orm_meta].[value_change_integer]
	@instance_id int
,	@property_id int
,	@value bigint
as
begin

	merge into [orm_meta].[values_integer] as d
	using ( select	@instance_id as instance_id
				,	@property_id as property_id) as s 
		on	d.instance_id = s.instance_id
		and	d.property_id = s.property_id
	
	when not matched and not @value is null then
		insert (instance_id, property_id, value)
		values (s.instance_id, s.property_id, @value)
	
	when matched and @value is null then
		delete 

	when matched and not @value is null then
		update set d.value = @value
	;
end
go

create procedure [orm].[value_change_integer]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value bigint
as
begin
	
	declare @template_id int, @instance_id int, @property_id int
		set @template_id		= (select top 1 template_id from [orm_meta].[templates] where name = @template_name)
		set @instance_id	= (select top 1 instance_id from [orm_meta].[instances] where name = @instance_name and template_id = @template_id)
		set @property_id	= (select top 1 property_id from [orm_meta].[properties] where name = @property_name and template_id = @template_id)

	exec [orm_meta].[value_change_integer] @instance_id, @property_id, @value
end
go


IF OBJECT_ID('[orm].[value_change_decimal]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_change_decimal]
go

IF OBJECT_ID('[orm_meta].[value_change_decimal]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_decimal]
go

create procedure [orm_meta].[value_change_decimal]
	@instance_id int
,	@property_id int
,	@value decimal(19,8)
as
begin

	merge into [orm_meta].[values_decimal] as d
	using ( select	@instance_id as instance_id
				,	@property_id as property_id) as s 
		on	d.instance_id = s.instance_id
		and	d.property_id = s.property_id
	
	when not matched and not @value is null then
		insert (instance_id, property_id, value)
		values (s.instance_id, s.property_id, @value)
	
	when matched and @value is null then
		delete 

	when matched and not @value is null then
		update set d.value = @value
	;
end
go

create procedure [orm].[value_change_decimal]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value decimal(19,8)
as
begin
	
	declare @template_id int, @instance_id int, @property_id int
		set @template_id		= (select top 1 template_id from [orm_meta].[templates] where name = @template_name)
		set @instance_id	= (select top 1 instance_id from [orm_meta].[instances] where name = @instance_name and template_id = @template_id)
		set @property_id	= (select top 1 property_id from [orm_meta].[properties] where name = @property_name and template_id = @template_id)

	exec [orm_meta].[value_change_decimal] @instance_id, @property_id, @value
end
go


IF OBJECT_ID('[orm].[value_change_datetime]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_change_datetime]
go

IF OBJECT_ID('[orm_meta].[value_change_datetime]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_datetime]
go

create procedure [orm_meta].[value_change_datetime]
	@instance_id int
,	@property_id int
,	@value datetime
as
begin

	merge into [orm_meta].[values_datetime] as d
	using ( select	@instance_id as instance_id
				,	@property_id as property_id) as s 
		on	d.instance_id = s.instance_id
		and	d.property_id = s.property_id
	
	when not matched and not @value is null then
		insert (instance_id, property_id, value)
		values (s.instance_id, s.property_id, @value)
	
	when matched and @value is null then
		delete 

	when matched and not @value is null then
		update set d.value = @value
	;
end
go

create procedure [orm].[value_change_datetime]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value datetime
as
begin
	
	declare @template_id int, @instance_id int, @property_id int
		set @template_id		= (select top 1 template_id from [orm_meta].[templates] where name = @template_name)
		set @instance_id	= (select top 1 instance_id from [orm_meta].[instances] where name = @instance_name and template_id = @template_id)
		set @property_id	= (select top 1 property_id from [orm_meta].[properties] where name = @property_name and template_id = @template_id)

	exec [orm_meta].[value_change_datetime] @instance_id, @property_id, @value
end
go


IF OBJECT_ID('[orm].[value_change_instance]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_change_instance]
go

IF OBJECT_ID('[orm_meta].[value_change_instance]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_instance]
go

create procedure [orm_meta].[value_change_instance]
	@instance_id int
,	@property_id int
,	@value varchar(250)
,	@clear_property bit = 0
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
		if @clear_property = 1
			delete [orm_meta].[values_instance]
			where 	instance_id = @instance_id
				and	property_id = @property_id
	end
	else
	begin
		if @clear_property = 1
			delete [orm_meta].[values_instance]
			where 	instance_id = @instance_id
				and	property_id = @property_id
				and value = @value
		else
			merge into [orm_meta].[values_instance] as d
			using ( select	@instance_id as instance_id
						,	@property_id as property_id
						,	@value as value) as s 
				on	d.instance_id = s.instance_id
				and	d.property_id = s.property_id
				and d.value = s.value

			when not matched then
				insert (instance_id, property_id, value)
				values (s.instance_id, s.property_id, @value)
			;
	end

end
go

create procedure [orm].[value_change_instance]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value varchar(250)
,	@clear_property bit = 0
as
begin
	
	declare @template_id int, @instance_id int, @property_id int
		set @template_id		= (select top 1 template_id from [orm_meta].[templates] where name = @template_name)
		set @instance_id	= (select top 1 instance_id from [orm_meta].[instances] where name = @instance_name and template_id = @template_id)
		set @property_id	= (select top 1 property_id from [orm_meta].[properties] where name = @property_name and template_id = @template_id)

	exec [orm_meta].[value_change_instance] @instance_id, @property_id, @value, @clear_property
end
go


if OBJECT_ID('[orm].[value_change]','P') is not null
	drop procedure [orm].[value_change]
go

create procedure [orm].[value_change]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value nvarchar(max) = NULL
,	@clear_property bit = 0
as
begin
begin try
begin transaction -- We'll want to make this a transaction to prevent errors from breaking the update

	declare @template_id int, @instance_id int, @property_id int, @data_type_id int
		set @template_id		= (select top 1 template_id from [orm_meta].[templates] where name = @template_name)
		set @instance_id	= (select top 1 instance_id from [orm_meta].[instances] where name = @instance_name and template_id = @template_id)
		set @property_id	= (select top 1 property_id from [orm_meta].[properties] where name = @property_name and template_id = @template_id)
		set @data_type_id	= (select top 1 datatype_id from [orm_meta].[properties] where property_id = @property_id and template_id = @template_id)

	-- As this switch structure is traversed, we'll only want to cast the value if it's NOT null
	-- If it is NULL, that can count as the hint to delete that value.

	if	not @data_type_id in (1,2,3,4)	-- instance
	begin
		-- Instances are a bit special, and while they're a string like @value, we want to cast it first.
		-- That way, if the cast truncates, we can raise an error instead of blindly contaminating
		-- We also can have multiple instance values for a given property (effecting a list),
		--   hence the need for the @clear_value field.
		declare @instance_value varchar(250)
			if not @value is null set @instance_value = convert(varchar(250), @value)
		if @instance_value <> @value raiserror('Instance name truncated. Aborting setting value. Be sure to keep names under 250 characters.', 16,1)

		exec [orm_meta].[value_change_instance] @instance_id, @property_id, @value, @clear_property
	end

	-- The remaining 4 base types are simpler: clear on NULL
	if @clear_property = 1 set @value = NULL

	if		@data_type_id = 1 -- nvarchar(max)
	begin
		exec [orm_meta].[value_change_string]	@instance_id, @property_id, @value
	end

	if	@data_type_id = 2 -- bigint
	begin
		declare @bigint_value bigint
			if not @value is null set @bigint_value = convert(bigint, @value)
		exec [orm_meta].[value_change_integer]	@instance_id, @property_id, @bigint_value
	end
	
	if	@data_type_id = 3 -- decimal(19,8)
	begin
		declare @decimal_value decimal(19,8)
			if not @value is null set @decimal_value = convert(decimal(19,8), @value)
		exec [orm_meta].[value_change_decimal] @instance_id, @property_id, @decimal_value
	end

	if	@data_type_id = 4 -- datetime
	begin
		declare @datetime_value datetime
			if not @value is null set @datetime_value = convert(datetime, @value, 121) -- ODBC canonical
		exec [orm_meta].[value_change_datetime] @instance_id, @property_id, @datetime_value
	end

	commit transaction
	
end try
begin catch
    declare @error_message nvarchar(max), @error_severity int, @error_state int
    select @error_message = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5)), @error_severity = ERROR_SEVERITY(), @error_state = ERROR_STATE()
    rollback transaction
    raiserror (@error_message, @error_severity, @error_state)
end catch
end
go


IF OBJECT_ID('[orm].[value_read]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_read]
go

create procedure [orm].[value_read]
	@template_name varchar(250)
,	@instance_name varchar(250) = NULL
as
begin

	-- Helper sproc to get values for a template and/or instance
	--	in the format similar to Ignition's historian
	-- A NULL for the instance name results in all instances
	select	Name 
		,	Property 
		,	[Integer]
		,	[Float]
		,	[String]
		,	[Date]
		,	[Instance]
		,	instance_id
		,	property_id
	from [orm].[values](@template_name) as v
	where @instance_name is NULL 
		or v.Name = @instance_name

end
go


IF OBJECT_ID('[orm].[value_read_listing]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_read_listing]
go

create procedure [orm].[value_read_listing]
	@template_name varchar(250)
,	@instance_name varchar(250) = NULL
as
begin

	-- Helper sproc to get values for a template and/or instance
	--	in a handy stringly-typed format (good for looping over properties)
	-- A NULL for the instance name results in all instances
	set @instance_name = isnull(@instance_name,'')

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
			on o.template_id = t.template_id
		inner join [orm_meta].[properties] as p
			on o.template_id = p.template_id
		inner join [orm_meta].[templates] as d
			on p.datatype_id = d.template_id
		left join
		(	select instance_id, property_id, convert(nvarchar(max),value) as value
			from [orm_meta].[values_integer]
			
			union

			select instance_id, property_id, convert(nvarchar(max),value) as value
			from [orm_meta].[values_decimal]

			union

			select instance_id, property_id, convert(nvarchar(max),value) as value
			from [orm_meta].[values_string]

			union
						-- convert the datetime to ODBC canonical yyyy-mm-dd hh:mi:ss.mmm
			select instance_id, property_id, convert(nvarchar(max),value, 121) as value
			from [orm_meta].[values_datetime]

			union

			select instance_id, property_id, convert(nvarchar(max),value) as value
			from [orm_meta].[values_instance]

			union 

			select instance_id, property_id, '' as value
			from [orm_meta].[values_instance]

		) as v
			on	o.instance_id   = v.instance_id
			and	p.property_id = v.property_id
	where t.name = @template_name
		and	(@instance_name = '' or o.name = @instance_name)
	order by o.name, p.name, v.value

end
go

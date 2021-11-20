print '
Generating all value change sprocs...'


IF OBJECT_ID('[orm].[value_change_string]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_change_string]
go

IF OBJECT_ID('[orm_meta].[value_change_string]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_string]
go

create procedure [orm_meta].[value_change_string]
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
,	@value nvarchar(max) = null
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	merge into [orm_meta].[values_string] as d
	using ( select	@instance_guid as instance_guid
				,	@property_guid as property_guid) as s 
		on	d.instance_guid = s.instance_guid
		and	d.property_guid = s.property_guid
	
	when not matched and @value is not null then
		insert (  instance_guid,   property_guid,  value)
		values (s.instance_guid, s.property_guid, @value)
	
	when matched and @value is null then
		delete 

	when matched and @value is not null then
		update set d.value = @value
	;

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


create procedure [orm].[value_change_string]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value nvarchar(max) = null
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;
	
	declare @template_guid uniqueidentifier
		, 	@instance_guid uniqueidentifier
		, 	@property_guid uniqueidentifier
		set @template_guid = (select template_guid from [orm_meta].[templates]  where name = @template_name )
		set @instance_guid = (select instance_guid from [orm_meta].[instances]  where name = @instance_name and template_guid = @template_guid )
		set @property_guid = (select property_guid from [orm_meta].[properties] where name = @property_name and template_guid = @template_guid )

	exec [orm_meta].[value_change_string] @instance_guid, @property_guid, @value

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go



IF OBJECT_ID('[orm].[value_change_integer]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_change_integer]
go

IF OBJECT_ID('[orm_meta].[value_change_integer]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_integer]
go

create procedure [orm_meta].[value_change_integer]
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
,	@value bigint = null
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	merge into [orm_meta].[values_integer] as d
	using ( select	@instance_guid as instance_guid
				,	@property_guid as property_guid) as s 
		on	d.instance_guid = s.instance_guid
		and	d.property_guid = s.property_guid
	
	when not matched and not @value is null then
		insert (  instance_guid,   property_guid,  value)
		values (s.instance_guid, s.property_guid, @value)
	
	when matched and @value is null then
		delete 

	when matched and not @value is null then
		update set d.value = @value
	;

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


create procedure [orm].[value_change_integer]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value bigint = null
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;
	
	declare @template_guid uniqueidentifier
		, 	@instance_guid uniqueidentifier
		, 	@property_guid uniqueidentifier
		set @template_guid = (select template_guid from [orm_meta].[templates]  where name = @template_name )
		set @instance_guid = (select instance_guid from [orm_meta].[instances]  where name = @instance_name and template_guid = @template_guid )
		set @property_guid = (select property_guid from [orm_meta].[properties] where name = @property_name and template_guid = @template_guid )

	exec [orm_meta].[value_change_integer] @instance_guid, @property_guid, @value

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


IF OBJECT_ID('[orm].[value_change_decimal]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_change_decimal]
go

IF OBJECT_ID('[orm_meta].[value_change_decimal]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_decimal]
go


create procedure [orm_meta].[value_change_decimal]
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
,	@value decimal(19,8) = null
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	merge into [orm_meta].[values_decimal] as d
	using ( select	@instance_guid as instance_guid
				,	@property_guid as property_guid) as s 
		on	d.instance_guid = s.instance_guid
		and	d.property_guid = s.property_guid
	
	when not matched and not @value is null then
		insert (  instance_guid,   property_guid,  value)
		values (s.instance_guid, s.property_guid, @value)
	
	when matched and @value is null then
		delete 

	when matched and not @value is null then
		update set d.value = @value
	;

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


create procedure [orm].[value_change_decimal]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value decimal(19,8) = null
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;
	
	declare @template_guid uniqueidentifier
		, 	@instance_guid uniqueidentifier
		, 	@property_guid uniqueidentifier
		set @template_guid = (select template_guid from [orm_meta].[templates]  where name = @template_name )
		set @instance_guid = (select instance_guid from [orm_meta].[instances]  where name = @instance_name and template_guid = @template_guid )
		set @property_guid = (select property_guid from [orm_meta].[properties] where name = @property_name and template_guid = @template_guid )

	exec [orm_meta].[value_change_decimal] @instance_guid, @property_guid, @value

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go



IF OBJECT_ID('[orm].[value_change_datetime]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_change_datetime]
go

IF OBJECT_ID('[orm_meta].[value_change_datetime]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_datetime]
go


create procedure [orm_meta].[value_change_datetime]
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
,	@value datetimeoffset(7) = null
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	merge into [orm_meta].[values_datetime] as d
	using ( select	@instance_guid as instance_guid
				,	@property_guid as property_guid) as s 
		on	d.instance_guid = s.instance_guid
		and	d.property_guid = s.property_guid
	
	when not matched and not @value is null then
		insert (  instance_guid,   property_guid,  value)
		values (s.instance_guid, s.property_guid, @value)
	
	when matched and @value is null then
		delete 

	when matched and not @value is null then
		update set d.value = @value
	;

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


create procedure [orm].[value_change_datetime]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value datetimeoffset(7) = null
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;
	
	declare @template_guid uniqueidentifier
		, 	@instance_guid uniqueidentifier
		, 	@property_guid uniqueidentifier
		set @template_guid = (select template_guid from [orm_meta].[templates]  where name = @template_name )
		set @instance_guid = (select instance_guid from [orm_meta].[instances]  where name = @instance_name and template_guid = @template_guid )
		set @property_guid = (select property_guid from [orm_meta].[properties] where name = @property_name and template_guid = @template_guid )

	exec [orm_meta].[value_change_datetime] @instance_guid, @property_guid, @value

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go



IF OBJECT_ID('[orm].[value_change_instance]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value_change_instance]
go

IF OBJECT_ID('[orm_meta].[value_change_instance]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[value_change_instance]
go

create procedure [orm_meta].[value_change_instance]
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
,	@value uniqueidentifier = null
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	merge into [orm_meta].[values_instance] as d
	using ( select	@instance_guid as instance_guid
				,	@property_guid as property_guid) as s 
		on	d.instance_guid = s.instance_guid
		and	d.property_guid = s.property_guid
	
	when not matched and not @value is null then
		insert (  instance_guid,   property_guid,  value)
		values (s.instance_guid, s.property_guid, @value)
	
	when matched and @value is null then
		delete 

	when matched and not @value is null then
		update set d.value = @value
	;

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go


create procedure [orm].[value_change_instance]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@value varchar(250) = null
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;
	
	declare @template_guid uniqueidentifier
		, 	@instance_guid uniqueidentifier
		, 	@property_guid uniqueidentifier
		,	@value_guid uniqueidentifier
		set @template_guid = (select template_guid from [orm_meta].[templates]  where name = @template_name )
		set @instance_guid = (select instance_guid from [orm_meta].[instances]  where name = @instance_name and template_guid = @template_guid )
		set @property_guid = (select property_guid from [orm_meta].[properties] where name = @property_name and template_guid = @template_guid )

	set @value_guid = TRY_CAST(@value as uniqueidentifier)
	if @value_guid is null
		begin
			set @value_guid = (	
				select top 1 i.instance_guid
				from [orm_meta].[properties] as p
					cross apply [orm_meta].[sub_templates](p.datatype_guid) as st
					inner join [orm_meta].[instances] as i
						on st.template_guid = i.template_guid
				where p.property_guid = @property_guid
					and i.name = @value
				order by st.echelon
			)
		end

	if @value_guid is null
		begin
			;throw 51000, 'Given instance value is neither a uniqueidentifier nor locally resolvable from the given template type of the property', 1;
		end

	exec [orm_meta].[value_change_instance] @instance_guid, @property_guid, @value_guid

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
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
as
begin
begin try
begin transaction -- We'll want to make this a transaction to prevent errors from breaking the update

  set nocount on; set xact_abort on;

	declare @message nvarchar(1000)
	declare @template_guid uniqueidentifier
		, 	@instance_guid uniqueidentifier
		, 	@property_guid uniqueidentifier
		, 	@datatype_guid uniqueidentifier
		set @template_guid = (select template_guid from [orm_meta].[templates]  where name = @template_name )
		set @instance_guid = (select instance_guid from [orm_meta].[instances]  where name = @instance_name and template_guid = @template_guid )
		set @property_guid = (select property_guid from [orm_meta].[properties] where name = @property_name and template_guid = @template_guid )
		set @datatype_guid = (select datatype_guid from [orm_meta].[properties] where property_guid = @property_guid)

	if @template_guid is null
		begin
			set @message = concat('Template does not exist: ', @template_name)
			;throw 51000, @message, 1;
		end

	if @instance_guid is null
		begin
			set @message = concat('Instance does not exist: ', @instance_name)
			;throw 51000, @message, 1;
		end

	if @property_guid is null
		begin
			set @message = concat('Property ', @property_name, ' does not exist on the template ', @template_name)
			;throw 51000, @message, 1;
		end

	-- As this switch structure is traversed, we'll only want to cast the value if it's NOT null
	-- If it is NULL, that can count as the hint to delete that value.

	if	@datatype_guid = 0x00000000000000000000000000000001 -- nvarchar(max)
	begin
		exec [orm_meta].[value_change_string]	@instance_guid, @property_guid, @value
	end
	else
	if	@datatype_guid = 0x00000000000000000000000000000002 -- bigint
	begin
		declare @bigint_value bigint
			if not @value is null set @bigint_value = convert(bigint, @value)
		exec [orm_meta].[value_change_integer]	@instance_guid, @property_guid, @bigint_value
	end
	else
	if	@datatype_guid = 0x00000000000000000000000000000003 -- decimal(19,8)
	begin
		declare @decimal_value decimal(19,8)
			if not @value is null set @decimal_value = convert(decimal(19,8), @value)
		exec [orm_meta].[value_change_decimal] @instance_guid, @property_guid, @decimal_value
	end
	else
	if	@datatype_guid = 0x00000000000000000000000000000004 -- datetime
	begin
		declare @datetime_value datetimeoffset(7)
			if not @value is null set @datetime_value = convert(datetimeoffset(7), @value, 121) -- ODBC canonical
		exec [orm_meta].[value_change_datetime] @instance_guid, @property_guid, @datetime_value
	end
	else
--	if @datatype_guid > 0x00000000000000000000000000000004	-- instance
	begin
		-- Instances are a bit special, and while they're a string like @value, we want to cast it first.
		-- That way, if the cast truncates, we can raise an error instead of blindly contaminating
		declare @instance_value varchar(250)
			if not @value is null 
				set @instance_value = convert(varchar(250), @value)
				
		if @instance_value <> @value 
			begin
				;throw 51000, 'Instance name truncated. Aborting setting value. Be sure to keep names under 250 characters.', 1;
			end

		declare @value_guid uniqueidentifier
		set @value_guid = TRY_CAST(@instance_value as uniqueidentifier)
		if @value_guid is null
			begin
				set @value_guid = (	
					select top 1 i.instance_guid
					from [orm_meta].[properties] as p
						cross apply [orm_meta].[sub_templates](p.datatype_guid) as st
						inner join [orm_meta].[instances] as i
							on st.template_guid = i.template_guid
					where p.property_guid = @property_guid
						and i.name = @value
					order by st.echelon
				)
			end

		if @value_guid is null
			begin
				set @message = concat('The instance value "', @value, '" is neither a UUID nor resolvable given the template property type of "', @template_name, '.', @property_name, '".')
				;throw 51000, @message, 1;
			end

		exec [orm_meta].[value_change_instance] @instance_guid, @property_guid, @value_guid
	end

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
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
	set nocount on;

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
		,	instance_guid
		,	property_guid
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
	set nocount on;

	-- Helper sproc to get values for a template and/or instance
	--	in a handy stringly-typed format (good for looping over properties)
	-- A NULL for the instance name results in all instances

	-- Consider profiling to see if the unions can be sped up by earlier where clauses

	declare @template_guid uniqueidentifier
		,	@instance_guid uniqueidentifier
		set @template_guid = (select template_guid from [orm_meta].[templates]  where name = @template_name )
		set @instance_guid = (select instance_guid from [orm_meta].[instances]  where name = @instance_name and template_guid = @template_guid )

	-- Note that this is a little different from the [orm_values_listing] function,
	--	this returns a blank for ALL relevant properties, 
	-- This is done by left joining the values and UNIONing a set of blanks to the instance values table
	select 
			o.name as [Instance]
		,	p.name as Property
		,	isnull(v.value,'') as Value
		,	d.name as Datatype
	
	from	[orm_meta].[instances] as o
		inner join [orm_meta].[templates] as t
			on o.template_guid = t.template_guid
		inner join [orm_meta].[properties] as p
			on o.template_guid = p.template_guid
		inner join [orm_meta].[templates] as d
			on p.datatype_guid = d.template_guid
		left join
		(	
			select instance_guid, property_guid, convert(nvarchar(max),value) as value
			from [orm_meta].[values_integer]
			
			union

			select instance_guid, property_guid, convert(nvarchar(max),value) as value
			from [orm_meta].[values_decimal]

			union

			select instance_guid, property_guid, convert(nvarchar(max),value) as value
			from [orm_meta].[values_string]

			union
						-- convert the datetime to ODBC canonical yyyy-mm-dd hh:mi:ss.mmm
			select instance_guid, property_guid, convert(nvarchar(max),value, 121) as value
			from [orm_meta].[values_datetime]

			union

			select instance_guid, property_guid, convert(nvarchar(max),value) as value
			from [orm_meta].[values_instance]

		) as v
			on	o.instance_guid = v.instance_guid
			and	p.property_guid = v.property_guid

	where t.template_guid = @template_guid
	  and (@instance_guid is null or o.instance_guid = @instance_guid)
	order by o.name, p.name, v.value

end
go




IF OBJECT_ID('[orm].[value]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[value]
go

create procedure [orm].[value]
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
as
begin
begin try
begin transaction

  set nocount on; set xact_abort on;

	declare @message nvarchar(1000)
	declare @template_guid uniqueidentifier
		,	@instance_guid uniqueidentifier
		,	@property_guid uniqueidentifier
		,	@datatype_guid uniqueidentifier

	set @template_guid = (select template_guid from orm_meta.templates where name = @template_name)
	
	if @template_guid is null
		begin
			set @message = concat('Template does not exist: ', @template_guid)
			;throw 51000, @message, 1;
		end

	set @instance_guid = (select top 1 instance_guid 
						  from orm_meta.instances as i
							inner join orm_meta.sub_templates(@template_guid) as st
								on i.template_guid = st.template_guid
						  where name = @instance_name
						  order by echelon desc)

	if @instance_guid is null
		begin
			set @message = concat('Instance does not exist: ', @instance_guid)
			;throw 51000, @message, 1;
		end

	set @template_guid = (select template_guid from orm_meta.instances where instance_guid = @instance_guid)

	set @property_guid = (select property_guid 
						  from orm_meta.properties 
						  where template_guid = @template_guid
						    and name = @property_name)

	if @property_guid is null
		begin
			set @message = concat('Property does not exist: ', @property_guid)
			;throw 51000, @message, 1;
		end

    set @datatype_guid = (select  p.datatype_guid from orm_meta.properties as p where p.property_guid = @property_guid)

	if @datatype_guid is null
		begin
			set @message = concat('Datatype does not exist: ', @datatype_guid)
			;throw 51000, @message, 1;
		end


	if	@datatype_guid = 0x00000000000000000000000000000001 -- nvarchar(max)
	begin
		select v.value
			,  t.name as template
			,  i.name as instance
			,  p.name as property
			,  d.name as datatype
			,  t.template_guid
			,  i.instance_guid
			,  p.property_guid
			,  p.datatype_guid
		from orm_meta.templates as t
			inner join orm_meta.properties as p
				on t.template_guid = p.template_guid
			inner join orm_meta.templates as d
				on d.template_guid = p.datatype_guid
			inner join orm_meta.instances as i
				on t.template_guid = i.template_guid
			inner join orm_meta.values_string as v
				on  v.instance_guid = i.instance_guid
				and v.property_guid = p.property_guid
		where t.template_guid = @template_guid
		  and p.property_guid = @property_guid
		  and i.instance_guid = @instance_guid
		 
		return
	end
	else
	if	@datatype_guid = 0x00000000000000000000000000000002 -- bigint
	begin
		select v.value
			,  t.name as template
			,  i.name as instance
			,  p.name as property
			,  d.name as datatype
			,  t.template_guid
			,  i.instance_guid
			,  p.property_guid
			,  p.datatype_guid
		from orm_meta.templates as t
			inner join orm_meta.properties as p
				on t.template_guid = p.template_guid
			inner join orm_meta.templates as d
				on d.template_guid = p.datatype_guid
			inner join orm_meta.instances as i
				on t.template_guid = i.template_guid
			inner join orm_meta.values_integer as v
				on  v.instance_guid = i.instance_guid
				and v.property_guid = p.property_guid
		where t.template_guid = @template_guid
		  and p.property_guid = @property_guid
		  and i.instance_guid = @instance_guid
		 
		return
	end
	else
	if	@datatype_guid = 0x00000000000000000000000000000003 -- decimal(19,8)
	begin
		select v.value
			,  t.name as template
			,  i.name as instance
			,  p.name as property
			,  d.name as datatype
			,  t.template_guid
			,  i.instance_guid
			,  p.property_guid
			,  p.datatype_guid
		from orm_meta.templates as t
			inner join orm_meta.properties as p
				on t.template_guid = p.template_guid
			inner join orm_meta.templates as d
				on d.template_guid = p.datatype_guid
			inner join orm_meta.instances as i
				on t.template_guid = i.template_guid
			inner join orm_meta.values_decimal as v
				on  v.instance_guid = i.instance_guid
				and v.property_guid = p.property_guid
		where t.template_guid = @template_guid
		  and p.property_guid = @property_guid
		  and i.instance_guid = @instance_guid
		 
		return
	end
	else
	if	@datatype_guid = 0x00000000000000000000000000000004 -- datetime
	begin
		select v.value
			,  t.name as template
			,  i.name as instance
			,  p.name as property
			,  d.name as datatype
			,  t.template_guid
			,  i.instance_guid
			,  p.property_guid
			,  p.datatype_guid
		from orm_meta.templates as t
			inner join orm_meta.properties as p
				on t.template_guid = p.template_guid
			inner join orm_meta.templates as d
				on d.template_guid = p.datatype_guid
			inner join orm_meta.instances as i
				on t.template_guid = i.template_guid
			inner join orm_meta.values_datetime as v
				on  v.instance_guid = i.instance_guid
				and v.property_guid = p.property_guid
		where t.template_guid = @template_guid
		  and p.property_guid = @property_guid
		  and i.instance_guid = @instance_guid
		 
		return
	end
	else
--	if @datatype_guid > 0x00000000000000000000000000000004	-- instance
	begin
		select vi.name as value
			,  t.name as template
			,  i.name as instance
			,  p.name as property
			,  d.name as datatype
			,  t.template_guid
			,  i.instance_guid
			,  p.property_guid
			,  p.datatype_guid
		from orm_meta.templates as t
			inner join orm_meta.properties as p
				on t.template_guid = p.template_guid
			inner join orm_meta.templates as d
				on d.template_guid = p.datatype_guid
			inner join orm_meta.instances as i
				on t.template_guid = i.template_guid
			inner join orm_meta.values_instance as v
				on  v.instance_guid = i.instance_guid
				and v.property_guid = p.property_guid
			inner join orm_meta.instances as vi
				on v.value = vi.instance_guid
		where t.template_guid = @template_guid
		  and p.property_guid = @property_guid
		  and i.instance_guid = @instance_guid
		 
		return
	end

  commit transaction

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end

go
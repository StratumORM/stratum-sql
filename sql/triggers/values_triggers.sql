print '
Adding value table triggers (for history)...'

-- STRING

if object_id('[orm_meta].[values_string_insert]', 'TR')  is not null
	drop trigger [orm_meta].[values_string_insert]
go

create trigger [orm_meta].[values_string_insert]
	on [orm_meta].[values_string]
	after insert
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values string history') = 0
	  begin
		-- Log the end of missing entry to history
		insert into [orm_hist].[values_string] 
			  (  instance_guid,   property_guid, value, transaction_id)
		select i.instance_guid, i.property_guid,  null, CURRENT_TRANSACTION_ID()
		from inserted as i
			inner join [orm_meta].[properties] as p 
				on i.property_guid = p.property_guid
		where p.no_history = 0
	  end
end
go



if object_id('[orm_meta].[values_string_update]', 'TR')  is not null
	drop trigger [orm_meta].[values_string_update]
go

create trigger [orm_meta].[values_string_update]
	on [orm_meta].[values_string]
	after update
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values string history') = 0
	  begin
		-- Log the changes to history
		insert into [orm_hist].[values_string] 
			  (  instance_guid,   property_guid,   value, transaction_id)
		select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
		from deleted as d
			inner join inserted as i 
				on d.instance_guid = i.instance_guid
				and d.property_guid = i.property_guid
			inner join [orm_meta].[properties] as p 
				on i.property_guid = p.property_guid
		where  ((d.value <> i.value) -- only log changes
			 or (d.value is null and i.value is not null)
			 or (d.value is not null and i.value is null)
			 ) and p.no_history = 0
	  end
end
go



if object_id('[orm_meta].[values_string_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_string_delete]
go

create trigger [orm_meta].[values_string_delete]
	on [orm_meta].[values_string]
	after delete
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values string history') = 0
	  begin
		-- Log the changes to history
		insert into [orm_hist].[values_string] 
			  (  instance_guid,   property_guid,   value, transaction_id)
		select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
		from deleted as d
	  end
end
go


-- INTEGER

if object_id('[orm_meta].[values_integer_insert]', 'TR')  is not null
	drop trigger [orm_meta].[values_integer_insert]
go

create trigger [orm_meta].[values_integer_insert]
	on [orm_meta].[values_integer]
	after insert
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values integer history') = 0
	  begin
		-- Log the end of missing entry to history
		insert into [orm_hist].[values_integer] 
			  (  instance_guid,   property_guid, value, transaction_id)
		select i.instance_guid, i.property_guid,  null, CURRENT_TRANSACTION_ID()
		from inserted as i
			inner join [orm_meta].[properties] as p 
				on i.property_guid = p.property_guid
		where p.no_history = 0
	  end
end
go



if object_id('[orm_meta].[values_integer_update]', 'TR')  is not null
	drop trigger [orm_meta].[values_integer_update]
go

create trigger [orm_meta].[values_integer_update]
	on [orm_meta].[values_integer]
	after update
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values integer history') = 0
	  begin
		-- Log the changes to history
		insert into [orm_hist].[values_integer] 
			  (  instance_guid,   property_guid,   value, transaction_id)
		select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
		from deleted as d
			inner join inserted as i 
				on d.instance_guid = i.instance_guid
				and d.property_guid = i.property_guid
			inner join [orm_meta].[properties] as p 
				on i.property_guid = p.property_guid
		where  ((d.value <> i.value) -- only log changes
			 or (d.value is null and i.value is not null)
			 or (d.value is not null and i.value is null)
			 ) and p.no_history = 0
	  end
end
go



if object_id('[orm_meta].[values_integer_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_integer_delete]
go

create trigger [orm_meta].[values_integer_delete]
	on [orm_meta].[values_integer]
	after delete
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values integer history') = 0
	  begin
		-- Log the changes to history
		insert into [orm_hist].[values_integer] 
			  (  instance_guid,   property_guid,   value, transaction_id)
		select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
		from deleted as d
	  end
end
go


-- DECIMAL

if object_id('[orm_meta].[values_decimal_insert]', 'TR')  is not null
	drop trigger [orm_meta].[values_decimal_insert]
go

create trigger [orm_meta].[values_decimal_insert]
	on [orm_meta].[values_decimal]
	after insert
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values decimal history') = 0
	  begin
		-- Log the end of missing entry to history
		insert into [orm_hist].[values_decimal] 
			  (  instance_guid,   property_guid, value, transaction_id)
		select i.instance_guid, i.property_guid,  null, CURRENT_TRANSACTION_ID()
		from inserted as i
			inner join [orm_meta].[properties] as p 
				on i.property_guid = p.property_guid
		where p.no_history = 0
	  end
end
go



if object_id('[orm_meta].[values_decimal_update]', 'TR')  is not null
	drop trigger [orm_meta].[values_decimal_update]
go

create trigger [orm_meta].[values_decimal_update]
	on [orm_meta].[values_decimal]
	after update
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values decimal history') = 0
	  begin
		-- Log the changes to history
		insert into [orm_hist].[values_decimal] 
			  (  instance_guid,   property_guid,   value, transaction_id)
		select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
		from deleted as d
			inner join inserted as i 
				on d.instance_guid = i.instance_guid
				and d.property_guid = i.property_guid
			inner join [orm_meta].[properties] as p 
				on i.property_guid = p.property_guid
		where  ((d.value <> i.value) -- only log changes
			 or (d.value is null and i.value is not null)
			 or (d.value is not null and i.value is null)
			 ) and p.no_history = 0
	  end
end
go



if object_id('[orm_meta].[values_decimal_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_decimal_delete]
go

create trigger [orm_meta].[values_decimal_delete]
	on [orm_meta].[values_decimal]
	after delete
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values decimal history') = 0
	  begin
		-- Log the changes to history
		insert into [orm_hist].[values_decimal] 
			  (  instance_guid,   property_guid,   value, transaction_id)
		select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
		from deleted as d
	  end
end
go


-- DATETIME

if object_id('[orm_meta].[values_datetime_insert]', 'TR')  is not null
	drop trigger [orm_meta].[values_datetime_insert]
go

create trigger [orm_meta].[values_datetime_insert]
	on [orm_meta].[values_datetime]
	after insert
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values datetime history') = 0
	  begin
		-- Log the end of missing entry to history
		insert into [orm_hist].[values_datetime] 
			  (  instance_guid,   property_guid, value, transaction_id)
		select i.instance_guid, i.property_guid,  null, CURRENT_TRANSACTION_ID()
		from inserted as i
			inner join [orm_meta].[properties] as p 
				on i.property_guid = p.property_guid
		where p.no_history = 0
	  end
end
go



if object_id('[orm_meta].[values_datetime_update]', 'TR')  is not null
	drop trigger [orm_meta].[values_datetime_update]
go

create trigger [orm_meta].[values_datetime_update]
	on [orm_meta].[values_datetime]
	after update
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values datetime history') = 0
	  begin
		-- Log the changes to history
		insert into [orm_hist].[values_datetime] 
			  (  instance_guid,   property_guid,   value, transaction_id)
		select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
		from deleted as d
			inner join inserted as i 
				on d.instance_guid = i.instance_guid
				and d.property_guid = i.property_guid
			inner join [orm_meta].[properties] as p 
				on i.property_guid = p.property_guid
		where  ((d.value <> i.value) -- only log changes
			 or (d.value is null and i.value is not null)
			 or (d.value is not null and i.value is null)
			 ) and p.no_history = 0
	  end
end
go



if object_id('[orm_meta].[values_datetime_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_datetime_delete]
go

create trigger [orm_meta].[values_datetime_delete]
	on [orm_meta].[values_datetime]
	after delete
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values datetime history') = 0
	  begin
		-- Log the changes to history
		insert into [orm_hist].[values_datetime] 
			  (  instance_guid,   property_guid,   value, transaction_id)
		select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
		from deleted as d
	  end
end
go


-- INSTANCE

if object_id('[orm_meta].[values_instance_insert]', 'TR')  is not null
	drop trigger [orm_meta].[values_instance_insert]
go

create trigger [orm_meta].[values_instance_insert]
	on [orm_meta].[values_instance]
	after insert
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values instance history') = 0
	  begin
		-- Log the end of missing entry to history
		insert into [orm_hist].[values_instance] 
			  (  instance_guid,   property_guid, value, transaction_id)
		select i.instance_guid, i.property_guid,  null, CURRENT_TRANSACTION_ID()
		from inserted as i
			inner join [orm_meta].[properties] as p 
				on i.property_guid = p.property_guid
		where p.no_history = 0
	  end
end
go



if object_id('[orm_meta].[values_instance_update]', 'TR')  is not null
	drop trigger [orm_meta].[values_instance_update]
go

create trigger [orm_meta].[values_instance_update]
	on [orm_meta].[values_instance]
	after update
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values instance history') = 0
	  begin
		-- Log the changes to history
		insert into [orm_hist].[values_instance] 
			  (  instance_guid,   property_guid,   value, transaction_id)
		select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
		from deleted as d
			inner join inserted as i 
				on d.instance_guid = i.instance_guid
				and d.property_guid = i.property_guid
			inner join [orm_meta].[properties] as p 
				on i.property_guid = p.property_guid
		where  ((d.value <> i.value) -- only log changes
			 or (d.value is null and i.value is not null)
			 or (d.value is not null and i.value is null)
			 ) and p.no_history = 0
	  end
end
go



if object_id('[orm_meta].[values_instance_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_instance_delete]
go

create trigger [orm_meta].[values_instance_delete]
	on [orm_meta].[values_instance]
	after delete
as 
begin
	set nocount on;

	if orm_meta.check_context('bypass values instance history') = 0
	  begin
		-- Log the changes to history
		insert into [orm_hist].[values_instance] 
			  (  instance_guid,   property_guid,   value, transaction_id)
		select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
		from deleted as d
	  end
end
go


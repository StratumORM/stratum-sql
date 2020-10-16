print '
Adding value table triggers (for history)...'



if object_id('[orm_meta].[values_string_insert]', 'TR')  is not null
	drop trigger [orm_meta].[values_string_insert]
go

create trigger [orm_meta].[values_string_insert]
	on [orm_meta].[values_string]
	after insert
as 
begin
	set nocount on;

	-- Log the end of missing entry to history
	insert into [orm_hist].[values_string] 
		  (instance_guid, property_guid, value, transaction_id)
	select instance_guid, property_guid,  null, CURRENT_TRANSACTION_ID()
	from inserted
end
go



if object_id('[orm_meta].[values_string_update_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_string_update_delete]
go

create trigger [orm_meta].[values_string_update_delete]
	on [orm_meta].[values_string]
	after update, delete
as 
begin
	set nocount on;

	-- Log the changes to history
	insert into [orm_hist].[values_string] 
		  (  instance_guid,   property_guid,   value, transaction_id)
	select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
	from deleted as d
		inner join inserted as i 
			on d.instance_guid = i.instance_guid
			and d.property_guid = i.property_guid
	where  (d.value <> i.value) -- only log changes
		or (d.value is null and i.value is not null)
		or (d.value is not null and i.value is null)

end
go



if object_id('[orm_meta].[values_integer_insert]', 'TR')  is not null
	drop trigger [orm_meta].[values_integer_insert]
go

create trigger [orm_meta].[values_integer_insert]
	on [orm_meta].[values_integer]
	after insert
as 
begin
	set nocount on;

	-- Log the end of missing entry to history
	insert into [orm_hist].[values_integer] 
		  (instance_guid, property_guid, value, transaction_id)
	select instance_guid, property_guid,  null, CURRENT_TRANSACTION_ID()
	from inserted

end
go



if object_id('[orm_meta].[values_integer_update_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_integer_update_delete]
go

create trigger [orm_meta].[values_integer_update_delete]
	on [orm_meta].[values_integer]
	after update, delete
as 
begin
	set nocount on;

	-- Log the changes to history
	insert into [orm_hist].[values_integer] 
		  (  instance_guid,   property_guid,   value, transaction_id)
	select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
	from deleted as d
		inner join inserted as i 
			on d.instance_guid = i.instance_guid
			and d.property_guid = i.property_guid
	where  (d.value <> i.value) -- only log changes
		or (d.value is null and i.value is not null)
		or (d.value is not null and i.value is null)

end
go



if object_id('[orm_meta].[values_decimal_insert]', 'TR')  is not null
	drop trigger [orm_meta].[values_decimal_insert]
go

create trigger [orm_meta].[values_decimal_insert]
	on [orm_meta].[values_decimal]
	after insert
as 
begin
	set nocount on;

	-- Log the end of missing entry to history
	insert into [orm_hist].[values_decimal] 
		  (instance_guid, property_guid, value, transaction_id)
	select instance_guid, property_guid,  null, CURRENT_TRANSACTION_ID()
	from inserted

end
go



if object_id('[orm_meta].[values_decimal_update_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_decimal_update_delete]
go

create trigger [orm_meta].[values_decimal_update_delete]
	on [orm_meta].[values_decimal]
	after update, delete
as 
begin
	set nocount on;

	-- Log the changes to history
	insert into [orm_hist].[values_decimal] 
		  (  instance_guid,   property_guid,   value, transaction_id)
	select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
	from deleted as d
		inner join inserted as i 
			on d.instance_guid = i.instance_guid
			and d.property_guid = i.property_guid
	where  (d.value <> i.value) -- only log changes
		or (d.value is null and i.value is not null)
		or (d.value is not null and i.value is null)

end
go



if object_id('[orm_meta].[values_datetime_insert]', 'TR')  is not null
	drop trigger [orm_meta].[values_datetime_insert]
go

create trigger [orm_meta].[values_datetime_insert]
	on [orm_meta].[values_datetime]
	after insert
as 
begin
	set nocount on;

	-- Log the end of missing entry to history
	insert into [orm_hist].[values_datetime] 
		  (instance_guid, property_guid, value, transaction_id)
	select instance_guid, property_guid,  null, CURRENT_TRANSACTION_ID()
	from inserted

end
go



if object_id('[orm_meta].[values_datetime_update_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_datetime_update_delete]
go

create trigger [orm_meta].[values_datetime_update_delete]
	on [orm_meta].[values_datetime]
	after update, delete
as 
begin
	set nocount on;

	-- Log the changes to history
	insert into [orm_hist].[values_datetime] 
		  (  instance_guid,   property_guid,   value, transaction_id)
	select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
	from deleted as d
		inner join inserted as i 
			on d.instance_guid = i.instance_guid
			and d.property_guid = i.property_guid
	where  (d.value <> i.value) -- only log changes
		or (d.value is null and i.value is not null)
		or (d.value is not null and i.value is null)

end
go



if object_id('[orm_meta].[values_instance_insert]', 'TR')  is not null
	drop trigger [orm_meta].[values_instance_insert]
go

create trigger [orm_meta].[values_instance_insert]
	on [orm_meta].[values_instance]
	after insert
as 
begin
	set nocount on;

	-- Log the end of missing entry to history
	insert into [orm_hist].[values_instance] 
		  (instance_guid, property_guid, value, transaction_id)
	select instance_guid, property_guid,  null, CURRENT_TRANSACTION_ID()
	from inserted

end
go



if object_id('[orm_meta].[values_instance_update_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_instance_update_delete]
go

create trigger [orm_meta].[values_instance_update_delete]
	on [orm_meta].[values_instance]
	after update, delete
as 
begin
	set nocount on;

	-- Log the changes to history
	insert into [orm_hist].[values_instance] 
		  (  instance_guid,   property_guid,   value, transaction_id)
	select d.instance_guid, d.property_guid, d.value, CURRENT_TRANSACTION_ID()
	from deleted as d
		inner join inserted as i 
			on d.instance_guid = i.instance_guid
			and d.property_guid = i.property_guid
	where  (d.value <> i.value) -- only log changes
		or (d.value is null and i.value is not null)
		or (d.value is not null and i.value is null)

end
go


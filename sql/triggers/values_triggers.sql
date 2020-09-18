print '
Adding value table triggers (for history)...'


if object_id('[orm_meta].[values_string_update_delete]', 'TR')  is not null
	drop trigger [orm_meta].[values_string_update_delete]
go

create trigger [orm_meta].[values_string_update_delete]
	on [orm_meta].[values_string]
	after update, delete
as 
begin

	-- Log the changes to history
	insert into [orm_hist].[values_string] 
		  (instance_guid, property_guid, value, transaction_id)
	select instance_guid, property_guid, value, CURRENT_TRANSACTION_ID()
	from deleted

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

	-- Log the changes to history
	insert into [orm_hist].[values_integer] 
		  (instance_guid, property_guid, value, transaction_id)
	select instance_guid, property_guid, value, CURRENT_TRANSACTION_ID()
	from deleted

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

	-- Log the changes to history
	insert into [orm_hist].[values_decimal] 
		  (instance_guid, property_guid, value, transaction_id)
	select instance_guid, property_guid, value, CURRENT_TRANSACTION_ID()
	from deleted

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

	-- Log the changes to history
	insert into [orm_hist].[values_datetime] 
		  (instance_guid, property_guid, value, transaction_id)
	select instance_guid, property_guid, value, CURRENT_TRANSACTION_ID()
	from deleted

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

	-- Log the changes to history
	insert into [orm_hist].[values_instance] 
		  (instance_guid, property_guid, value, transaction_id)
	select instance_guid, property_guid, value, CURRENT_TRANSACTION_ID()
	from deleted

end
go


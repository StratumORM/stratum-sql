print '
Adding instance table triggers (for history)...'



if object_id('[orm_meta].[instances_insert]', 'TR')  is not null
	drop trigger [orm_meta].[instances_insert]
go

create trigger [orm_meta].[instances_insert]
	on [orm_meta].[instances]
	after insert
as 
begin
	set nocount on;

	-- Log the end of missing entry to history
	insert into [orm_hist].[instances] 
		  (instance_id, instance_guid, template_guid, name, signature, transaction_id)
	select instance_id, instance_guid,          null, null,      null, CURRENT_TRANSACTION_ID()
	from inserted
end
go



if object_id('[orm_meta].[instances_update_delete]', 'TR')  is not null
	drop trigger [orm_meta].[instances_update_delete]
go

create trigger [orm_meta].[instancs_update_delete]
	on [orm_meta].[instances]
	after update, delete
as 
begin
	set nocount on;

	-- Log the changes to history
	insert into [orm_hist].[instances] 
		  (instance_id, instance_guid, template_guid, name, signature, transaction_id)
	select instance_id, instance_guid, template_guid, name, signature, CURRENT_TRANSACTION_ID()
	from deleted

end
go

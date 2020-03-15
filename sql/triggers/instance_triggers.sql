print '
Adding instance table triggers (for history)...'


if object_id('[orm_meta].[instance_update_delete]', 'TR')  is not null
	drop trigger [orm_meta].[instance_update_delete]
go

create trigger [orm_meta].[instance_update_delete]
	on [orm_meta].[instances]
	after update, delete
as 
begin

	-- Log the changes to history
	insert into [orm_hist].[instances] 
		  (instance_id, template_id, name, signature)
	select instance_id, template_id, name, signature
	from deleted

end
go

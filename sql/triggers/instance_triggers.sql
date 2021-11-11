print '
Adding instance table triggers (for history)...'



if object_id('[orm_meta].[instances_insert]', 'TR')  is not null
	drop trigger [orm_meta].[instances_insert]
go

create trigger [orm_meta].[instances_insert]
	on [orm_meta].[instances]
	instead of insert
as 
begin
	set nocount on;

	-- Merge it into the instances table
	set identity_insert [orm_meta].[instances] on; -- merge statement manages id

	merge into [orm_meta].[instances] as d 
		using (	select 	ident_current('[orm_meta].[instances]') 
			            + row_number() over (order by instance_guid) 
			            as instance_id
					,	instance_guid
					,	template_guid
					,	name
					,	signature
				from inserted 
				-- where instance_id = 0
			) as s 
		on d.instance_guid = s.instance_guid
	when not matched then
		insert (  instance_id, instance_guid,   template_guid,   name,   signature)
		values (s.instance_id, instance_guid, s.template_guid, s.name, s.signature)
	when matched then
		update set 
		--	instance_id = s.instance_id -- this can't be updated since it's the table's PK
			name = s.name
		,	signature = s.signature
	;

	set identity_insert [orm_meta].[instances] off;


	-- Log the end of missing entry to history
	insert into [orm_hist].[instances] 
		  (instance_id, instance_guid, template_guid, name, signature, transaction_id)
	select instance_id, instance_guid,          null, null,      null, CURRENT_TRANSACTION_ID()
	from inserted

end
go



if object_id('[orm_meta].[instances_update]', 'TR')  is not null
	drop trigger [orm_meta].[instances_update]
go

create trigger [orm_meta].[instances_update]
	on [orm_meta].[instances]
	instead of update
as 
begin
	set nocount on;

	-- Perform the update
	update o 
	set  	o.name = i.name
		,	o.signature = i.signature
	from [orm_meta].[instances] as o
		inner join inserted as i
			on o.instance_guid = i.instance_guid

	-- Log the changes to history
	insert into [orm_hist].[instances] 
		  (  instance_id,   instance_guid,   template_guid,   name,   signature, transaction_id)
	select d.instance_id, d.instance_guid, d.template_guid, d.name, d.signature, CURRENT_TRANSACTION_ID()
	from deleted as d
		inner join inserted as i
			on d.instance_guid = i.instance_guid
	where ( (d.name <> i.name) -- only log changes
		 or (d.name is null and i.name is not null)
		 or (d.name is not null and i.name is null) )
	   or ( (d.signature <> i.signature) 
		 or (d.signature is null and i.signature is not null)
		 or (d.signature is not null and i.signature is null) )
end
go




if object_id('[orm_meta].[instances_update_delete]', 'TR')  is not null
	drop trigger [orm_meta].[instances_delete]
go

create trigger [orm_meta].[instances_delete]
	on [orm_meta].[instances]
	instead of delete
as 
begin
	set nocount on;

	declare @deleted_instances identities

	insert into @deleted_instances (guid)
	select instance_guid
	from deleted as d
		
	-- First, to maintain FKs,
	--   cascade delete values for the removed instances
	exec [orm_meta].[cascade_delete_instance] @deleted_instances

	-- _then_ delete the instance (pillage first, then burn)
	delete o 
	from [orm_meta].[instances] as o
		inner join deleted as d
			on o.instance_guid = d.instance_guid


	-- Log the changes to history
	insert into [orm_hist].[instances] 
		  (instance_id, instance_guid, template_guid, name, signature, transaction_id)
	select instance_id, instance_guid, template_guid, name, signature, CURRENT_TRANSACTION_ID()
	from deleted

end
go

print '
Adding template table triggers...'



if object_id('[orm_meta].[templates_insert]', 'TR')  is not null
	drop trigger [orm_meta].[templates_insert]
go

create trigger [orm_meta].[templates_insert]
	on [orm_meta].[templates]
	instead of insert
as 
begin
	set nocount on;

	-- Make sure the template_name is legal (since this will go into dynamic sql)
	-- select i.name
	-- from inserted as i
	-- where i.name <> [orm_meta].[sanitize_string](i.name)
	-- if @@ROWCOUNT <> 0 
	-- 	begin
	-- 		rollback transaction		
	-- 		raiserror('Template name not purely alphanumeric.', 16, 10)
	-- 		return
	-- 	end	

	-- Make sure it doesn't already exist
	if (
		select t.template_guid 
		from [orm_meta].[templates] as t
			inner join inserted as i
				on t.name = i.name
		) is not null
		begin
			rollback transaction		
			raiserror('Template already exists.', 16, 1)
			return
		end	

	-- Now insert it into the templates table
	insert into [orm_meta].[templates] (name, signature)
	select i.name, i.signature
	from inserted as i

	-- Loop over all the template names that were affected by the insert
	declare @template_guid uniqueidentifier

	declare template_guid_cursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct t.template_guid
		from inserted as i
			inner join [orm_meta].[templates] as t
				on t.name = i.name
	
	open template_guid_cursor

	fetch next from template_guid_cursor into @template_guid
	
	while @@FETCH_STATUS = 0
	begin
		exec [orm_meta].[generate_template_view_wide] @template_guid

		fetch next from template_guid_cursor into @template_guid
	end
	close template_guid_cursor 
	deallocate template_guid_cursor

	-- Log the end of missing entry to history
	insert into [orm_hist].[templates] 
		  (template_id, template_guid, name, signature, transaction_id)
	select template_id, template_guid, null,      null, CURRENT_TRANSACTION_ID()
	from inserted

end
go


if object_id('[orm_meta].[templates_update]', 'TR')  is not null
	drop trigger [orm_meta].[templates_update]
go

create trigger [orm_meta].[templates_update]
	on [orm_meta].[templates]
	instead of update
as 
begin
	set nocount on;

	-- Make sure the template_name is legal (since this will go into dynamic sql)
	-- select i.name
	-- from inserted as i
	-- where i.name <> [orm_meta].[sanitize_string](i.name)
	-- if @@ROWCOUNT <> 0 
	-- 	begin
	-- 		rollback transaction		
	-- 		raiserror('Template name not purely alphanumeric.', 16, 10)
	-- 		return
	-- 	end	

	-- Perform the update
	update t
	set 	t.name = i.name
		,	t.signature = i.signature
	from [orm_meta].[templates] as t
		inner join inserted as i 
			on t.template_guid = i.template_guid

	-- Loop over all the template names that were affected by the update
	declare @template_name nvarchar(250), @template_guid uniqueidentifier, @drop_query nvarchar(max)

	declare template_cursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct d.name, i.template_guid
		from deleted as d
			inner join inserted as i
				on d.template_guid = i.template_guid
		where d.name <> i.name
	
	open template_cursor

	fetch next from template_cursor into @template_name, @template_guid
	
	while @@FETCH_STATUS = 0
	begin

		set @drop_query = 'drop view ' + QUOTENAME(@template_name)
		exec sp_executesql @drop_query

		exec [orm_meta].[generate_template_view_wide] @template_guid

		fetch next from template_cursor into @template_name, @template_guid
	end
	close template_cursor 
	deallocate template_cursor

	-- Log the changes to history
	insert into [orm_hist].[templates] 
		  (  template_id,   template_guid,   name,   signature, transaction_id)
	select d.template_id, d.template_guid, d.name, d.signature, CURRENT_TRANSACTION_ID()
	from deleted as d
		inner join inserted as i 
			on d.template_guid = i.template_guid
	where ( (d.name <> i.name) -- only log changes
		 or (d.name is null and i.name is not null)
		 or (d.name is not null and i.name is null) )
	   or ( (d.signature <> i.signature) 
		 or (d.signature is null and i.signature is not null)
		 or (d.signature is not null and i.signature is null) )
end
go


if object_id('[orm_meta].[templates_delete]', 'TR')  is not null
	drop trigger [orm_meta].[templates_delete]
go

create trigger [orm_meta].[templates_delete]
	on [orm_meta].[templates]
	instead of delete
as 
begin
	set nocount on;

	-- We need to make sure that the base templates are never deleted. So we'll mask the special
	--	deleted table like the properties trigger manipulates them
	declare @deleted table (
				template_guid uniqueidentifier
			, 	name nvarchar(250)
			,	signature nvarchar(max)
			,	primary key (template_guid) )
		insert @deleted (template_guid, name, signature)
		select template_guid, name, signature
		from deleted

		if (select min(template_guid) from deleted) <= 0x00000000000000000000000000000004 raiserror('Can not delete base templates. Other templates will be deleted, if any (otherwise error escalates rollback).',5,20)

		delete d
		from @deleted as d
		where template_guid <= 0x00000000000000000000000000000004

		-- Sound a warning if this is the only data that was deleted
		-- But we'll silently ignore these templates otherwise.
		if (not exists(	select * from @deleted as d)) 
			begin
				rollback transaction
				return
			end			

	-- Get the list of the affected templates
	declare @affected_template_guids identities, @property_guids identities, @child_templates identities
		insert into @affected_template_guids (guid)
		select distinct tree.template_guid
		from @deleted as d
			cross apply [orm_meta].[template_tree](d.template_guid) as tree

		insert into @child_templates (guid)
		select distinct i.child_template_guid
		from [orm_meta].[inheritance] as i
			inner join @deleted as d
				on i.parent_template_guid = d.template_guid

	-- If this template is the sole source of a base property, then we'll need
	--  to purge that property from the children as well
	-- So first, find out what properties *may* be affected...
	insert into @property_guids (guid)
	select m.current_property_guid
	from [orm_meta].[resolve_properties](@affected_template_guids) as m
		inner join @deleted as d 
			on m.masked_template_guid = d.template_guid 
	where isnull(m.masked_is_extended,0) = 0

	-- first delete the properties ... (which will cascade deletes to the values)
	delete p
	from [orm_meta].[properties] as p 
		inner join @deleted as d 
			on p.template_guid = d.template_guid 

	-- then delete the instances ...
	delete o
	from [orm_meta].[instances] as o 
		inner join @deleted as d 
			on o.template_guid = d.template_guid

	-- and update the children to inherit from the template's parents, if any
	declare @my_ordinal_insert table (my_guid uniqueidentifier, my_offset int)
		insert into @my_ordinal_insert (my_guid, my_offset)
		select d.template_guid, count(i.ordinal)
		from @deleted as d 
			inner join [orm_meta].[inheritance] as i
				on d.template_guid = i.child_template_guid
		group by d.template_guid

	-- We'll need to bump the other inherited templates to make room for the insert	
	; with my_children as
	(
		select d.template_guid as my_guid, i.child_template_guid, i.ordinal as my_ordinal
		from [orm_meta].[inheritance] as i
			inner join @deleted as d
				on i.parent_template_guid = d.template_guid
	)	
	update i 
	set i.ordinal = i.ordinal + o.my_offset --not off by one		
	from [orm_meta].[inheritance] as i 
		inner join my_children as c 
			on i.child_template_guid = c.child_template_guid
		inner join @my_ordinal_insert as o 
			on c.my_guid = o.my_guid
	where i.ordinal >= c.my_ordinal 

	--
	-- The grandfather paradox is tripped here 
	--	if the template has dependents and parents.	
	--

	-- ... and with that room, we can now insert the new inherited links

	; with	my_parents as
	(
		select 	d.template_guid as my_guid
			,	i.parent_template_guid
			,	dense_rank() over (partition by d.template_guid order by ordinal) as ordinal
		from [orm_meta].[inheritance] as i
			inner join @deleted as d
				on i.child_template_guid = d.template_guid	
	)
	,	my_children as
	(
		select 	d.template_guid as my_guid
			,	i.child_template_guid
			,	ordinal
		from [orm_meta].[inheritance] as i
			inner join @deleted as d
				on i.parent_template_guid = d.template_guid
	)
	,	new_relationship as
	(
		select 	p.parent_template_guid
			,	c.child_template_guid
			,	c.ordinal + o.my_offset as ordinal
		from my_parents as p 
			inner join my_children as c 
				on p.my_guid = c.my_guid
			inner join @my_ordinal_insert as o 
				on p.my_guid = o.my_guid
	)
	merge into [orm_meta].[inheritance] as d 
	using (	select 	r.parent_template_guid
				,	r.child_template_guid
				,	r.ordinal
			from new_relationship as r) as s 
		on  d.parent_template_guid = s.parent_template_guid
		and d.child_template_guid  = s.child_template_guid
	when matched then
		update 
		set d.ordinal = s.ordinal
	when not matched then
		insert (  parent_template_guid,   child_template_guid,   ordinal)
		values (s.parent_template_guid, s.child_template_guid, s.ordinal)
	;

	-- Notice that we didn't have an off-by-one error above: we intentionally
	--	jump over the current relationship's ordinal so that when we delete
	-- 	this one, the old ones will be immediately exposed (and no ordinal collisions)
	delete i
	from [orm_meta].[inheritance] as i
		inner join @deleted as d 
			on 	child_template_guid = d.template_guid 
			or 	parent_template_guid = d.template_guid	

	-- then finally delete the template ...
	delete t 
	from [orm_meta].[templates] as t
		inner join @deleted as d 
			on t.template_guid = d.template_guid

	-- And now check if a new template has stepped up to cover some or all of those properties.
	-- We do that by checking if the masking template for those saved properties 
	-- 	inherited from the one getting deleted
	delete from @property_guids
	where guid not in (	
		select m.current_property_guid
		from @property_guids as p
			inner join [orm_meta].[resolve_properties](@affected_template_guids) as m
				on m.current_property_guid = p.guid
			inner join @child_templates as c 
				on m.masked_template_guid = c.guid 
		)

	-- Deletes will cascade once the properties trigger fires
	delete p
	from [orm_meta].[properties] as p
		inner join @property_guids as pids 
			on p.property_guid = pids.guid

	-- Finally, loop over all the template names that were affected by the delete
	declare @template_name varchar(250), @drop_query nvarchar(max)

		select distinct d.name
		from @deleted as d

	-- from http://stackoverflow.com/a/18514133
	declare template_name_cursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct d.name
		from @deleted as d
	
	open template_name_cursor

	fetch next from template_name_cursor into @template_name
	
	while @@FETCH_STATUS = 0
	begin

		set @drop_query = 'drop view ' + QUOTENAME(@template_name)
		exec sp_executesql @drop_query

		fetch next from template_name_cursor into @template_name
	end
	close template_name_cursor 
	deallocate template_name_cursor

	-- Log the changes to history
	insert into [orm_hist].[templates] 
		  (template_id, template_guid, name, signature, transaction_id)
	select template_id, template_guid, name, signature, CURRENT_TRANSACTION_ID()
	from deleted

end
go

print '
Adding property table triggers...'



if object_id('[orm_meta].[properties_insert]', 'TR')  is not null
	drop trigger [orm_meta].[properties_insert]
go

create trigger [orm_meta].[properties_insert]
	on [orm_meta].[properties]
	instead of insert
as 
begin

	declare @template_ids identities
		insert into @template_ids
		select distinct
			tree.template_id
		from inserted as i
			cross apply [orm_meta].[template_tree](i.template_id) as tree

	-- Referential integrity checks (needed instead of foreign keys due to constraint checks coming before triggers)
	if (exists(	select i.template_id
				from [orm_meta].[templates] as t
					right join inserted as i
						on t.template_id = i.template_id
				where t.template_id is null)) 
		begin
			rollback transaction
			raiserror('Can not insert property due to invalid template_id.', 16, 5)
			return
		end

	if (exists(	select i.datatype_id
				from [orm_meta].[templates] as t
					right join inserted as i
						on t.template_id = i.datatype_id
				where t.template_id is null)) 
		begin
			rollback transaction
			raiserror('Can not insert property due to invalid datatype template_id.', 16, 6)
			return
		end

	-- Check that no property inserted already exists.
	if (exists(	select i.property_id
				from inserted as i
					inner join [orm_meta].[properties] as p
						on	i.template_id = p.template_id
						and i.name = p.name))
		begin
			rollback transaction	
			raiserror('Can not insert duplicate property.', 16, 1)
			return
		end

	-- Verify the names are safe
	-- if (exists(	select i.property_id
	-- 			from inserted as i
	-- 			where i.name <> [orm_meta].[sanitize_string](i.name) ))
	-- 	begin
	-- 		rollback transaction	
	-- 		raiserror('Property name is not purely alphanumeric.', 16, 10)
	-- 		return
	-- 	end

	-- To further simplify things, this procedure will use a table variable so we can more easily reference
	--	and massage the masked property data.
	declare @masking table (scoped_template_id int,
							masking_property_id int, masking_template_id int, masking_name varchar(250), masking_datatype_id int, masking_is_extended int, masking_signature nvarchar(max),
							current_property_id int, current_template_id int, current_name varchar(250), current_datatype_id int, current_is_extended int, current_signature nvarchar(max))

	-- Insert the rows
	insert into [orm_meta].[properties] (template_id, name, datatype_id, is_extended, signature)
	select template_id, name, datatype_id, is_extended, signature
	from inserted as i

	-- Now that we have new properties, we need to make sure that these are inherited properly.
	-- First, we resolve how the affected template's properties are masked.
	
	-- Get the current masked properties
	insert into @masking (	scoped_template_id,
							masking_property_id, masking_template_id, masking_name, masking_datatype_id, masking_is_extended, masking_signature,
							current_property_id, current_template_id, current_name, current_datatype_id, current_is_extended, current_signature)
	select	
			p.scoped_template_id
		,	p.masked_property_id
		,	p.masked_template_id
		,	p.masked_name
		,	p.masked_datatype_id
		,	p.masked_is_extended
		,	p.masked_signature

		,	p.current_property_id
		,	p.current_template_id
		,	p.current_name
		,	p.current_datatype_id
		,	p.current_is_extended
		,	p.current_signature	
	from [orm_meta].[resolve_properties](@template_ids) as p

	-- Next, we need to perform a sanity check. 
	-- If a child is inheriting a property datatype change, then fail the transaction.
	-- I want to do this because it should never happen in a sane situation,
	--  and it would be so destructive and easy that it would be better to just fail
	--  than risk the extremely likely case that it was an accident.
	if (exists(	select m.current_property_id
				from @masking as m
				where m.current_datatype_id <> m.masking_datatype_id 
					and m.current_datatype_id is not null ))
		raiserror('Adding a new property that conflicts with the datatype of an existing subtemplate''s property is not allowed. Sorry.', 16, 1)

	-- Merge in the missing properties, inserting any properties that don't already exist
	--	... but only the ones that *need* to
	merge into [orm_meta].[properties] as d
	using (	select	m.current_property_id as property_id
				,	m.scoped_template_id as template_id
				,	m.masking_name as name
				,	m.masking_datatype_id as datatype_id
				,	m.masking_is_extended as is_extended
				,	m.masking_signature as [signature]
			from @masking as m
			where isnull(m.masking_is_extended, 0) = 0) as s 
		on d.property_id = s.property_id
	when not matched then
		insert (template_id, name, datatype_id, is_extended, signature)
		values (s.template_id, s.name, s.datatype_id, s.is_extended, s.signature)
	;

	-- Finally, loop over all the template_ids that were affected by the insert/delete
	declare @template_id int

	-- from http://stackoverflow.com/a/18514133
	declare template_idcursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct id
		from @template_ids as t
	
	open template_idcursor

	fetch next from template_idcursor into @template_id
	
	while @@FETCH_STATUS = 0
	begin
		exec [orm_meta].[generate_template_view_wide] @template_id

		fetch next from template_idcursor into @template_id
	end
	close template_idcursor 
	deallocate template_idcursor

end
go



if object_id('[orm_meta].[properties_update]', 'TR')  is not null
	drop trigger [orm_meta].[properties_update]
go

create trigger [orm_meta].[properties_update]
	on [orm_meta].[properties]
	instead of update
as 
begin
	
	declare @inserted table (property_id int, template_id int, name varchar(250), datatype_id int, is_extended int, signature nvarchar(max), primary key (property_id))
	declare @deleted table (property_id int, template_id int, name varchar(250), datatype_id int, is_extended int, signature nvarchar(max), primary key (property_id))

		insert @inserted (property_id, template_id, name, datatype_id, is_extended, signature)
		select property_id, template_id, name, datatype_id, is_extended, signature
		from inserted

		insert @deleted (property_id, template_id, name, datatype_id, is_extended, signature)
		select property_id, template_id, name, datatype_id, is_extended, signature
		from deleted

	-- Referential integrity checks (needed instead of foreign keys due to constraint checks coming before triggers)
	if (exists(	select i.template_id
				from [orm_meta].[templates] as t
					right join inserted as i
						on t.template_id = i.template_id
				where t.template_id is null)) 
		begin
			rollback transaction	
			raiserror('Can not insert property due to invalid template_id.', 16, 5)
			return
		end	
		
	if (exists(	select i.datatype_id
				from [orm_meta].[templates] as t
					right join inserted as i
						on t.template_id = i.datatype_id
				where t.template_id is null)) 
		begin
			rollback transaction	
			raiserror('Can not insert property due to invalid data template_id.', 16, 6)	
			return
		end	
		
	-- Check that no property inserted already exists.
	-- (and make sure we're not merely double counting one that is merely changing )
	if (exists(	select i.property_id
				from inserted as i
					inner join [orm_meta].[properties] as p
						on	i.template_id = p.template_id
						and i.name = p.name
				where i.property_id not in (	select d.property_id
											from deleted as d 
											where d.template_id = i.template_id
												and d.name = i.name )	))
		begin
			rollback transaction		
			raiserror('Can not insert duplicate property.', 16, 1)
			return
		end	

	-- Verify the names are safe
	-- if (exists(	select i.property_id
	-- 			from inserted as i
	-- 			where i.name <> [orm_meta].[sanitize_string](i.name) ))
	-- 	begin
	-- 		rollback transaction		
	-- 		raiserror('Property name is not purely alphanumeric.', 16, 10)
	-- 		return
	-- 	end	

	-- To make things simpler, the query that generates the report on what properties are masked is
	--	abstracted out to a table valued function. These have the restriction that we can only pass in 
	--	parameters of a known template. So we need to generate a list of the affected templates in a special table template.
	declare @template_ids identities, @scoped_ids identities, @deleted_properties identities
		insert into @template_ids
		select distinct
			t.template_id
		from (	select template_id from @inserted as i
				union
				select template_id from @deleted as d) as t

	-- To further simplify things, this procedure will use a table variable so we can more easily reference
	--	and massage the masked property data.
	declare @masking table (scoped_template_id int,
							masking_property_id int, masking_template_id int, masking_name varchar(250), masking_datatype_id int, masking_is_extended int, masking_signature nvarchar(max),
							current_property_id int, current_template_id int, current_name varchar(250), current_datatype_id int, current_is_extended int, current_signature nvarchar(max))

	-- Get the current masked properties
	insert into @masking (	scoped_template_id,
							masking_property_id, masking_template_id, masking_name, masking_datatype_id, masking_is_extended, masking_signature,
							current_property_id, current_template_id, current_name, current_datatype_id, current_is_extended, current_signature)
	select	
			p.scoped_template_id
		,	p.masked_property_id
		,	p.masked_template_id
		,	p.masked_name
		,	p.masked_datatype_id
		,	p.masked_is_extended
		,	p.masked_signature

		,	p.current_property_id
		,	p.current_template_id
		,	p.current_name
		,	p.current_datatype_id
		,	p.current_is_extended
		,	p.current_signature	
	from [orm_meta].[resolve_properties](@template_ids) as p

	-- Grab the templates that are going to potentially be affected by the changes.
	-- We'll use this later to rebuild the wide views.
	insert into @scoped_ids (id)
	select distinct scoped_template_id
	from @masking as m

	-- Purge any values where the datatype is changing.
	-- Be sure to get rid of any sub-templates that are being covered by this property.
	-- That is, from our properties table, find what current properties
	--	are covered by a mask that is changing templates.
	-- Cascading deletes will take 'care' of the values currently associated with them.
	delete p
	output deleted.property_id into @deleted_properties -- deleted is scoped to THIS statement!
	from [orm_meta].[properties] as p
		inner join @masking as m
			on p.property_id = m.current_property_id
		inner join @inserted as i
			on i.property_id = m.masking_property_id
		inner join @deleted as d
			on i.property_id = d.property_id
	where i.datatype_id <> d.datatype_id

	-- Cascade delete the removed properties
	exec [orm_meta].[cascade_delete_property] @deleted_properties
	-- Reset for next deletion
	delete from @deleted_properties

	-- Before we merge into @masking the @inserted row updates,
	--	we need to make sure that inserted won't merely add
	--	pointless new masks (since the merge happens on *masked*, not *current*.)
	-- If we find that we're about to merge in something that's already covered,
	--	remove it from @inserted.
	merge into @inserted as d
	using (	select	current_property_id
				,	masking_property_id
			from @masking as m) as s 
		on	d.property_id = s.current_property_id
		and	s.masking_property_id <> s.current_property_id
	when matched then
		delete
	;

	-- Update the masks to what the inserted table tells us the changes are.
	-- Note that the @masking variable currently holds the same data as deleted
	--	(since it referenced the same table from the same point in time).
	merge into @masking as d
	using (	select	i.property_id
				,	i.template_id
				,	i.name
				,	i.datatype_id
				,	i.is_extended
				,	i.signature
			from @inserted as i ) as s
		on d.masking_property_id = s.property_id
	when matched then
		update
		set		d.masking_name = s.name
			,	d.masking_is_extended = (
					case
						-- when setting to base and currently not a base property, make base
						when s.is_extended = 0 and d.current_is_extended <> 0
						then	0
					
						-- when setting not base and mask is base, override to base
						when s.is_extended <> 0 and d.masking_is_extended = 0
						then	0
					
						-- otherwise just accept the value
						else	isNull(s.is_extended, 0)
					end)
			,	d.masking_signature = s.signature
	when not matched then
		insert	(	scoped_template_id	
				,	masking_property_id
				,	masking_template_id
				,	masking_name
				,	masking_datatype_id
				,	masking_is_extended
				,	masking_signature	)
		values	(	s.template_id		--	this is necessarily the same as s.template_id
				,	s.property_id	--	since we got the in_scope_ids from here!
				,	s.template_id
				,	s.name
				,	s.datatype_id
				,	s.is_extended
				,	s.signature	)
	;

	-- If a property is being overwritten (since we follow violent pigeonholing), 
	--	we need to purge the now-covered property.
	-- We do this by checking if the mask now effectively has a duplicate entry.
	-- The signature of this is there will be a duplicate entry for a scoped_template_id
	--	where one entry has a masking_template_id the same as current_template_id.
	-- If we have one like that, we take that entry and delete it from the properties table.
	declare @dead_pigeons identities
	; with contested_pigeonhole as
	(
		select m.scoped_template_id, m.masking_name
		from @masking as m
		group by m.scoped_template_id, m.masking_name
		having count(m.scoped_template_id) > 1
	)
	,	property_getting_pushed_out as
	(
		select m.current_property_id as dead_pigeon
		from contested_pigeonhole as cp
			inner join @masking as m
				on	m.scoped_template_id = cp.scoped_template_id
				and	m.masking_name = cp.masking_name
		where m.current_template_id = m.masking_template_id
	)
	insert into @dead_pigeons (id)
	select pgpo.dead_pigeon
	from property_getting_pushed_out as pgpo
	
	-- removed these displaced properties from both the main table...
	delete p
	output deleted.property_id into @deleted_properties -- deleted is scoped to THIS statement!		
	from [orm_meta].[properties] as p
		inner join @dead_pigeons as dp
			on p.property_id = dp.id
	-- ... and the mask (to make sure they're not just re-inserted!)
	delete m
	from @masking as m
		inner join @dead_pigeons as dp
			on m.masking_property_id = dp.id

	-- Cascade delete the removed properties
	exec [orm_meta].[cascade_delete_property] @deleted_properties
	-- Reset for next deletion
	delete from @deleted_properties			

	-- Update the properties table to this corrected mask.
	-- This is the first set of two corrections.
	-- Once this is applied, we'll double check the masking again to see
	--	if any new properties were uncovered. If so, add these in.
	merge into [orm_meta].[properties] as d
	using (	select	scoped_template_id
				,	masking_property_id
				,	masking_template_id
				,	masking_name
				,	masking_datatype_id
				,	masking_is_extended
				,	masking_signature
				,	current_property_id
				,	current_template_id
				,	current_name
				,	current_datatype_id
				,	current_is_extended
				,	current_signature
			from @masking as m	) as s 
		on d.property_id = s.current_property_id
	when matched then
		update
		set		d.name = s.masking_name
			--,	d.datatype_id = s.datatype_id -- we can ignore this since we've already deleted the changed ones
			
			-- Q: Do we change our is_extended propery?
			-- A: ONLY if the masking is_extended property is 0 or NULL
			,	d.is_extended = (
					case
						when s.masking_is_extended = 0 
						then	0
						else	isnull(s.current_is_extended, 0)
					end)
			,	d.signature = s.current_signature
	when not matched then
		insert	(	template_id
				,	name
				,	datatype_id
				,	is_extended
				,	signature	)
		values	(	scoped_template_id
				,	masking_name
				,	masking_datatype_id
				,	masking_is_extended
				,	masking_signature	)
	;

	-- Reset the mask to prepare for final checks
	delete from @masking

	-- Get the current masked properties so we can double check the base properties are masked correctly.
	insert into @masking (	scoped_template_id,
							masking_property_id, masking_template_id, masking_name, masking_datatype_id, masking_is_extended, masking_signature,
							current_property_id, current_template_id, current_name, current_datatype_id, current_is_extended, current_signature)
	select	
			p.scoped_template_id
		,	p.masked_property_id
		,	p.masked_template_id
		,	p.masked_name
		,	p.masked_datatype_id
		,	p.masked_is_extended
		,	p.masked_signature

		,	p.current_property_id
		,	p.current_template_id
		,	p.current_name
		,	p.current_datatype_id
		,	p.current_is_extended
		,	p.current_signature	
	from [orm_meta].[resolve_properties](@template_ids) as p

	-- The final pass here will do two things:
	--  1) add new properties that were uncovered by the previous merge
	--	2) re-solve and verify if properties are optional (which may have changed)
	-- This merge is simpler since the only properties that can be wrong are either missing
	--	or are marked (non)optional.
	merge into [orm_meta].[properties] as d
	using (	select	scoped_template_id
				,	masking_property_id
				,	masking_template_id
				,	masking_name
				,	masking_datatype_id
				,	masking_is_extended
				,	masking_signature
				,	current_property_id
				,	current_template_id
				,	current_name
				,	current_datatype_id
				,	current_is_extended
				,	current_signature
			from @masking as m	) as s 
		on d.property_id = s.current_property_id
	when matched then
		update	-- override properties as non-optional if their parent says so
		set		d.is_extended = (
					case 
						when s.masking_is_extended = 0 
						then	0
						else	isnull(s.current_is_extended, 0)
					end	)
	when not matched then
		insert	(	template_id
				,	name
				,	datatype_id
				,	is_extended
				,	signature	)
		values	(	scoped_template_id
				,	masking_name
				,	masking_datatype_id
				,	masking_is_extended
				,	masking_signature	)
	;

	-- Finally, loop over all the template_ids that were affected by the insert/delete
	declare @template_id int

	-- from http://stackoverflow.com/a/18514133
	declare template_idcursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct id
		from @scoped_ids as t
	
	open template_idcursor

	fetch next from template_idcursor into @template_id
	
	while @@FETCH_STATUS = 0
	begin
		exec [orm_meta].[generate_template_view_wide] @template_id

		fetch next from template_idcursor into @template_id
	end
	close template_idcursor 
	deallocate template_idcursor

	-- Log the changes to history
	insert into [orm_hist].[properties] 
		  (property_id, template_id, name, datatype_id, is_extended, signature, transaction_id)
	select property_id, template_id, name, datatype_id, is_extended, signature, CURRENT_TRANSACTION_ID()
	from deleted

end
go


if object_id('[orm_meta].[properties_delete]', 'TR')  is not null
	drop trigger [orm_meta].[properties_delete]
go

create trigger [orm_meta].[properties_delete]
	on [orm_meta].[properties]
	instead of delete
as 
begin

	declare @template_ids identities, @deleted_properties identities
	insert into @template_ids
	select distinct
		tree.template_id
	from deleted as d
		cross apply [orm_meta].[template_tree](d.template_id) as tree

	-- Only allow deletion for properties that are uncovered!
	--	and be sure to get children masked by it as well!
	; with involved_properties as
	(
		select m.masked_property_id, m.masked_template_id, m.current_property_id, m.current_template_id
		from [orm_meta].[resolve_properties](@template_ids) as m
	)
	,	uncovered as
	(
		select	p.current_property_id as property_id
		from deleted as d
			inner join involved_properties as p
				on d.property_id = p.masked_property_id	-- Delete the rows and anything they mask.
				or d.property_id = p.current_property_id	-- If it's behaving like a mask, the masked property ID is already
	)													-- the top-most one.
	delete p
	output deleted.property_id into @deleted_properties -- deleted is scoped to THIS statement!		
	from [orm_meta].[properties] as p 
		inner join uncovered as u
			on p.property_id = u.property_id

	-- Cascade delete the removed properties
	exec [orm_meta].[cascade_delete_property] @deleted_properties

	-- Finally, loop over all the template_ids that were affected by the insert/delete
	declare @template_id int

	-- from http://stackoverflow.com/a/18514133
	declare template_idcursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct id
		from @template_ids as t
	
	open template_idcursor

	fetch next from template_idcursor into @template_id
	
	while @@FETCH_STATUS = 0
	begin
		exec [orm_meta].[generate_template_view_wide] @template_id

		fetch next from template_idcursor into @template_id
	end
	close template_idcursor 
	deallocate template_idcursor

	-- Log the changes to history
	insert into [orm_hist].[properties] 
		  (property_id, template_id, name, datatype_id, is_extended, signature, transaction_id)
	select property_id, template_id, name, datatype_id, is_extended, signature, CURRENT_TRANSACTION_ID()
	from deleted

end
go

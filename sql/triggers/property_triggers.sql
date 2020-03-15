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

	declare @templateIDs identities
		insert into @templateIDs
		select distinct
			tree.templateID
		from inserted as i
			cross apply [orm_meta].[templateTree](i.templateID) as tree

	-- Referential integrity checks (needed instead of foreign keys due to constraint checks coming before triggers)
	if (exists(	select i.templateID
				from [orm_meta].[templates] as t
					right join inserted as i
						on t.templateID = i.templateID
				where t.templateID is null)) 
		begin
			rollback transaction
			raiserror('Can not insert property due to invalid templateID.', 16, 5)
			return
		end

	if (exists(	select i.datatypeID
				from [orm_meta].[templates] as t
					right join inserted as i
						on t.templateID = i.datatypeID
				where t.templateID is null)) 
		begin
			rollback transaction
			raiserror('Can not insert property due to invalid datatype templateID.', 16, 6)
			return
		end

	-- Check that no property inserted already exists.
	if (exists(	select i.propertyID
				from inserted as i
					inner join [orm_meta].[properties] as p
						on	i.templateID = p.templateID
						and i.name = p.name))
		begin
			rollback transaction	
			raiserror('Can not insert duplicate property.', 16, 1)
			return
		end

	-- Verify the names are safe
	if (exists(	select i.propertyID
				from inserted as i
				where i.name <> [orm_meta].[sanitize_string](i.name) ))
		begin
			rollback transaction	
			raiserror('Property name is not purely alphanumeric.', 16, 10)
			return
		end

	-- To further simplify things, this procedure will use a table variable so we can more easily reference
	--	and massage the masked property data.
	declare @masking table (scoped_templateID int,
							masking_propertyID int, masking_templateID int, masking_name varchar(250), masking_datatypeID int, masking_isExtended int, masking_signature nvarchar(max),
							current_propertyID int, current_templateID int, current_name varchar(250), current_datatypeID int, current_isExtended int, current_signature nvarchar(max))

	-- Insert the rows
	insert into [orm_meta].[properties] (templateID, name, datatypeID, isExtended, signature)
	select templateID, name, datatypeID, isExtended, signature
	from inserted as i

	-- Now that we have new properties, we need to make sure that these are inherited properly.
	-- First, we resolve how the affected template's properties are masked.
	
	-- Get the current masked properties
	insert into @masking (	scoped_templateID,
							masking_propertyID, masking_templateID, masking_name, masking_datatypeID, masking_isExtended, masking_signature,
							current_propertyID, current_templateID, current_name, current_datatypeID, current_isExtended, current_signature)
	select	
			p.scoped_templateID
		,	p.masked_propertyID
		,	p.masked_templateID
		,	p.masked_name
		,	p.masked_datatypeID
		,	p.masked_isExtended
		,	p.masked_signature

		,	p.current_propertyID
		,	p.current_templateID
		,	p.current_name
		,	p.current_datatypeID
		,	p.current_isExtended
		,	p.current_signature	
	from [orm_meta].[resolve_properties](@templateIDs) as p

	-- Next, we need to perform a sanity check. 
	-- If a child is inheriting a property datatype change, then fail the transaction.
	-- I want to do this because it should never happen in a sane situation,
	--  and it would be so destructive and easy that it would be better to just fail
	--  than risk the extremely likely case that it was an accident.
	if (exists(	select m.current_propertyID
				from @masking as m
				where m.current_datatypeID <> m.masking_datatypeID 
					and m.current_datatypeID is not null ))
		raiserror('Adding a new property that conflicts with the datatype of an existing subtemplate''s property is not allowed. Sorry.', 16, 1)

	-- Merge in the missing properties, inserting any properties that don't already exist
	--	... but only the ones that *need* to
	merge into [orm_meta].[properties] as d
	using (	select	m.current_propertyID as propertyID
				,	m.scoped_templateID as templateID
				,	m.masking_name as name
				,	m.masking_datatypeID as datatypeID
				,	m.masking_isExtended as isExtended
				,	m.masking_signature as [signature]
			from @masking as m
			where isnull(m.masking_isExtended, 0) = 0) as s 
		on d.propertyID = s.propertyID
	when not matched then
		insert (templateID, name, datatypeID, isExtended, signature)
		values (s.templateID, s.name, s.datatypeID, s.isExtended, s.signature)
	;

	-- Finally, loop over all the templateIDs that were affected by the insert/delete
	declare @templateID int

	-- from http://stackoverflow.com/a/18514133
	declare templateIDcursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct id
		from @templateIDs as t
	
	open templateIDcursor

	fetch next from templateIDcursor into @templateID
	
	while @@FETCH_STATUS = 0
	begin
		exec [orm_meta].[generate_template_view_wide] @templateID

		fetch next from templateIDcursor into @templateID
	end
	close templateIDcursor 
	deallocate templateIDcursor

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
	
	declare @inserted table (propertyID int, templateID int, name varchar(250), datatypeID int, isExtended int, signature nvarchar(max), primary key (propertyID))
	declare @deleted table (propertyID int, templateID int, name varchar(250), datatypeID int, isExtended int, signature nvarchar(max), primary key (propertyID))

		insert @inserted (propertyID, templateID, name, datatypeID, isExtended, signature)
		select propertyID, templateID, name, datatypeID, isExtended, signature
		from inserted

		insert @deleted (propertyID, templateID, name, datatypeID, isExtended, signature)
		select propertyID, templateID, name, datatypeID, isExtended, signature
		from deleted

	-- Referential integrity checks (needed instead of foreign keys due to constraint checks coming before triggers)
	if (exists(	select i.templateID
				from [orm_meta].[templates] as t
					right join inserted as i
						on t.templateID = i.templateID
				where t.templateID is null)) 
		begin
			rollback transaction	
			raiserror('Can not insert property due to invalid templateID.', 16, 5)
			return
		end	
		
	if (exists(	select i.datatypeID
				from [orm_meta].[templates] as t
					right join inserted as i
						on t.templateID = i.datatypeID
				where t.templateID is null)) 
		begin
			rollback transaction	
			raiserror('Can not insert property due to invalid data templateID.', 16, 6)	
			return
		end	
		
	-- Check that no property inserted already exists.
	-- (and make sure we're not merely double counting one that is merely changing )
	if (exists(	select i.propertyID
				from inserted as i
					inner join [orm_meta].[properties] as p
						on	i.templateID = p.templateID
						and i.name = p.name
				where i.propertyID not in (	select d.propertyID
											from deleted as d 
											where d.templateID = i.templateID
												and d.name = i.name )	))
		begin
			rollback transaction		
			raiserror('Can not insert duplicate property.', 16, 1)
			return
		end	

	-- Verify the names are safe
	if (exists(	select i.propertyID
				from inserted as i
				where i.name <> [orm_meta].[sanitize_string](i.name) ))
		begin
			rollback transaction		
			raiserror('Property name is not purely alphanumeric.', 16, 10)
			return
		end	

	-- To make things simpler, the query that generates the report on what properties are masked is
	--	abstracted out to a table valued function. These have the restriction that we can only pass in 
	--	parameters of a known template. So we need to generate a list of the affected templates in a special table template.
	declare @templateIDs identities, @scopedIDs identities, @deletedProperties identities
		insert into @templateIDs
		select distinct
			t.templateID
		from (	select templateID from @inserted as i
				union
				select templateID from @deleted as d) as t

	-- To further simplify things, this procedure will use a table variable so we can more easily reference
	--	and massage the masked property data.
	declare @masking table (scoped_templateID int,
							masking_propertyID int, masking_templateID int, masking_name varchar(250), masking_datatypeID int, masking_isExtended int, masking_signature nvarchar(max),
							current_propertyID int, current_templateID int, current_name varchar(250), current_datatypeID int, current_isExtended int, current_signature nvarchar(max))

	-- Get the current masked properties
	insert into @masking (	scoped_templateID,
							masking_propertyID, masking_templateID, masking_name, masking_datatypeID, masking_isExtended, masking_signature,
							current_propertyID, current_templateID, current_name, current_datatypeID, current_isExtended, current_signature)
	select	
			p.scoped_templateID
		,	p.masked_propertyID
		,	p.masked_templateID
		,	p.masked_name
		,	p.masked_datatypeID
		,	p.masked_isExtended
		,	p.masked_signature

		,	p.current_propertyID
		,	p.current_templateID
		,	p.current_name
		,	p.current_datatypeID
		,	p.current_isExtended
		,	p.current_signature	
	from [orm_meta].[resolve_properties](@templateIDs) as p

	-- Grab the templates that are going to potentially be affected by the changes.
	-- We'll use this later to rebuild the wide views.
	insert into @scopedIDs (id)
	select distinct scoped_templateID
	from @masking as m

	-- Purge any values where the datatype is changing.
	-- Be sure to get rid of any sub-templates that are being covered by this property.
	-- That is, from our properties table, find what current properties
	--	are covered by a mask that is changing templates.
	-- Cascading deletes will take 'care' of the values currently associated with them.
	delete p
	output deleted.propertyID into @deletedProperties -- deleted is scoped to THIS statement!
	from [orm_meta].[properties] as p
		inner join @masking as m
			on p.propertyID = m.current_propertyID
		inner join @inserted as i
			on i.propertyID = m.masking_propertyID
		inner join @deleted as d
			on i.propertyID = d.propertyID
	where i.datatypeID <> d.datatypeID

	-- Cascade delete the removed properties
	exec [orm_meta].[cascadeDelete_property] @deletedProperties
	-- Reset for next deletion
	delete from @deletedProperties

	-- Before we merge into @masking the @inserted row updates,
	--	we need to make sure that inserted won't merely add
	--	pointless new masks (since the merge happens on *masked*, not *current*.)
	-- If we find that we're about to merge in something that's already covered,
	--	remove it from @inserted.
	merge into @inserted as d
	using (	select	current_propertyID
				,	masking_propertyID
			from @masking as m) as s 
		on	d.propertyID = s.current_propertyID
		and	s.masking_propertyID <> s.current_propertyID
	when matched then
		delete
	;

	-- Update the masks to what the inserted table tells us the changes are.
	-- Note that the @masking variable currently holds the same data as deleted
	--	(since it referenced the same table from the same point in time).
	merge into @masking as d
	using (	select	i.propertyID
				,	i.templateID
				,	i.name
				,	i.datatypeID
				,	i.isExtended
				,	i.signature
			from @inserted as i ) as s
		on d.masking_propertyID = s.propertyID
	when matched then
		update
		set		d.masking_name = s.name
			,	d.masking_isExtended = (
					case
						-- when setting to base and currently not a base property, make base
						when s.isExtended = 0 and d.current_isExtended <> 0
						then	0
					
						-- when setting not base and mask is base, override to base
						when s.isExtended <> 0 and d.masking_isExtended = 0
						then	0
					
						-- otherwise just accept the value
						else	isNull(s.isExtended, 0)
					end)
			,	d.masking_signature = s.signature
	when not matched then
		insert	(	scoped_templateID	
				,	masking_propertyID
				,	masking_templateID
				,	masking_name
				,	masking_datatypeID
				,	masking_isExtended
				,	masking_signature	)
		values	(	s.templateID		--	this is necessarily the same as s.templateID
				,	s.propertyID	--	since we got the inScopeIDs from here!
				,	s.templateID
				,	s.name
				,	s.datatypeID
				,	s.isExtended
				,	s.signature	)
	;

	-- If a property is being overwritten (since we follow violent pigeonholing), 
	--	we need to purge the now-covered property.
	-- We do this by checking if the mask now effectively has a duplicate entry.
	-- The signature of this is there will be a duplicate entry for a scoped_templateID
	--	where one entry has a masking_templateID the same as current_templateID.
	-- If we have one like that, we take that entry and delete it from the properties table.
	declare @deadPigeons identities
	; with contestedPigeonhole as
	(
		select m.scoped_templateID, m.masking_name
		from @masking as m
		group by m.scoped_templateID, m.masking_name
		having count(m.scoped_templateID) > 1
	)
	,	propertyGettingPushedOut as
	(
		select m.current_propertyID as deadPigeon
		from contestedPigeonhole as cp
			inner join @masking as m
				on	m.scoped_templateID = cp.scoped_templateID
				and	m.masking_name = cp.masking_name
		where m.current_templateID = m.masking_templateID
	)
	insert into @deadPigeons (id)
	select pgpo.deadPigeon
	from propertyGettingPushedOut as pgpo
	
	-- removed these displaced properties from both the main table...
	delete p
	output deleted.propertyID into @deletedProperties -- deleted is scoped to THIS statement!		
	from [orm_meta].[properties] as p
		inner join @deadPigeons as dp
			on p.propertyID = dp.id
	-- ... and the mask (to make sure they're not just re-inserted!)
	delete m
	from @masking as m
		inner join @deadPigeons as dp
			on m.masking_propertyID = dp.id

	-- Cascade delete the removed properties
	exec [orm_meta].[cascadeDelete_property] @deletedProperties
	-- Reset for next deletion
	delete from @deletedProperties			

	-- Update the properties table to this corrected mask.
	-- This is the first set of two corrections.
	-- Once this is applied, we'll double check the masking again to see
	--	if any new properties were uncovered. If so, add these in.
	merge into [orm_meta].[properties] as d
	using (	select	scoped_templateID
				,	masking_propertyID
				,	masking_templateID
				,	masking_name
				,	masking_datatypeID
				,	masking_isExtended
				,	masking_signature
				,	current_propertyID
				,	current_templateID
				,	current_name
				,	current_datatypeID
				,	current_isExtended
				,	current_signature
			from @masking as m	) as s 
		on d.propertyID = s.current_propertyID
	when matched then
		update
		set		d.name = s.masking_name
			--,	d.datatypeID = s.datatypeID -- we can ignore this since we've already deleted the changed ones
			
			-- Q: Do we change our isExtended propery?
			-- A: ONLY if the masking isExtended property is 0 or NULL
			,	d.isExtended = (
					case
						when s.masking_isExtended = 0 
						then	0
						else	isnull(s.current_isExtended, 0)
					end)
			,	d.signature = s.current_signature
	when not matched then
		insert	(	templateID
				,	name
				,	datatypeID
				,	isExtended
				,	signature	)
		values	(	scoped_templateID
				,	masking_name
				,	masking_datatypeID
				,	masking_isExtended
				,	masking_signature	)
	;

	-- Reset the mask to prepare for final checks
	delete from @masking

	-- Get the current masked properties so we can double check the base properties are masked correctly.
	insert into @masking (	scoped_templateID,
							masking_propertyID, masking_templateID, masking_name, masking_datatypeID, masking_isExtended, masking_signature,
							current_propertyID, current_templateID, current_name, current_datatypeID, current_isExtended, current_signature)
	select	
			p.scoped_templateID
		,	p.masked_propertyID
		,	p.masked_templateID
		,	p.masked_name
		,	p.masked_datatypeID
		,	p.masked_isExtended
		,	p.masked_signature

		,	p.current_propertyID
		,	p.current_templateID
		,	p.current_name
		,	p.current_datatypeID
		,	p.current_isExtended
		,	p.current_signature	
	from [orm_meta].[resolve_properties](@templateIDs) as p

	-- The final pass here will do two things:
	--  1) add new properties that were uncovered by the previous merge
	--	2) re-solve and verify if properties are optional (which may have changed)
	-- This merge is simpler since the only properties that can be wrong are either missing
	--	or are marked (non)optional.
	merge into [orm_meta].[properties] as d
	using (	select	scoped_templateID
				,	masking_propertyID
				,	masking_templateID
				,	masking_name
				,	masking_datatypeID
				,	masking_isExtended
				,	masking_signature
				,	current_propertyID
				,	current_templateID
				,	current_name
				,	current_datatypeID
				,	current_isExtended
				,	current_signature
			from @masking as m	) as s 
		on d.propertyID = s.current_propertyID
	when matched then
		update	-- override properties as non-optional if their parent says so
		set		d.isExtended = (
					case 
						when s.masking_isExtended = 0 
						then	0
						else	isnull(s.current_isExtended, 0)
					end	)
	when not matched then
		insert	(	templateID
				,	name
				,	datatypeID
				,	isExtended
				,	signature	)
		values	(	scoped_templateID
				,	masking_name
				,	masking_datatypeID
				,	masking_isExtended
				,	masking_signature	)
	;

	-- Finally, loop over all the templateIDs that were affected by the insert/delete
	declare @templateID int

	-- from http://stackoverflow.com/a/18514133
	declare templateIDcursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct id
		from @scopedIDs as t
	
	open templateIDcursor

	fetch next from templateIDcursor into @templateID
	
	while @@FETCH_STATUS = 0
	begin
		exec [orm_meta].[generate_template_view_wide] @templateID

		fetch next from templateIDcursor into @templateID
	end
	close templateIDcursor 
	deallocate templateIDcursor

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

	declare @templateIDs identities, @deletedProperties identities
	insert into @templateIDs
	select distinct
		tree.templateID
	from deleted as d
		cross apply [orm_meta].[templateTree](d.templateID) as tree

	-- Only allow deletion for properties that are uncovered!
	--	and be sure to get children masked by it as well!
	; with involvedProperties as
	(
		select m.masked_propertyID, m.masked_templateID, m.current_propertyID, m.current_templateID
		from [orm_meta].[resolve_properties](@templateIDs) as m
	)
	,	uncovered as
	(
		select	p.current_propertyID as propertyID
		from deleted as d
			inner join involvedProperties as p
				on d.propertyID = p.masked_propertyID	-- Delete the rows and anything they mask.
				or d.propertyID = p.current_propertyID	-- If it's behaving like a mask, the masked property ID is already
	)													-- the top-most one.
	delete p
	output deleted.propertyID into @deletedProperties -- deleted is scoped to THIS statement!		
	from [orm_meta].[properties] as p 
		inner join uncovered as u
			on p.propertyID = u.propertyID

	-- Cascade delete the removed properties
	exec [orm_meta].[cascadeDelete_property] @deletedProperties

	-- Finally, loop over all the templateIDs that were affected by the insert/delete
	declare @templateID int

	-- from http://stackoverflow.com/a/18514133
	declare templateIDcursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct id
		from @templateIDs as t
	
	open templateIDcursor

	fetch next from templateIDcursor into @templateID
	
	while @@FETCH_STATUS = 0
	begin
		exec [orm_meta].[generate_template_view_wide] @templateID

		fetch next from templateIDcursor into @templateID
	end
	close templateIDcursor 
	deallocate templateIDcursor

end
go
print '
Generating template inheritance triggers...'


if object_id('[orm_meta].[inheritance_insert]', 'TR')  is not null
	drop trigger [orm_meta].[inheritance_insert]
go

create trigger [orm_meta].[inheritance_insert]
	on [orm_meta].[inheritance]
	instead of insert
as 
begin
	set nocount on;

	-- First, bail on any grandfather paradoxes.
	-- Make sure not to exclude mere ordinal changes
	if (exists( select *
				from inserted as i
					cross apply [orm_meta].[template_tree](i.parent_template_guid) as ptree
					cross apply [orm_meta].[template_tree](i.child_template_guid) as ctree
				where	ptree.template_guid = i.parent_template_guid and ptree.echelon <> 0
					and ctree.template_guid = i.child_template_guid and ctree.echelon <> 0
					and not exists (select *
									from deleted as d
										inner join inserted as i
											on d.parent_template_guid = i.parent_template_guid
											and d.child_template_guid = i.child_template_guid)))
		begin
			rollback transaction	
			raiserror('Insert will cause a recursive loop in inheritance (no grandfather paradoxes, please).', 16, 1)
			return
		end

	-- Ordinals are not allowed to get to 32000, since that's where self-reference goes
	if (exists( select *
				from inserted as i
				where i.ordinal >= 32000	))
		begin
			rollback transaction
			raiserror('Ordinal can not be greater than 32000 (internally the template represents itself as that for masking purposes).', 16, 1)
			return
		end

	-- If that passes, perform the insert...
	insert into [orm_meta].[inheritance] (parent_template_guid, child_template_guid, ordinal)
	select i.parent_template_guid, i.child_template_guid, i.ordinal
	from inserted as i
		
	-- ... and force an update on the property table (let it resolve the complexities)
	update p
	set p.template_guid = p.template_guid
	from [orm_meta].[properties] as p
		inner join inserted as i
			on p.template_guid = i.child_template_guid
			or p.template_guid = i.parent_template_guid

end
go


if object_id('[orm_meta].[inheritance_update]', 'TR')  is not null
	drop trigger [orm_meta].[inheritance_update]
go

create trigger [orm_meta].[inheritance_update]
	on [orm_meta].[inheritance]
	instead of update
as 
begin
	set nocount on;
	
	-- The update problem is (naturally) a composite of the insert and delete problems.
	-- For inheritance, we need to perform the same validity checks as the insert,
	--	as well as the uncovering check as the delete.
	-- The final step is to ensure that the properties are corrected, which will
	--	simply be a repeat of the end of the insert trigger.
	
	-- First, bail on any grandfather paradoxes (don't allow someone to insert into their own tree)
	-- Make sure not to exclude mere ordinal changes
	if (exists( select *
				from inserted as i
					cross apply [orm_meta].[template_tree](i.parent_template_guid) as ptree
					cross apply [orm_meta].[template_tree](i.child_template_guid) as ctree
				where	ptree.template_guid = i.parent_template_guid and ptree.echelon <> 0
					and ctree.template_guid = i.child_template_guid and ctree.echelon <> 0
					and not exists (select *
									from deleted as d
										inner join inserted as i
											on d.parent_template_guid = i.parent_template_guid
											and d.child_template_guid = i.child_template_guid)))
		begin
			rollback transaction	
			raiserror('Insert will cause a recursive loop in inheritance (no grandfather paradoxes, please).', 16, 1)
			return
		end

	-- Ordinals are not allowed to get to 32000, since that's where self-reference goes
	if (exists( select *
				from inserted as i
				where i.ordinal >= 32000	))
		begin
			rollback transaction
			raiserror('Ordinal can not be greater than 32000 (internally the template represents itself as that for masking purposes).', 16, 1)
			return
		end

	-- Next, check if we've uncovered any properties.
	-- If so, delete these like in the delete trigger. 
	-- (The following is taken directly from the delete trigger, but with the detail of also inserting inserted.)

	-- In the case of a deletion, we need to determine what properties are not going to be covered. 
	-- We can detect any relevant covered property as one who has a mask that isn't their own
	--	and whose masking template_guid becomes the child of the parent
	-- We'll do this in two steps.

	declare @covering_before table (parent_template_guid uniqueidentifier, child_template_guid uniqueidentifier, child_property_guid uniqueidentifier)
	declare @covering_after table  (parent_template_guid uniqueidentifier, child_template_guid uniqueidentifier, child_property_guid uniqueidentifier)

	declare	@template_guids identities
		insert into @template_guids (guid)
		select distinct d.parent_template_guid
		from deleted as d

	-- First, get the properties that are covered before the change
	insert into @covering_before (parent_template_guid, child_template_guid, child_property_guid)
	select m.masked_template_guid, m.current_template_guid, m.current_property_guid
	from [orm_meta].[resolve_properties](@template_guids) as m
	where m.masked_template_guid <> m.current_template_guid
	
	-- Make the changes:
	-- First delete...
	delete i
	from [orm_meta].[inheritance] as i
		inner join deleted as d
			on d.parent_template_guid = i.parent_template_guid
			and d.child_template_guid = i.child_template_guid
			and d.ordinal = i.ordinal
	-- Second insert... (since this is an update, after all: we may add the 
	--	relationship right back in but with another ordinal.)
	insert into [orm_meta].[inheritance] (parent_template_guid, child_template_guid, ordinal)
	select i.parent_template_guid, i.child_template_guid, i.ordinal
	from inserted as i
	
	-- Reset the template_guids so we can check again from the children's point of view
	delete @template_guids

	insert into @template_guids (guid)
	select distinct d.child_template_guid
	from deleted as d

	-- Now re-solve the property tree given the change
	insert into @covering_after (parent_template_guid, child_template_guid, child_property_guid)
	select m.masked_template_guid, m.current_template_guid, m.current_property_guid
	from [orm_meta].[resolve_properties](@template_guids) as m

	-- We can now check if any properties are uncovered.
	-- Any property whose masking ID is was the parent, but is now the child
	--	which shows the change percolating.
	-- These properties with this masking ID need to be removed.

	delete p
	from [orm_meta].[properties] as p
		inner join @covering_after as ca
			on p.property_guid = ca.child_property_guid
		inner join @covering_before as cb
			on ca.child_property_guid = cb.child_property_guid
		inner join deleted as d
			on d.parent_template_guid = cb.parent_template_guid
			and d.child_template_guid = ca.parent_template_guid


	-- Force the properties table to heal itself, if needed.
	-- (Healing means that a template that should have a supertemplate's property (but doesn't)
	--	will be updated to have it.)
	-- This can be an issue if we cleared uncovered properties, but never added newly covered properties.
	--	By tripping a no-op update on the property table, we can let it re-resolve the details and apply corrections.
	update p
	set p.template_guid = p.template_guid
	from [orm_meta].[properties] as p
		inner join inserted as i
			on p.template_guid = i.child_template_guid
			or p.template_guid = i.parent_template_guid

	-- Log the changes to history
	insert into [orm_hist].[inheritance] 
		  (parent_template_guid, child_template_guid, ordinal, transaction_id)
	select parent_template_guid, child_template_guid, ordinal, CURRENT_TRANSACTION_ID()
	from deleted

end
go


if object_id('[orm_meta].[inheritance_delete]', 'TR')  is not null
	drop trigger [orm_meta].[inheritance_delete]
go

create trigger [orm_meta].[inheritance_delete]
	on [orm_meta].[inheritance]
	instead of delete
as 
begin
	set nocount on;

	-- In the case of a deletion, we need to determine what properties are not going to be covered. 
	-- We can detect any relevant covered property as one who has a mask that isn't their own
	--	and whose masking template_guid becomes the child of the parent
	-- We'll do this in two steps.

	declare @covering_before table (parent_template_guid uniqueidentifier, child_template_guid uniqueidentifier, child_property_guid uniqueidentifier)
	declare @covering_after table  (parent_template_guid uniqueidentifier, child_template_guid uniqueidentifier, child_property_guid uniqueidentifier)

	declare	@template_guids identities
		insert into @template_guids (guid)
		select distinct d.parent_template_guid
		from deleted as d

	-- First, get the properties that are covered before the change
	insert into @covering_before (parent_template_guid, child_template_guid, child_property_guid)
	select m.masked_template_guid, m.current_template_guid, m.current_property_guid
	from [orm_meta].[resolve_properties](@template_guids) as m
	where m.masked_template_guid <> m.current_template_guid
	
	-- Make the change...
	delete i
	from [orm_meta].[inheritance] as i
		inner join deleted as d
			on d.parent_template_guid = i.parent_template_guid
			and d.child_template_guid = i.child_template_guid
			and d.ordinal = i.ordinal
	
	-- Reset the template_guids so we can check from the children's point of view
	delete @template_guids

	insert into @template_guids (guid)
	select distinct d.child_template_guid
	from deleted as d

	-- Now re-solve the property tree given the change
	insert into @covering_after (parent_template_guid, child_template_guid, child_property_guid)
	select m.masked_template_guid, m.current_template_guid, m.current_property_guid
	from [orm_meta].[resolve_properties](@template_guids) as m

	-- We can now check if any properties are uncovered.
	-- Any property whose masking ID is was the parent, but is now the child
	--	which shows the change percolating.
	-- These properties with this masking ID need to be removed.

	delete p
	from [orm_meta].[properties] as p
		inner join @covering_after as ca
			on p.property_guid = ca.child_property_guid
		inner join @covering_before as cb
			on ca.child_property_guid = cb.child_property_guid
		inner join deleted as d
			on d.parent_template_guid = cb.parent_template_guid
			and d.child_template_guid = ca.parent_template_guid

	-- Log the changes to history
	insert into [orm_hist].[inheritance] 
		  (parent_template_guid, child_template_guid, ordinal, transaction_id)
	select parent_template_guid, child_template_guid, ordinal, CURRENT_TRANSACTION_ID()
	from deleted
end
go

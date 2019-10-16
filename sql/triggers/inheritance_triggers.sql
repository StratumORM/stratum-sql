print '
Generating template inheritance triggers...'


if object_id('[dbo].[trigger_orm_meta_inheritance_insert]', 'TR')  is not null
	drop trigger dbo.trigger_orm_meta_inheritance_insert
go

create trigger trigger_orm_meta_inheritance_insert
	on dbo.orm_meta_inheritance
	instead of insert
as 
begin

	-- First, bail on any grandfather paradoxes.
	-- Make sure not to exclude mere ordinal changes
	if (exists( select *
				from inserted as i
					cross apply dbo.orm_meta_templateTree(i.parentTemplateID) as ptree
					cross apply dbo.orm_meta_templateTree(i.childTemplateID) as ctree
				where	ptree.templateID = i.parentTemplateID and ptree.echelon <> 0
					and ctree.templateID = i.childTemplateID and ctree.echelon <> 0
					and not exists (select *
									from deleted as d
										inner join inserted as i
											on d.parentTemplateID = i.parentTemplateID
											and d.childTemplateID = i.childTemplateID)))
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
	insert into orm_meta_inheritance (parentTemplateID, childTemplateID, ordinal)
	select i.parentTemplateID, i.childTemplateID, i.ordinal
	from inserted as i
		
	-- ... and force an update on the property table (let it resolve the complexities)
	update p
	set p.templateID = p.templateID
	from orm_meta_properties as p
		inner join inserted as i
			on p.templateID = i.childTemplateID
			or p.templateID = i.parentTemplateID

end
go


if object_id('[dbo].[trigger_orm_meta_inheritance_update]', 'TR')  is not null
	drop trigger dbo.trigger_orm_meta_inheritance_update
go

create trigger trigger_orm_meta_inheritance_update
	on dbo.orm_meta_inheritance
	instead of update
as 
begin
	
	-- The update problem is (naturally) a composite of the insert and delete problems.
	-- For inheritance, we need to perform the same validity checks as the insert,
	--	as well as the uncovering check as the delete.
	-- The final step is to ensure that the properties are corrected, which will
	--	simply be a repeat of the end of the insert trigger.
	
	-- First, bail on any grandfather paradoxes (don't allow someone to insert into their own tree)
	-- Make sure not to exclude mere ordinal changes
	if (exists( select *
				from inserted as i
					cross apply dbo.orm_meta_templateTree(i.parentTemplateID) as ptree
					cross apply dbo.orm_meta_templateTree(i.childTemplateID) as ctree
				where	ptree.templateID = i.parentTemplateID and ptree.echelon <> 0
					and ctree.templateID = i.childTemplateID and ctree.echelon <> 0
					and not exists (select *
									from deleted as d
										inner join inserted as i
											on d.parentTemplateID = i.parentTemplateID
											and d.childTemplateID = i.childTemplateID)))
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
	--	and whose masking templateID becomes the child of the parent
	-- We'll do this in two steps.

	declare @covering_before table (parent_templateID int, child_templateID int, child_propertyID int)
	declare @covering_after table  (parent_templateID int, child_templateID int, child_propertyID int)

	declare	@templateIDs identities
		insert into @templateIDs (id)
		select distinct d.parentTemplateID
		from deleted as d

	-- First, get the properties that are covered before the change
	insert into @covering_before (parent_templateID, child_templateID, child_propertyID)
	select m.masked_templateID, m.current_templateID, m.current_propertyID
	from dbo.orm_meta_resolve_properties(@templateIDs) as m
	where m.masked_templateID <> m.current_templateID
	
	-- Make the changes:
	-- First delete...
	delete i
	from orm_meta_inheritance as i
		inner join deleted as d
			on d.parentTemplateID = i.parentTemplateID
			and d.childTemplateID = i.childTemplateID
			and d.ordinal = i.ordinal
	-- Second insert... (since this is an update, after all: we may add the 
	--	relationship right back in but with another ordinal.)
	insert into orm_meta_inheritance (parentTemplateID, childTemplateID, ordinal)
	select i.parentTemplateID, i.childTemplateID, i.ordinal
	from inserted as i
	
	-- Reset the templateIDs so we can check again from the children's point of view
	delete @templateIDs

	insert into @templateIDs (id)
	select distinct d.childTemplateID
	from deleted as d

	-- Now re-solve the property tree given the change
	insert into @covering_after (parent_templateID, child_templateID, child_propertyID)
	select m.masked_templateID, m.current_templateID, m.current_propertyID
	from dbo.orm_meta_resolve_properties(@templateIDs) as m

	-- We can now check if any properties are uncovered.
	-- Any property whose masking ID is was the parent, but is now the child
	--	which shows the change percolating.
	-- These properties with this masking ID need to be removed.

	delete p
	from orm_meta_properties as p
		inner join @covering_after as ca
			on p.propertyID = ca.child_propertyID
		inner join @covering_before as cb
			on ca.child_propertyID = cb.child_propertyID
		inner join deleted as d
			on d.parentTemplateID = cb.parent_templateID
			and d.childTemplateID = ca.parent_templateID


	-- Force the properties table to heal itself, if needed.
	-- (Healing means that a template that should have a supertemplate's property (but doesn't)
	--	will be updated to have it.)
	-- This can be an issue if we cleared uncovered properties, but never added newly covered properties.
	--	By tripping a no-op update on the property table, we can let it re-resolve the details and apply corrections.
	update p
	set p.templateID = p.templateID
	from orm_meta_properties as p
		inner join inserted as i
			on p.templateID = i.childTemplateID
			or p.templateID = i.parentTemplateID

end
go


if object_id('[dbo].[trigger_orm_meta_inheritance_delete]', 'TR')  is not null
	drop trigger dbo.trigger_orm_meta_inheritance_delete
go

create trigger trigger_orm_meta_inheritance_delete
	on dbo.orm_meta_inheritance
	instead of delete
as 
begin

	-- In the case of a deletion, we need to determine what properties are not going to be covered. 
	-- We can detect any relevant covered property as one who has a mask that isn't their own
	--	and whose masking templateID becomes the child of the parent
	-- We'll do this in two steps.

	declare @covering_before table (parent_templateID int, child_templateID int, child_propertyID int)
	declare @covering_after table  (parent_templateID int, child_templateID int, child_propertyID int)

	declare	@templateIDs identities
		insert into @templateIDs (id)
		select distinct d.parentTemplateID
		from deleted as d

	-- First, get the properties that are covered before the change
	insert into @covering_before (parent_templateID, child_templateID, child_propertyID)
	select m.masked_templateID, m.current_templateID, m.current_propertyID
	from dbo.orm_meta_resolve_properties(@templateIDs) as m
	where m.masked_templateID <> m.current_templateID
	
	-- Make the change...
	delete i
	from orm_meta_inheritance as i
		inner join deleted as d
			on d.parentTemplateID = i.parentTemplateID
			and d.childTemplateID = i.childTemplateID
			and d.ordinal = i.ordinal
	
	-- Reset the templateIDs so we can check from the children's point of view
	delete @templateIDs

	insert into @templateIDs (id)
	select distinct d.childTemplateID
	from deleted as d

	-- Now re-solve the property tree given the change
	insert into @covering_after (parent_templateID, child_templateID, child_propertyID)
	select m.masked_templateID, m.current_templateID, m.current_propertyID
	from dbo.orm_meta_resolve_properties(@templateIDs) as m

	-- We can now check if any properties are uncovered.
	-- Any property whose masking ID is was the parent, but is now the child
	--	which shows the change percolating.
	-- These properties with this masking ID need to be removed.

	delete p
	from orm_meta_properties as p
		inner join @covering_after as ca
			on p.propertyID = ca.child_propertyID
		inner join @covering_before as cb
			on ca.child_propertyID = cb.child_propertyID
		inner join deleted as d
			on d.parentTemplateID = cb.parent_templateID
			and d.childTemplateID = ca.parent_templateID

end
go

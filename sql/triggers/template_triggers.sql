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

	-- Make sure the templateName is legal (since this will go into dynamic sql)
	select i.name
	from inserted as i
	where i.name <> [orm].meta_sanitize_string(i.name)
	if @@ROWCOUNT <> 0 
		begin
			rollback transaction		
			raiserror('Template name not purely alphanumeric.', 16, 10)
			return
		end	

	-- Make sure it doesn't already exist
	select t.templateID 
	from [orm_meta].[templates] as t
		inner join inserted as i
			on t.name = i.name

	if @@ROWCOUNT <> 0 
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
	declare @templateID int

	declare templateIDCursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct t.templateID
		from inserted as i
			inner join [orm_meta].[templates] as t
				on t.name = i.name
	
	open templateIDCursor

	fetch next from templateIDCursor into @templateID
	
	while @@FETCH_STATUS = 0
	begin
		exec [orm_meta].[generate_template_view_wide] @templateID

		fetch next from templateIDCursor into @templateID
	end
	close templateIDCursor 
	deallocate templateIDCursor

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

	-- Make sure the templateName is legal (since this will go into dynamic sql)
	select i.name
	from inserted as i
	where i.name <> [orm].meta_sanitize_string(i.name)
	if @@ROWCOUNT <> 0 
		begin
			rollback transaction		
			raiserror('Template name not purely alphanumeric.', 16, 10)
			return
		end	

	-- Perform the update
	update t
	set 	t.name = i.name
		,	t.signature = i.signature
	from [orm_meta].[templates] as t
		inner join inserted as i 
			on t.templateID = i.templateID

	-- Loop over all the template names that were affected by the update
	declare @templateName varchar(250), @templateID int, @dropQuery nvarchar(max)

	declare templateCursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct d.name, i.templateID
		from deleted as d
			inner join inserted as i
				on d.templateID = i.templateID
		where d.name <> i.name
	
	open templateCursor

	fetch next from templateCursor into @templateName, @templateID
	
	while @@FETCH_STATUS = 0
	begin

		set @dropQuery = 'drop view ' + @templateName
		exec sp_executesql @dropQuery

		exec [orm_meta].[generate_template_view_wide] @templateID

		fetch next from templateCursor into @templateName, @templateID
	end
	close templateCursor 
	deallocate templateCursor

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

	-- We need to make sure that the base templates are never deleted. So we'll mask the special
	--	deleted table like the properties trigger manipulates them
	declare @deleted table (templateID int, name varchar(250), signature nvarchar(max), primary key (templateID))
		insert @deleted (templateID, name, signature)
		select templateID, name, signature
		from deleted

		if (select min(templateID) from deleted) < 5 raiserror('Can not delete base templates. Other templates will be deleted, if any (otherwise error escalates rollback).',5,20)

		delete d
		from @deleted as d
		where templateID < 5

		-- Sound a warning if this is the only data that was deleted
		-- But we'll silently ignore these templates otherwise.
		if (not exists(	select * from @deleted as d)) 
			begin
				rollback transaction
				return
			end			

	-- Get the list of the affected templates
	declare @affectedTemplateIDs identities, @propIDs identities, @childTemplates identities
		insert into @affectedTemplateIDs (id)
		select distinct tree.templateID
		from @deleted as d
			cross apply [orm_meta].[templateTree](d.templateID) as tree

		insert into @childTemplates (id)
		select distinct i.childTemplateID
		from [orm_meta].[inheritance] as i
			inner join @deleted as d
				on i.parentTemplateID = d.templateID

	-- If this template is the sole source of a base property, then we'll need
	--  to purge that property from the children as well
	-- So first, find out what properties *may* be affected...
	insert into @propIDs (id)
	select m.current_propertyID
	from [orm_meta].[resolve_properties](@affectedTemplateIDs) as m
		inner join @deleted as d 
			on m.masked_templateID = d.templateID 
	where isnull(m.masked_isExtended,0) = 0

	-- first delete the properties ... (which will cascade deletes to the values)
	delete p
	from [orm_meta].[properties] as p 
		inner join @deleted as d 
			on p.templateID = d.templateID 

	-- then delete the instances ...
	delete o
	from [orm_meta].[instances] as o 
		inner join @deleted as d 
			on o.templateID = d.templateID

	-- and update the children to inherit from the template's parents, if any
	declare @myOrdinalInsert table (myID int, myOffset int)
		insert into @myOrdinalInsert (myID, myOffset)
		select d.templateID, count(i.ordinal)
		from @deleted as d 
			inner join [orm_meta].[inheritance] as i
				on d.templateID = i.childTemplateID
		group by d.templateID

	-- We'll need to bump the other inherited templates to make room for the insert	
	; with myChildren as
	(
		select d.templateID as myID, i.childTemplateID, i.ordinal as myOrdinal
		from [orm_meta].[inheritance] as i
			inner join @deleted as d
				on i.parentTemplateID = d.templateID
	)	
	update i 
	set i.ordinal = i.ordinal + o.myOffset --not off by one		
	from [orm_meta].[inheritance] as i 
		inner join myChildren as c 
			on i.childTemplateID = c.childTemplateID
		inner join @myOrdinalInsert as o 
			on c.myID = o.myID
	where i.ordinal >= c.myOrdinal 

	--
	-- The grandfather paradox is tripped here 
	--	if the template has dependents and parents.	
	--

	-- ... and with that room, we can now insert the new inherited links

	; with	myParents as
	(
		select 	d.templateID as myID
			,	i.parentTemplateID
			,	dense_rank() over (partition by d.templateID order by ordinal) as ordinal
		from [orm_meta].[inheritance] as i
			inner join @deleted as d
				on i.childTemplateID = d.templateID	
	)
	,	myChildren as
	(
		select 	d.templateID as myID
			,	i.childTemplateID
			,	ordinal
		from [orm_meta].[inheritance] as i
			inner join @deleted as d
				on i.parentTemplateID = d.templateID
	)
	,	newRelationship as
	(
		select 	p.parentTemplateID
			,	c.childTemplateID
			,	c.ordinal + o.myOffset as ordinal
		from myParents as p 
			inner join myChildren as c 
				on p.myID = c.myID
			inner join @myOrdinalInsert as o 
				on p.myID = o.myID
	)
	merge into [orm_meta].[inheritance] as d 
	using (	select 	r.parentTemplateID
				,	r.childTemplateID
				,	r.ordinal
			from newRelationship as r) as s 
		on d.parentTemplateID = s.parentTemplateID
		and d.childTemplateID = s.childTemplateID
	when matched then
		update 
		set d.ordinal = s.ordinal
	when not matched then
		insert (parentTemplateID, childTemplateID, ordinal)
		values (s.parentTemplateID, s.childTemplateID, s.ordinal)
	;

	-- Notice that we didn't have an off-by-one error above: we intentionally
	--	jump over the current relationship's ordinal so that when we delete
	-- 	this one, the old ones will be immediately exposed (and no ordinal collisions)
	delete i
	from [orm_meta].[inheritance] as i
		inner join @deleted as d 
			on 	childTemplateID = d.templateID 
			or 	parentTemplateID = d.templateID	

	-- then finally delete the template ...
	delete t 
	from [orm_meta].[templates] as t
		inner join @deleted as d 
			on t.templateID = d.templateID

	-- And now check if a new template has stepped up to cover some or all of those properties.
	-- We do that by checking if the masking template for those saved properties 
	-- 	inherited from the one getting deleted
	delete from @propIDs
	where id not in (	
		select m.current_propertyID
		from @propIDs as p
			inner join [orm_meta].[resolve_properties](@affectedTemplateIDs) as m
				on m.current_propertyID = p.id
			inner join @childTemplates as c 
				on m.masked_templateID = c.id 
		)

	-- Deletes will cascade once the properties trigger fires
	delete p
	from [orm_meta].[properties] as p
		inner join @propIDs as pids 
			on p.propertyID = pids.id

	-- Finally, loop over all the template names that were affected by the delete
	declare @templateName varchar(250), @dropQuery nvarchar(max)

		select distinct d.name
		from @deleted as d

	-- from http://stackoverflow.com/a/18514133
	declare templateNameCursor cursor
	  LOCAL STATIC READ_ONLY FORWARD_ONLY
	for
		select distinct d.name
		from @deleted as d
	
	open templateNameCursor

	fetch next from templateNameCursor into @templateName
	
	while @@FETCH_STATUS = 0
	begin

		set @dropQuery = 'drop view ' + @templateName
		exec sp_executesql @dropQuery

		fetch next from templateNameCursor into @templateName
	end
	close templateNameCursor 
	deallocate templateNameCursor

end
go

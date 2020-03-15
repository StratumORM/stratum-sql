print '
Generating meta view value triggers...'


IF OBJECT_ID('[orm_meta].[view_all_values_listing_delete]', 'tr') IS NOT NULL
	drop trigger [orm_meta].[view_all_values_listing_delete]
go

create trigger [orm_meta].[view_all_values_listing_delete]
	on [orm_meta].[all_values_listing]
	instead of delete
as 
begin
	
	declare @resolved_deleted table 
	(	templateID int not null
	,	instanceID int not null
	,	propertyID int
	,	datatypeID int 
	,	value nvarchar(max)
	,	unique nonclustered (datatypeID, instanceID, propertyID)
	) 

	insert into @resolved_deleted
	select 	omt.templateID
		,	omi.instanceID 
		,	omp.propertyID 
		,	omd.templateID as datatypeID
		,	d.Value
	from deleted as d
		inner join [orm_meta].[templates] as omt 
			on	d.Template = omt.name
		inner join [orm_meta].[instances] as omi 
			on	d.Instance = omi.name
			and omt.templateID = omi.templateID
		inner join [orm_meta].[properties] as omp 
			on	d.Property = omp.name
			and omt.templateID = omp.templateID
		inner join [orm_meta].[templates] as omd 
			on	d.Datatype = omd.name
			and omp.datatypeID = omd.templateID


	delete omv
	from [orm_meta].[values_string] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instanceID = omv.instanceID
			and rd.propertyID = omv.propertyID
	where rd.datatypeID = 1

	delete omv
	from [orm_meta].[values_integer] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instanceID = omv.instanceID
			and rd.propertyID = omv.propertyID
	where rd.datatypeID = 2

	delete omv
	from [orm_meta].[values_decimal] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instanceID = omv.instanceID
			and rd.propertyID = omv.propertyID
	where rd.datatypeID = 3

	delete omv
	from [orm_meta].[values_datetime] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instanceID = omv.instanceID
			and rd.propertyID = omv.propertyID
	where rd.datatypeID = 4

	delete omv
	from [orm_meta].[values_instance] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instanceID = omv.instanceID
			and rd.propertyID = omv.propertyID
	where rd.datatypeID > 4
	
end



IF OBJECT_ID('[orm_meta].[view_all_values_listing_update]', 'tr') IS NOT NULL
	drop trigger [orm_meta].[view_all_values_listing_update]
go


create trigger [orm_meta].[view_all_values_listing_update]
	on [orm_meta].[all_values_listing]
	instead of update
as 
begin

	declare @resolved_updated table 
	(	templateID int not null
	,	instanceID int not null
	,	propertyID int
	,	datatypeID int 
	,	value nvarchar(max)
	,	unique nonclustered (datatypeID, instanceID, propertyID)
	) 

	insert into @resolved_updated
	select 	omt.templateID
		,	omi.instanceID 
		,	omp.propertyID 
		,	omp.datatypeID
		,	i.Value
	from inserted as i
		inner join [orm_meta].[templates] as omt 
			on	i.Template = omt.name
		inner join [orm_meta].[instances] as omi 
			on	i.Instance = omi.name
			and omt.templateID = omi.templateID
		inner join [orm_meta].[properties] as omp 
			on	i.Property = omp.name
			and omt.templateID = omp.templateID


	merge into [orm_meta].[values_string] as omv
	using @resolved_updated as ru
		on 	ru.instanceID = omv.instanceID
		and ru.propertyID = omv.propertyID
		and ru.datatypeID = 1
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;

	merge into [orm_meta].[values_integer] as omv
	using @resolved_updated as ru
		on 	ru.instanceID = omv.instanceID
		and ru.propertyID = omv.propertyID
		and ru.datatypeID = 2
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;

	merge into [orm_meta].[values_decimal] as omv
	using @resolved_updated as ru
		on 	ru.instanceID = omv.instanceID
		and ru.propertyID = omv.propertyID
		and ru.datatypeID = 3
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;
	
	merge into [orm_meta].[values_datetime] as omv
	using @resolved_updated as ru
		on 	ru.instanceID = omv.instanceID
		and ru.propertyID = omv.propertyID
		and ru.datatypeID = 4		
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;
	
	merge into [orm_meta].[values_instance] as omv
	using @resolved_updated as ru
		on 	ru.instanceID = omv.instanceID
		and ru.propertyID = omv.propertyID
		and ru.datatypeID > 4
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;
	

end


IF OBJECT_ID('[orm_meta].[view_all_values_listing_insert]', 'TR') IS NOT NULL
	DROP TRIGGER [orm_meta].[view_all_values_listing_insert]
go


create trigger [orm_meta].[view_all_values_listing_insert]
	on [orm_meta].[all_values_listing]
	instead of insert
as 
begin

	declare @resolved_inserted table 
	(	templateID int not null
	,	instanceID int not null
	,	propertyID int not null
	,	datatypeID int not null
	,	value nvarchar(max)
	,	unique nonclustered (datatypeID, instanceID, propertyID)
	) 

	insert into @resolved_inserted
	select 	omt.templateID
		,	omi.instanceID 
		,	omp.propertyID 
		,	omp.datatypeID
		,	i.Value
	from inserted as i
		inner join [orm_meta].[templates] as omt 
			on	i.Template = omt.name
		inner join [orm_meta].[instances] as omi 
			on	i.Instance = omi.name
			and omt.templateID = omi.templateID
		inner join [orm_meta].[properties] as omp 
			on	i.Property = omp.name
			and omt.templateID = omp.templateID

	print 'inserting...'
	select * from @resolved_inserted as ri
	print 'this stuff...'


	; with filtered_values as
	(	select instanceID, propertyID, value
		from @resolved_inserted as ri 
		where ri.datatypeID = 1)
	merge into [orm_meta].[values_string] as omv
	using filtered_values as v
		on 	v.instanceID = omv.instanceID
		and v.propertyID = omv.propertyID
	when not matched then
		insert (  instanceID,   propertyID,   value)
		values (v.instanceID, v.propertyID, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;

	; with filtered_values as
	(	select instanceID, propertyID, value
		from @resolved_inserted as ri 
		where ri.datatypeID = 2)
	merge into [orm_meta].[values_integer] as omv
	using filtered_values as v
		on 	v.instanceID = omv.instanceID
		and v.propertyID = omv.propertyID
	when not matched then
		insert (  instanceID,   propertyID,   value)
		values (v.instanceID, v.propertyID, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;

	; with filtered_values as
	(	select instanceID, propertyID, value
		from @resolved_inserted as ri 
		where ri.datatypeID = 3)
	merge into [orm_meta].[values_decimal] as omv
	using filtered_values as v
		on 	v.instanceID = omv.instanceID
		and v.propertyID = omv.propertyID
	when not matched then
		insert (  instanceID,   propertyID,   value)
		values (v.instanceID, v.propertyID, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;
	
	; with filtered_values as
	(	select instanceID, propertyID, value
		from @resolved_inserted as ri 
		where ri.datatypeID = 4)
	merge into [orm_meta].[values_datetime] as omv
	using filtered_values as v
		on 	v.instanceID = omv.instanceID
		and v.propertyID = omv.propertyID
	when not matched then
		insert (  instanceID,   propertyID,   value)
		values (v.instanceID, v.propertyID, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;
	
	; with filtered_values as
	(	select instanceID, propertyID, value
		from @resolved_inserted as ri 
		where ri.datatypeID > 4)
	merge into [orm_meta].[values_instance] as omv
	using filtered_values as v
		on 	v.instanceID = omv.instanceID
		and v.propertyID = omv.propertyID
	when not matched then
		insert (  instanceID,   propertyID,   value)
		values (v.instanceID, v.propertyID, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;


end
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
	(	template_guid uniqueidentifier not null
	,	instance_guid uniqueidentifier not null
	,	property_guid uniqueidentifier
	,	datatype_guid uniqueidentifier 
	,	value nvarchar(max)
	,	unique nonclustered (datatype_guid, instance_guid, property_guid)
	) 

	insert into @resolved_deleted
	select 	omt.template_guid
		,	omi.instance_guid 
		,	omp.property_guid 
		,	omd.template_guid as datatype_guid
		,	d.Value
	from deleted as d
		inner join [orm_meta].[templates] as omt 
			on	d.Template = omt.name
		inner join [orm_meta].[instances] as omi 
			on	d.Instance = omi.name
			and omt.template_guid = omi.template_guid
		inner join [orm_meta].[properties] as omp 
			on	d.Property = omp.name
			and omt.template_guid = omp.template_guid
		inner join [orm_meta].[templates] as omd 
			on	d.Datatype = omd.name
			and omp.datatype_guid = omd.template_guid


	delete omv
	from [orm_meta].[values_string] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instance_guid = omv.instance_guid
			and rd.property_guid = omv.property_guid
	where rd.datatype_guid = 0x00000000000000000000000000000001

	delete omv
	from [orm_meta].[values_integer] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instance_guid = omv.instance_guid
			and rd.property_guid = omv.property_guid
	where rd.datatype_guid = 0x00000000000000000000000000000002

	delete omv
	from [orm_meta].[values_decimal] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instance_guid = omv.instance_guid
			and rd.property_guid = omv.property_guid
	where rd.datatype_guid = 0x00000000000000000000000000000003

	delete omv
	from [orm_meta].[values_datetime] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instance_guid = omv.instance_guid
			and rd.property_guid = omv.property_guid
	where rd.datatype_guid = 0x00000000000000000000000000000004

	delete omv
	from [orm_meta].[values_instance] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instance_guid = omv.instance_guid
			and rd.property_guid = omv.property_guid
	where rd.datatype_guid > 0x00000000000000000000000000000004
	
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
	(	template_guid uniqueidentifier not null
	,	instance_guid uniqueidentifier not null
	,	property_guid uniqueidentifier
	,	datatype_guid uniqueidentifier 
	,	value nvarchar(max)
	,	unique nonclustered (datatype_guid, instance_guid, property_guid)
	) 

	insert into @resolved_updated
	select 	omt.template_guid
		,	omi.instance_guid 
		,	omp.property_guid 
		,	omp.datatype_guid
		,	i.Value
	from inserted as i
		inner join [orm_meta].[templates] as omt 
			on	i.Template = omt.name
		inner join [orm_meta].[instances] as omi 
			on	i.Instance = omi.name
			and omt.template_guid = omi.template_guid
		inner join [orm_meta].[properties] as omp 
			on	i.Property = omp.name
			and omt.template_guid = omp.template_guid


	merge into [orm_meta].[values_string] as omv
	using @resolved_updated as ru
		on 	ru.instance_guid = omv.instance_guid
		and ru.property_guid = omv.property_guid
		and ru.datatype_guid = 0x00000000000000000000000000000001
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;

	merge into [orm_meta].[values_integer] as omv
	using @resolved_updated as ru
		on 	ru.instance_guid = omv.instance_guid
		and ru.property_guid = omv.property_guid
		and ru.datatype_guid = 0x00000000000000000000000000000002
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;

	merge into [orm_meta].[values_decimal] as omv
	using @resolved_updated as ru
		on 	ru.instance_guid = omv.instance_guid
		and ru.property_guid = omv.property_guid
		and ru.datatype_guid = 0x00000000000000000000000000000003
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;
	
	merge into [orm_meta].[values_datetime] as omv
	using @resolved_updated as ru
		on 	ru.instance_guid = omv.instance_guid
		and ru.property_guid = omv.property_guid
		and ru.datatype_guid = 0x00000000000000000000000000000004		
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;
	
	merge into [orm_meta].[values_instance] as omv
	using @resolved_updated as ru
		on 	ru.instance_guid = omv.instance_guid
		and ru.property_guid = omv.property_guid
		and ru.datatype_guid > 0x00000000000000000000000000000004
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
	(	template_guid uniqueidentifier not null
	,	instance_guid uniqueidentifier not null
	,	property_guid uniqueidentifier not null
	,	datatype_guid uniqueidentifier not null
	,	value nvarchar(max)
	,	unique nonclustered (datatype_guid, instance_guid, property_guid)
	) 

	insert into @resolved_inserted
	select 	omt.template_guid
		,	omi.instance_guid 
		,	omp.property_guid 
		,	omp.datatype_guid
		,	i.Value
	from inserted as i
		inner join [orm_meta].[templates] as omt 
			on	i.Template = omt.name
		inner join [orm_meta].[instances] as omi 
			on	i.Instance = omi.name
			and omt.template_guid = omi.template_guid
		inner join [orm_meta].[properties] as omp 
			on	i.Property = omp.name
			and omt.template_guid = omp.template_guid

	print 'inserting...'
	select * from @resolved_inserted as ri
	print 'this stuff...'


	; with filtered_values as
	(	select instance_guid, property_guid, value
		from @resolved_inserted as ri 
		where ri.datatype_guid = 0x00000000000000000000000000000001)
	merge into [orm_meta].[values_string] as omv
	using filtered_values as v
		on 	v.instance_guid = omv.instance_guid
		and v.property_guid = omv.property_guid
	when not matched then
		insert (  instance_guid,   property_guid,   value)
		values (v.instance_guid, v.property_guid, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;

	; with filtered_values as
	(	select instance_guid, property_guid, value
		from @resolved_inserted as ri 
		where ri.datatype_guid = 0x00000000000000000000000000000002)
	merge into [orm_meta].[values_integer] as omv
	using filtered_values as v
		on 	v.instance_guid = omv.instance_guid
		and v.property_guid = omv.property_guid
	when not matched then
		insert (  instance_guid,   property_guid,   value)
		values (v.instance_guid, v.property_guid, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;

	; with filtered_values as
	(	select instance_guid, property_guid, value
		from @resolved_inserted as ri 
		where ri.datatype_guid = 0x00000000000000000000000000000003)
	merge into [orm_meta].[values_decimal] as omv
	using filtered_values as v
		on 	v.instance_guid = omv.instance_guid
		and v.property_guid = omv.property_guid
	when not matched then
		insert (  instance_guid,   property_guid,   value)
		values (v.instance_guid, v.property_guid, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;
	
	; with filtered_values as
	(	select instance_guid, property_guid, value
		from @resolved_inserted as ri 
		where ri.datatype_guid = 0x00000000000000000000000000000004)
	merge into [orm_meta].[values_datetime] as omv
	using filtered_values as v
		on 	v.instance_guid = omv.instance_guid
		and v.property_guid = omv.property_guid
	when not matched then
		insert (  instance_guid,   property_guid,   value)
		values (v.instance_guid, v.property_guid, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;
	
	; with filtered_values as
	(	select instance_guid, property_guid, value
		from @resolved_inserted as ri 
		where ri.datatype_guid > 0x00000000000000000000000000000004)
	merge into [orm_meta].[values_instance] as omv
	using filtered_values as v
		on 	v.instance_guid = omv.instance_guid
		and v.property_guid = omv.property_guid
	when not matched then
		insert (  instance_guid,   property_guid,   value)
		values (v.instance_guid, v.property_guid, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;


end

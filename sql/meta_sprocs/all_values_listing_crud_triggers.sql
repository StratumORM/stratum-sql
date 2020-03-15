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
	(	template_id int not null
	,	instance_id int not null
	,	property_id int
	,	datatype_id int 
	,	value nvarchar(max)
	,	unique nonclustered (datatype_id, instance_id, property_id)
	) 

	insert into @resolved_deleted
	select 	omt.template_id
		,	omi.instance_id 
		,	omp.property_id 
		,	omd.template_id as datatype_id
		,	d.Value
	from deleted as d
		inner join [orm_meta].[templates] as omt 
			on	d.Template = omt.name
		inner join [orm_meta].[instances] as omi 
			on	d.Instance = omi.name
			and omt.template_id = omi.template_id
		inner join [orm_meta].[properties] as omp 
			on	d.Property = omp.name
			and omt.template_id = omp.template_id
		inner join [orm_meta].[templates] as omd 
			on	d.Datatype = omd.name
			and omp.datatype_id = omd.template_id


	delete omv
	from [orm_meta].[values_string] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instance_id = omv.instance_id
			and rd.property_id = omv.property_id
	where rd.datatype_id = 1

	delete omv
	from [orm_meta].[values_integer] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instance_id = omv.instance_id
			and rd.property_id = omv.property_id
	where rd.datatype_id = 2

	delete omv
	from [orm_meta].[values_decimal] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instance_id = omv.instance_id
			and rd.property_id = omv.property_id
	where rd.datatype_id = 3

	delete omv
	from [orm_meta].[values_datetime] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instance_id = omv.instance_id
			and rd.property_id = omv.property_id
	where rd.datatype_id = 4

	delete omv
	from [orm_meta].[values_instance] as omv 
		inner join @resolved_deleted as rd
			on 	rd.instance_id = omv.instance_id
			and rd.property_id = omv.property_id
	where rd.datatype_id > 4
	
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
	(	template_id int not null
	,	instance_id int not null
	,	property_id int
	,	datatype_id int 
	,	value nvarchar(max)
	,	unique nonclustered (datatype_id, instance_id, property_id)
	) 

	insert into @resolved_updated
	select 	omt.template_id
		,	omi.instance_id 
		,	omp.property_id 
		,	omp.datatype_id
		,	i.Value
	from inserted as i
		inner join [orm_meta].[templates] as omt 
			on	i.Template = omt.name
		inner join [orm_meta].[instances] as omi 
			on	i.Instance = omi.name
			and omt.template_id = omi.template_id
		inner join [orm_meta].[properties] as omp 
			on	i.Property = omp.name
			and omt.template_id = omp.template_id


	merge into [orm_meta].[values_string] as omv
	using @resolved_updated as ru
		on 	ru.instance_id = omv.instance_id
		and ru.property_id = omv.property_id
		and ru.datatype_id = 1
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;

	merge into [orm_meta].[values_integer] as omv
	using @resolved_updated as ru
		on 	ru.instance_id = omv.instance_id
		and ru.property_id = omv.property_id
		and ru.datatype_id = 2
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;

	merge into [orm_meta].[values_decimal] as omv
	using @resolved_updated as ru
		on 	ru.instance_id = omv.instance_id
		and ru.property_id = omv.property_id
		and ru.datatype_id = 3
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;
	
	merge into [orm_meta].[values_datetime] as omv
	using @resolved_updated as ru
		on 	ru.instance_id = omv.instance_id
		and ru.property_id = omv.property_id
		and ru.datatype_id = 4		
	when matched and not (ru.Value is null) then
		update
		set omv.value = ru.Value
	when matched and (ru.Value is null) then
		delete
	;
	
	merge into [orm_meta].[values_instance] as omv
	using @resolved_updated as ru
		on 	ru.instance_id = omv.instance_id
		and ru.property_id = omv.property_id
		and ru.datatype_id > 4
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
	(	template_id int not null
	,	instance_id int not null
	,	property_id int not null
	,	datatype_id int not null
	,	value nvarchar(max)
	,	unique nonclustered (datatype_id, instance_id, property_id)
	) 

	insert into @resolved_inserted
	select 	omt.template_id
		,	omi.instance_id 
		,	omp.property_id 
		,	omp.datatype_id
		,	i.Value
	from inserted as i
		inner join [orm_meta].[templates] as omt 
			on	i.Template = omt.name
		inner join [orm_meta].[instances] as omi 
			on	i.Instance = omi.name
			and omt.template_id = omi.template_id
		inner join [orm_meta].[properties] as omp 
			on	i.Property = omp.name
			and omt.template_id = omp.template_id

	print 'inserting...'
	select * from @resolved_inserted as ri
	print 'this stuff...'


	; with filtered_values as
	(	select instance_id, property_id, value
		from @resolved_inserted as ri 
		where ri.datatype_id = 1)
	merge into [orm_meta].[values_string] as omv
	using filtered_values as v
		on 	v.instance_id = omv.instance_id
		and v.property_id = omv.property_id
	when not matched then
		insert (  instance_id,   property_id,   value)
		values (v.instance_id, v.property_id, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;

	; with filtered_values as
	(	select instance_id, property_id, value
		from @resolved_inserted as ri 
		where ri.datatype_id = 2)
	merge into [orm_meta].[values_integer] as omv
	using filtered_values as v
		on 	v.instance_id = omv.instance_id
		and v.property_id = omv.property_id
	when not matched then
		insert (  instance_id,   property_id,   value)
		values (v.instance_id, v.property_id, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;

	; with filtered_values as
	(	select instance_id, property_id, value
		from @resolved_inserted as ri 
		where ri.datatype_id = 3)
	merge into [orm_meta].[values_decimal] as omv
	using filtered_values as v
		on 	v.instance_id = omv.instance_id
		and v.property_id = omv.property_id
	when not matched then
		insert (  instance_id,   property_id,   value)
		values (v.instance_id, v.property_id, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;
	
	; with filtered_values as
	(	select instance_id, property_id, value
		from @resolved_inserted as ri 
		where ri.datatype_id = 4)
	merge into [orm_meta].[values_datetime] as omv
	using filtered_values as v
		on 	v.instance_id = omv.instance_id
		and v.property_id = omv.property_id
	when not matched then
		insert (  instance_id,   property_id,   value)
		values (v.instance_id, v.property_id, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;
	
	; with filtered_values as
	(	select instance_id, property_id, value
		from @resolved_inserted as ri 
		where ri.datatype_id > 4)
	merge into [orm_meta].[values_instance] as omv
	using filtered_values as v
		on 	v.instance_id = omv.instance_id
		and v.property_id = omv.property_id
	when not matched then
		insert (  instance_id,   property_id,   value)
		values (v.instance_id, v.property_id, v.value)
	when matched and not (v.Value is null) then
		update
		set omv.value = v.Value
	when matched and (v.Value is null) then
		delete
	;


end

use orm_test
go

-- select * from [MES Equipment]

/*

declare	@root_object_guid uniqueidentifier
	,	@by_property_name varchar(255)

	set @root_object_guid = (
			select i.instance_guid
			from orm_meta.instances as i 
				inner join orm_meta.templates as t 
					on i.template_guid = t.template_guid
		---- from root down
		--	where t.name = 'Line' and i.name = 'Line 1'
		
		---- from middle out
			where t.name = 'Workcenter' and i.name = 'Line 1/Workcenter 1'
		
		---- from leaf up
		--	where t.name = 'Workstation' and i.name = 'Line 1/Workcenter 1/Workstation B'
		)
	set @by_property_name = 'parent'

select * from orm_meta.sub_instance_by_property(@root_object_guid , @by_property_name) as sibp
select * from orm_meta.super_instance_by_property(@root_object_guid , @by_property_name) as sibp
select * from orm_meta.instance_by_property_tree(@root_object_guid , @by_property_name) as sibp
*/


declare	@root_object_guid uniqueidentifier
	,	@by_property_name varchar(255)

	set @root_object_guid = (
			select i.instance_guid
			from orm_meta.instances as i 
				inner join orm_meta.templates as t 
					on i.template_guid = t.template_guid
		--	where t.name = 'Line' and i.name = 'Line 1'
			where t.name = 'Workcenter' and i.name = 'Line 1/Workcenter 1'
		--	where t.name = 'Workstation' and i.name = 'Line 1/Workcenter 1/Workstation B'
		)
	set @by_property_name = 'parent'

	; with related_properties as
	(	-- get all properties that if the same (or sub) 
		-- of the given property's datatype
		select sp.property_guid
		from orm_meta.properties as p
			inner join orm_meta.templates as t
				on p.template_guid = t.template_guid
			inner join orm_meta.instances as i
				on i.template_guid = t.template_guid
			cross apply orm_meta.sub_templates(p.datatype_guid) as sdt
			inner join orm_meta.properties as sp
				on sp.datatype_guid = sdt.template_guid
		where i.instance_guid = @root_object_guid
			and p.name = @by_property_name
			and sp.name = @by_property_name
	)
	,	children as
	(
		select @root_object_guid as instance_guid, 0 as echelon

		union all

		--select vi.value as instance_guid, tree.echelon + 1 as echelon
		select vi.instance_guid, tree.echelon - 1 as echelon
		from orm_meta.values_instance as vi
			inner join children as tree
			--	on vi.instance_guid = tree.instance_guid
				on vi.value = tree.instance_guid
			inner join related_properties as p
				on vi.property_guid = p.property_guid
	)
	select tree.instance_guid, tree.echelon --, i.name
	from children as tree
		inner join orm_meta.instances as i
			on tree.instance_guid = i.instance_guid


	; with related_properties as
	(	-- get all properties that if the same (or sub) 
		-- of the given property's datatype
		select sp.property_guid
		from orm_meta.properties as p
			inner join orm_meta.templates as t
				on p.template_guid = t.template_guid
			inner join orm_meta.instances as i
				on i.template_guid = t.template_guid
			cross apply orm_meta.sub_templates(p.datatype_guid) as sdt
			inner join orm_meta.properties as sp
				on sp.datatype_guid = sdt.template_guid
		where i.instance_guid = @root_object_guid
			and p.name = @by_property_name
			and sp.name = @by_property_name
	)
	,	parents as
	(
		select @root_object_guid as instance_guid, 0 as echelon

		union all

		select vi.value as instance_guid, tree.echelon + 1 as echelon
		from orm_meta.values_instance as vi
			inner join parents as tree
				on vi.instance_guid = tree.instance_guid
			inner join related_properties as p
				on vi.property_guid = p.property_guid
	)
	select tree.instance_guid, tree.echelon --, i.name
	from parents as tree
		inner join orm_meta.instances as i
			on tree.instance_guid = i.instance_guid



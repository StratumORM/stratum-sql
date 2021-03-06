print '
Generating helper views...'



IF OBJECT_ID('[orm].[template_properties]', 'V') IS NOT NULL
	DROP VIEW [orm].[template_properties]
go


create view [orm].[template_properties]
as

	select	t.name as [Template]
		,	p.name as [Property]
		,	d.name as [Datatype]
		,	t.template_guid
		,	p.property_guid
		,	d.template_guid as datatype_guid
	from orm_meta.templates as t
		inner join orm_meta.properties as p 
			on t.template_guid = p.template_guid
		inner join orm_meta.templates as d
			on p.datatype_guid = d.template_guid

go



IF OBJECT_ID('[orm].[instance_properties]', 'V') IS NOT NULL
	DROP VIEW [orm].[instance_properties]
go

create view [orm].[instance_properties]
as

	select	t.name as [Template]
		,	o.name as [Instance]
		,	p.name as [Property]
		,	d.name as [Datatype]
	from [orm_meta].[instances] as o
		inner join [orm_meta].[templates] as t
			on o.template_guid = t.template_guid
		inner join [orm_meta].[properties] as p
			on t.template_guid = p.template_guid
		inner join [orm_meta].[templates] as d
			on p.datatype_guid = d.template_guid
go

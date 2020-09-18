print '
Generating values views...'

IF OBJECT_ID('[orm].[values_string]', 'V') IS NOT NULL
	DROP VIEW [orm].[values_string]
go

create view [orm].[values_string]
as
	select	t.name as [template]
		,	o.name as [instance]
		,	p.name as [property]
		,	v.value
		--,	t.template_guid
		--,	o.instance_guid
		--,	p.property_guid
	from [orm_meta].[values_string] as v
		inner join [orm_meta].[instances] as o
			on v.instance_guid = o.instance_guid
		inner join [orm_meta].[properties] as p
			on v.property_guid = p.property_guid
		inner join [orm_meta].[templates] as t
			on p.template_guid = t.template_guid
	where p.datatype_guid = 0x00000000000000000000000000000001
	--order by t.template_guid, o.name, p.name
GO


IF OBJECT_ID('[orm].[values_integer]', 'V') IS NOT NULL
	DROP VIEW [orm].[values_integer]
go

create view [orm].[values_integer]
as
	select	t.name as [template]
		,	o.name as [instance]
		,	p.name as [property]
		,	v.value
		--,	t.template_guid
		--,	o.instance_guid
		--,	p.property_guid
	from [orm_meta].[values_integer] as v
		inner join [orm_meta].[instances] as o
			on v.instance_guid = o.instance_guid
		inner join [orm_meta].[properties] as p
			on v.property_guid = p.property_guid
		inner join [orm_meta].[templates] as t
			on p.template_guid = t.template_guid
	where p.datatype_guid = 0x00000000000000000000000000000002
	--order by t.template_guid, o.name, p.name
GO


IF OBJECT_ID('[orm].[values_decimal]', 'V') IS NOT NULL
	DROP VIEW [orm].[values_decimal]
go

create view [orm].[values_decimal]
as
	select	t.name as [template]
		,	o.name as [instance]
		,	p.name as [property]
		,	v.value
		--,	t.template_guid
		--,	o.instance_guid
		--,	p.property_guid
	from [orm_meta].[values_decimal] as v
		inner join [orm_meta].[instances] as o
			on v.instance_guid = o.instance_guid
		inner join [orm_meta].[properties] as p
			on v.property_guid = p.property_guid
		inner join [orm_meta].[templates] as t
			on p.template_guid = t.template_guid
	where p.datatype_guid = 0x00000000000000000000000000000003
	--order by t.template_guid, o.name, p.name
GO


IF OBJECT_ID('[orm].[values_datetime]', 'V') IS NOT NULL
	DROP VIEW [orm].[values_datetime]
go

create view [orm].[values_datetime]
as
	select	t.name as [template]
		,	o.name as [instance]
		,	p.name as [property]
		,	v.value
		--,	t.template_guid
		--,	o.instance_guid
		--,	p.property_guid
	from [orm_meta].[values_datetime] as v
		inner join [orm_meta].[instances] as o
			on v.instance_guid = o.instance_guid
		inner join [orm_meta].[properties] as p
			on v.property_guid = p.property_guid
		inner join [orm_meta].[templates] as t
			on p.template_guid = t.template_guid
	where p.datatype_guid = 0x00000000000000000000000000000004
	--order by t.template_guid, o.name, p.name
GO

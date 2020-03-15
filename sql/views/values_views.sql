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
		--,	t.template_id
		--,	o.instance_id
		--,	p.property_id
	from [orm_meta].[values_string] as v
		inner join [orm_meta].[instances] as o
			on v.instance_id = o.instance_id
		inner join [orm_meta].[properties] as p
			on v.property_id = p.property_id
		inner join [orm_meta].[templates] as t
			on p.template_id = t.template_id
	where p.datatype_id = 1
	--order by t.template_id, o.name, p.name
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
		--,	t.template_id
		--,	o.instance_id
		--,	p.property_id
	from [orm_meta].[values_integer] as v
		inner join [orm_meta].[instances] as o
			on v.instance_id = o.instance_id
		inner join [orm_meta].[properties] as p
			on v.property_id = p.property_id
		inner join [orm_meta].[templates] as t
			on p.template_id = t.template_id
	where p.datatype_id = 2
	--order by t.template_id, o.name, p.name
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
		--,	t.template_id
		--,	o.instance_id
		--,	p.property_id
	from [orm_meta].[values_decimal] as v
		inner join [orm_meta].[instances] as o
			on v.instance_id = o.instance_id
		inner join [orm_meta].[properties] as p
			on v.property_id = p.property_id
		inner join [orm_meta].[templates] as t
			on p.template_id = t.template_id
	where p.datatype_id = 3
	--order by t.template_id, o.name, p.name
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
		--,	t.template_id
		--,	o.instance_id
		--,	p.property_id
	from [orm_meta].[values_datetime] as v
		inner join [orm_meta].[instances] as o
			on v.instance_id = o.instance_id
		inner join [orm_meta].[properties] as p
			on v.property_id = p.property_id
		inner join [orm_meta].[templates] as t
			on p.template_id = t.template_id
	where p.datatype_id = 4
	--order by t.template_id, o.name, p.name
GO

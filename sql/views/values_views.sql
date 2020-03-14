print '
Generating values views...'

IF OBJECT_ID('[dbo].[orm_values_string]', 'V') IS NOT NULL
	DROP VIEW [dbo].[orm_values_string]
go

create view [dbo].[orm_values_string]
as
	select	t.name as [template]
		,	o.name as [instance]
		,	p.name as [property]
		,	v.value
		--,	t.templateID
		--,	o.instanceID
		--,	p.propertyID
	from orm_meta_values_string as v
		inner join orm_meta_instances as o
			on v.instanceID = o.instanceID
		inner join orm_meta_properties as p
			on v.propertyID = p.propertyID
		inner join orm_meta_templates as t
			on p.templateID = t.templateID
	where p.datatypeID = 1
	--order by t.templateID, o.name, p.name
GO


IF OBJECT_ID('[dbo].[orm_values_integer]', 'V') IS NOT NULL
	DROP VIEW [dbo].[orm_values_integer]
go

create view [dbo].[orm_values_integer]
as
	select	t.name as [template]
		,	o.name as [instance]
		,	p.name as [property]
		,	v.value
		--,	t.templateID
		--,	o.instanceID
		--,	p.propertyID
	from orm_meta_values_integer as v
		inner join orm_meta_instances as o
			on v.instanceID = o.instanceID
		inner join orm_meta_properties as p
			on v.propertyID = p.propertyID
		inner join orm_meta_templates as t
			on p.templateID = t.templateID
	where p.datatypeID = 2
	--order by t.templateID, o.name, p.name
GO


IF OBJECT_ID('[dbo].[orm_values_decimal]', 'V') IS NOT NULL
	DROP VIEW [dbo].[orm_values_decimal]
go

create view [dbo].[orm_values_decimal]
as
	select	t.name as [template]
		,	o.name as [instance]
		,	p.name as [property]
		,	v.value
		--,	t.templateID
		--,	o.instanceID
		--,	p.propertyID
	from orm_meta_values_decimal as v
		inner join orm_meta_instances as o
			on v.instanceID = o.instanceID
		inner join orm_meta_properties as p
			on v.propertyID = p.propertyID
		inner join orm_meta_templates as t
			on p.templateID = t.templateID
	where p.datatypeID = 3
	--order by t.templateID, o.name, p.name
GO


IF OBJECT_ID('[dbo].[orm_values_datetime]', 'V') IS NOT NULL
	DROP VIEW [dbo].[orm_values_datetime]
go

create view [dbo].[orm_values_datetime]
as
	select	t.name as [template]
		,	o.name as [instance]
		,	p.name as [property]
		,	v.value
		--,	t.templateID
		--,	o.instanceID
		--,	p.propertyID
	from orm_meta_values_datetime as v
		inner join orm_meta_instances as o
			on v.instanceID = o.instanceID
		inner join orm_meta_properties as p
			on v.propertyID = p.propertyID
		inner join orm_meta_templates as t
			on p.templateID = t.templateID
	where p.datatypeID = 4
	--order by t.templateID, o.name, p.name
GO
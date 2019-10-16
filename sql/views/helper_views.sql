print '
Generating helper views...'


IF OBJECT_ID('[dbo].[orm_instance_properties]', 'V') IS NOT NULL
	DROP VIEW [dbo].orm_instance_properties
go

create view orm_instance_properties
as

	select	t.name as [Template]
		,	o.name as [Instance]
		,	p.name as [Property]
		,	d.name as [Datatype]
	from orm_meta_instances as o
		inner join orm_meta_templates as t
			on o.templateID = t.templateID
		inner join orm_meta_properties as p
			on t.templateID = p.templateID
		inner join orm_meta_templates as d
			on p.datatypeID = d.templateID
go

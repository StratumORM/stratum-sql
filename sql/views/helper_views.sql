print '
Generating helper views...'


IF OBJECT_ID('[orm].[instance_properties]', 'V') IS NOT NULL
	DROP VIEW [orm].[instance_properties]
go

create view orm_instance_properties
as

	select	t.name as [Template]
		,	o.name as [Instance]
		,	p.name as [Property]
		,	d.name as [Datatype]
	from [orm_meta].[instances] as o
		inner join [orm_meta].[templates] as t
			on o.templateID = t.templateID
		inner join [orm_meta].[properties] as p
			on t.templateID = p.templateID
		inner join [orm_meta].[templates] as d
			on p.datatypeID = d.templateID
go

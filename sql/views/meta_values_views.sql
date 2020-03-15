print '
Generating meta value views...'

IF OBJECT_ID('[orm_meta].[all_values]', 'V') IS NOT NULL
	DROP VIEW [orm_meta].[all_values]
go

create view [orm_meta].[all_values]
as
	-- This is primarily a template view.
	-- But it's useful as a consolidated place to scan for everything

	select  o.name as Name
		,	p.name as Property

		,	vi.value as [Integer]
		,	vf.value as [Float]
		,	vs.value as [String]
		,	vd.value as [Date]
		,	vo.value as [Instance]
	
		,	o.instance_id
		,	p.property_id
	
	from	[orm_meta].[instances] as o
		inner join [orm_meta].[properties] as p
			on o.template_id = p.template_id

		left join [orm_meta].[values_integer]	as vi
			on	o.instance_id   = vi.instance_id
			and	p.property_id = vi.property_id

		left join [orm_meta].[values_decimal]	as vf
			on	o.instance_id   = vf.instance_id
			and	p.property_id = vf.property_id

		left join [orm_meta].[values_string]	as vs
			on	o.instance_id   = vs.instance_id
			and	p.property_id = vs.property_id

		left join [orm_meta].[values_datetime]	as vd
			on	o.instance_id   = vd.instance_id
			and	p.property_id = vd.property_id

		left join [orm_meta].[values_instance]	as vo
			on	o.instance_id   = vo.instance_id
			and	p.property_id = vo.property_id			
go


IF OBJECT_ID('[orm_meta].[all_values_listing]', 'V') IS NOT NULL
	DROP VIEW [orm_meta].[all_values_listing]
go

create view [orm_meta].[all_values_listing]
as
	-- This is primarily a template view.
	-- But it's useful as a consolidated place to scan for everything

	select 	t.name as Template,
			o.name as Instance
		,	p.name as Property
		,	v.value as Value
		,	d.name as Datatype
	
	from	[orm_meta].[instances] as o
		inner join [orm_meta].[templates] as t
			on o.template_id = t.template_id
		inner join [orm_meta].[properties] as p
			on o.template_id = p.template_id
		inner join [orm_meta].[templates] as d
			on p.datatype_id = d.template_id
		inner join
		(	select instance_id, property_id, convert(nvarchar(max),value) as value
			from [orm_meta].[values_integer]
			
			union

			select instance_id, property_id, convert(nvarchar(max),value) as value
			from [orm_meta].[values_decimal]

			union

			select instance_id, property_id, convert(nvarchar(max),value) as value
			from [orm_meta].[values_string]

			union
						-- convert the datetime to ODBC canonical yyyy-mm-dd hh:mi:ss.mmm
			select instance_id, property_id, convert(nvarchar(max),value, 121) as value
			from [orm_meta].[values_datetime]

			union

			select instance_id, property_id, convert(nvarchar(max),value) as value
			from [orm_meta].[values_instance]
		) as v
			on	o.instance_id   = v.instance_id
			and	p.property_id = v.property_id
GO

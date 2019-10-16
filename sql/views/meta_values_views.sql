print '
Generating meta value views...'

IF OBJECT_ID('[dbo].[orm_meta_all_values]', 'V') IS NOT NULL
	DROP VIEW [dbo].orm_meta_all_values
go

create view orm_meta_all_values
as
	-- This is primarily a template view.
	-- But it's useful as a consolidated place to scan for everything

	select  o.name as Name
		,	p.name as Property

		,	vi.value as IntValue
		,	vf.value as FloatValue
		,	vs.value as StringValue
		,	vd.value as DateValue
		,	vo.value as InstanceValue
	
		,	o.instanceID
		,	p.propertyID
	
	from	orm_meta_instances as o
		inner join orm_meta_properties as p
			on o.templateID = p.templateID

		left join orm_meta_values_integer	as vi
			on	o.instanceID   = vi.instanceID
			and	p.propertyID = vi.propertyID

		left join orm_meta_values_decimal	as vf
			on	o.instanceID   = vf.instanceID
			and	p.propertyID = vf.propertyID

		left join orm_meta_values_string	as vs
			on	o.instanceID   = vs.instanceID
			and	p.propertyID = vs.propertyID

		left join orm_meta_values_datetime	as vd
			on	o.instanceID   = vd.instanceID
			and	p.propertyID = vd.propertyID

		left join orm_meta_values_instance	as vo
			on	o.instanceID   = vo.instanceID
			and	p.propertyID = vo.propertyID			
go


IF OBJECT_ID('[dbo].[orm_meta_all_values_listing]', 'V') IS NOT NULL
	DROP VIEW [dbo].[orm_meta_all_values_listing]
go

create view [dbo].[orm_meta_all_values_listing]
as
	-- This is primarily a template view.
	-- But it's useful as a consolidated place to scan for everything

	select 	t.name as Template,
			o.name as Instance
		,	p.name as Property
		,	v.value as Value
		,	d.name as Datatype
	
	from	orm_meta_instances as o
		inner join orm_meta_templates as t
			on o.templateID = t.templateID
		inner join orm_meta_properties as p
			on o.templateID = p.templateID
		inner join orm_meta_templates as d
			on p.datatypeID = d.templateID
		inner join
		(	select instanceID, propertyID, convert(nvarchar(max),value) as value
			from orm_meta_values_integer
			
			union

			select instanceID, propertyID, convert(nvarchar(max),value) as value
			from orm_meta_values_decimal

			union

			select instanceID, propertyID, convert(nvarchar(max),value) as value
			from orm_meta_values_string

			union
						-- convert the datetime to ODBC canonical yyyy-mm-dd hh:mi:ss.mmm
			select instanceID, propertyID, convert(nvarchar(max),value, 121) as value
			from orm_meta_values_datetime

			union

			select instanceID, propertyID, convert(nvarchar(max),value) as value
			from orm_meta_values_instance
		) as v
			on	o.instanceID   = v.instanceID
			and	p.propertyID = v.propertyID
GO

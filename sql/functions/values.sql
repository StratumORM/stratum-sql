print '
Generating value functions...'


if object_id('[orm].[values]', 'IF') is not null
	drop function [orm].[values]
go

create function [orm].[values]
(
	@template_name varchar(250)
)
returns table
as
return
(
	-- This is a generic view on the template's values
	--	presented in a format similar to Ignition's historian tables.

	select  o.name as Name
		,	p.name as Property

		,	vi.value as [Integer]
		,	vf.value as [Float]
		,	vs.value as [String]
		,	vd.value as [Date]
		,	vo.value as [Instance]
	
		,	o.instance_guid
		,	p.property_guid
	
	from	[orm_meta].[instances] as o
		inner join [orm_meta].[properties] as p
			on o.template_guid = p.template_guid

		inner join [orm_meta].[templates] as t 
			on p.template_guid = t.template_guid

		left join [orm_meta].[values_integer]	as vi
			on	o.instance_guid = vi.instance_guid
			and	p.property_guid = vi.property_guid

		left join [orm_meta].[values_decimal]	as vf
			on	o.instance_guid = vf.instance_guid
			and	p.property_guid = vf.property_guid

		left join [orm_meta].[values_string]	as vs
			on	o.instance_guid = vs.instance_guid
			and	p.property_guid = vs.property_guid

		left join [orm_meta].[values_datetime]	as vd
			on	o.instance_guid = vd.instance_guid
			and	p.property_guid = vd.property_guid

		left join [orm_meta].[values_instance]	as vo
			on	o.instance_guid = vo.instance_guid
			and	p.property_guid = vo.property_guid

	where t.name = @template_name
)
GO


if object_id('[orm].[values_listing]', 'IF') is not null
	drop function [orm].[values_listing]
go

create function [orm].[values_listing]
(
	@template_name varchar(250)
)
returns table
as
return
(
	-- This is a view on the template's values where one row per value
	--	and makes the values stringly-typed.
	-- Use this when you want a simple, unified view on the data,
	--	especially when looping over the data.

	select 
			o.name as [Instance]
		,	p.name as Property
		,	isnull(v.value,'') as Value
		,	d.name as Datatype
		,	o.instance_guid
		,	p.property_guid
		,	p.datatype_guid
	
	from	[orm_meta].[instances] as o
		inner join [orm_meta].[templates] as t
			on o.template_guid = t.template_guid
		inner join [orm_meta].[properties] as p
			on o.template_guid = p.template_guid
		inner join [orm_meta].[templates] as d
			on p.datatype_guid = d.template_guid
		inner join
		(	select instance_guid, property_guid, convert(nvarchar(max), vi.value) as value
			from [orm_meta].[values_integer] as vi
			
			union

			select instance_guid, property_guid, convert(nvarchar(max), vf.value) as value
			from [orm_meta].[values_decimal] as vf

			union

			select instance_guid, property_guid, convert(nvarchar(max), vs.value) as value
			from [orm_meta].[values_string] as vs

			union
						-- convert the datetime to ODBC canonical yyyy-mm-dd hh:mi:ss.mmm
			select instance_guid, property_guid, convert(nvarchar(max), vd.value, 121) as value
			from [orm_meta].[values_datetime] as vd

			union

			select instance_guid, property_guid, convert(nvarchar(max), vo.value) as value
			from [orm_meta].[values_instance] as vo

		) as v
			on	o.instance_guid = v.instance_guid
			and	p.property_guid = v.property_guid
	where t.name = @template_name
)
GO

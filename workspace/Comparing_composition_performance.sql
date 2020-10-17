use orm_test
go
/*
	The following is a very simple test for performance.

	The first two are essentially identical, and the query executed
	  for both is 19% of the work.

	The last is 62% of the work. Technically the same work, 
	  but in practice more complex.

	But! If you look at the estimated query plans and add them up, 
	  each is fairly close to one third of the total work. Neat!

*/

declare @property_guid uniqueidentifier
	,	@instance_guid uniqueidentifier

	set @instance_guid = orm_meta.resolve_instance_guid('Line', 'Line 1')
	set @property_guid = orm_meta.resolve_property_guid('Line', 'state')

select hvi.*
from orm_meta.history_values_integer(@instance_guid, @property_guid) as hvi

go


select hvi.*
from orm_meta.history_values_integer(
			orm_meta.resolve_instance_guid('Line', 'Line 1')
		,	orm_meta.resolve_property_guid('Line', 'state')
		) as hvi

go


select hvi.*
from orm_meta.templates as t
	inner join orm_meta.instances as i
		on t.template_guid = i.template_guid
	inner join orm_meta.properties as p
		on t.template_guid = p.template_guid
	cross apply orm_meta.history_values_integer(i.instance_guid, p.property_guid) as hvi
where t.name = 'Line'
	and i.name = 'Line 1'
	and p.name = 'state'






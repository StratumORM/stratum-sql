

print 'Testing inheritance...'

print '... renaming str_# to someString to force collision'
-- next we'll want to make sure there's property to collision so we have something to resolve
exec orm_property_rename 'ONE','str_1','someString'
go
exec orm_property_rename 'TWO','str_2','someString'
go
exec orm_property_rename 'THREE','str_3','someString'
go
exec orm_property_rename 'FOUR','str_4','someString'
go

truncate table orm_meta_inheritance

print 'Marking THREE to inherit from TWO and ONE, in that order'
-- let's say that THREE inherits from TWO and ONE, in that order
declare @oneType int, @twoType int, @threeType int, @fourType int
	set @oneType = (select top 1 typeID from orm_meta_types where name = 'ONE')
	set @twoType = (select top 1 typeID from orm_meta_types where name = 'TWO')
	set @threeType = (select top 1 typeID from orm_meta_types where name = 'THREE')
	set @fourType = (select top 1 typeID from orm_meta_types where name = 'FOUR')

insert into orm_meta_inheritance (parentTypeID, childTypeID, ordinal)
values	(@twoType, @threeType, 1)
	,	(@oneType, @threeType, 2)
	,	(@threeType, @fourType, 1)

update p
set p.isExtended = 1
from orm_meta_properties as p
	inner join orm_meta_types as t
		on p.typeID = t.typeID
where t.typeID = @threeType
	and p.name = 'someString'
go


print 'Testing inheritance tree functions...(2,3,2,3)'
select * from dbo.orm_meta_subTypes(5) as subs
select * from dbo.orm_meta_superTypes(7) as supers

select * from dbo.orm_meta_typeTree(5) as fullTree
select * from dbo.orm_meta_typeTree(7) as fullTree
/*
select * from orm_ONE_listing
select * from orm_ONE_wide
select * from orm_ONE_values
*/


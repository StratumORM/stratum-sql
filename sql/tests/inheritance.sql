

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

truncate table [orm_meta].[inheritance]

print 'Marking THREE to inherit from TWO and ONE, in that order'
-- let's say that THREE inherits from TWO and ONE, in that order
declare @oneTemplate int, @twoTemplate int, @threeTemplate int, @fourTemplate int
	set @oneTemplate = (select top 1 templateID from [orm_meta].[templates] where name = 'ONE')
	set @twoTemplate = (select top 1 templateID from [orm_meta].[templates] where name = 'TWO')
	set @threeTemplate = (select top 1 templateID from [orm_meta].[templates] where name = 'THREE')
	set @fourTemplate = (select top 1 templateID from [orm_meta].[templates] where name = 'FOUR')

insert into [orm_meta].[inheritance] (parentTemplateID, childTemplateID, ordinal)
values	(@twoTemplate, @threeTemplate, 1)
	,	(@oneTemplate, @threeTemplate, 2)
	,	(@threeTemplate, @fourTemplate, 1)

update p
set p.isExtended = 1
from [orm_meta].[properties] as p
	inner join [orm_meta].[templates] as t
		on p.templateID = t.templateID
where t.templateID = @threeTemplate
	and p.name = 'someString'
go


print 'Testing inheritance tree functions...(2,3,2,3)'
select * from [orm_meta].[subTemplates](5) as subs
select * from [orm_meta].[superTemplates](7) as supers

select * from [orm_meta].[templateTree](5) as fullTree
select * from [orm_meta].[templateTree](7) as fullTree
/*
select * from orm_ONE_listing
select * from orm_ONE_wide
select * from orm_ONE_values
*/


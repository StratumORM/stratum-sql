

print 'Testing inheritance...'

print '... renaming str_# to someString to force collision'
-- next we'll want to make sure there's property to collision so we have something to resolve
exec [orm].[property_rename] 'ONE','str_1','someString'
go
exec [orm].[property_rename] 'TWO','str_2','someString'
go
exec [orm].[property_rename] 'THREE','str_3','someString'
go
exec [orm].[property_rename] 'FOUR','str_4','someString'
go

truncate table [orm_meta].[inheritance]

print 'Marking THREE to inherit from TWO and ONE, in that order'
-- let's say that THREE inherits from TWO and ONE, in that order
declare @one_template int, @two_template int, @three_template int, @four_template int
	set @one_template = (select top 1 template_id from [orm_meta].[templates] where name = 'ONE')
	set @two_template = (select top 1 template_id from [orm_meta].[templates] where name = 'TWO')
	set @three_template = (select top 1 template_id from [orm_meta].[templates] where name = 'THREE')
	set @four_template = (select top 1 template_id from [orm_meta].[templates] where name = 'FOUR')

insert into [orm_meta].[inheritance] (parent_template_id, child_template_id, ordinal)
values	(@two_template, @three_template, 1)
	,	(@one_template, @three_template, 2)
	,	(@three_template, @four_template, 1)

update p
set p.is_extended = 1
from [orm_meta].[properties] as p
	inner join [orm_meta].[templates] as t
		on p.template_id = t.template_id
where t.template_id = @three_template
	and p.name = 'someString'
go


print 'Testing inheritance tree functions...(2,3,2,3)'
select * from [orm_meta].[sub_templates](5) as subs
select * from [orm_meta].[super_templates](7) as supers

select * from [orm_meta].[template_tree](5) as full_tree
select * from [orm_meta].[template_tree](7) as full_tree
/*
select * from [orm].[ONE_listing]
select * from [orm].[ONE_wide]
select * from [orm].[ONE_values]
*/


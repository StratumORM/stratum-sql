use orm_test
go

select * from [orm_meta].[templates]

select * from [orm_meta].[properties]
where templateID = 7

select v.* 
from [orm_meta].[values_decimal] as v
	inner join [orm_meta].[properties] as p
		on v.propertyID = p.propertyID
where p.templateID = 6

select * 
from [orm_meta].[instances]

select *
from [Another Thing]

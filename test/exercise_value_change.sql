use orm_test
go


exec orm.template_add 'T'
go

exec orm.property_add 'T', 'str', 'string'
exec orm.property_add 'T', 'dec', 'decimal'
exec orm.property_add 'T', 'int', 'integer'
exec orm.property_add 'T', 'dtm', 'datetime'
exec orm.property_add 'T', 'ins', 'T'
go

exec orm.instance_add 'T', 'inst-1'
exec orm.instance_add 'T', 'inst-2'
go

exec orm.value_change 'T', 'inst-1', 'str', 'word 1'
exec orm.value_change 'T', 'inst-1', 'dec', 1.234
exec orm.value_change 'T', 'inst-1', 'int', 1234
exec orm.value_change 'T', 'inst-1', 'dtm', '2021-11-10 12:34:56.123456+03:00'
exec orm.value_change 'T', 'inst-1', 'ins', 'inst-1'
go

exec orm.value_change 'T', 'inst-1', 'str', 'word 2'
exec orm.value_change 'T', 'inst-1', 'dec', 5.678
exec orm.value_change 'T', 'inst-1', 'int', 5678
exec orm.value_change 'T', 'inst-1', 'dtm', '2021-12-12 12:12:12.121212+03:00'
exec orm.value_change 'T', 'inst-1', 'ins', 'inst-2'
go

exec orm.template_remove 'T'
--exec orm.instance_remove 'T', 'inst-1'
go

select * from orm_meta.templates
select * from orm_meta.instances

select value as current_value from orm_meta.values_string
select value as history_value from orm_hist.values_string

select value as current_value from orm_meta.values_decimal
select value as history_value from orm_hist.values_decimal

select value as current_value from orm_meta.values_integer
select value as history_value from orm_hist.values_integer

select value as current_value from orm_meta.values_datetime
select value as history_value from orm_hist.values_datetime

select value as current_value from orm_meta.values_instance
select value as history_value from orm_hist.values_instance

go

/*
-- should throw an error
exec orm.value_change 'T', 'inst-1', 'ins', 'inst-3'

*/
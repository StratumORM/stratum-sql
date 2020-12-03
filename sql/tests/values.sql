

--=============================================================================
--									  Reset!
--=============================================================================

-- exec [orm_meta].[PURGE_OBJECTS] 'I really mean it'
-- go

-- TODO
delete from orm_meta.templates where template_id > 4
go

--=============================================================================
--										
--=============================================================================

if OBJECT_ID('[orm].[test_init_object]','P') is not null
	drop procedure [orm].test_init_object
go

create procedure orm.test_init_object
	@template_name varchar(250)
as
begin
	declare @num int, @object_name varchar(250), @prop_name varchar(250)
	declare @int bigint, @str nvarchar(max), @dt datetimeoffset(7), @dec decimal(19,8)
	declare @multiplier bigint
	
	print 'add a new template: ' + @template_name
	exec [orm].[template_add] @template_name

	set @num = (select obj_num
				from (	select name
						,	row_number() over (order by template_id) as obj_num 
						from [orm_meta].[templates] 
						where template_id > 4
					) as objnums
				where name = @template_name)
	set @object_name = 'obj_' + @template_name

	print 'instance an object: ' + @object_name
	--set @prop_name = 'Test object ' + convert(varchar(250), @num)
	exec [orm].[instance_add]	@template_name, @object_name --, @prop_name

	print 'add some properties and values to ' + @template_name

	set @multiplier = 10000
	set @dec = @multiplier * rand()
	set @int = round(@dec*@multiplier,0)
	set @str = 'some string ' + convert(nvarchar(max), @dec)
	set @dt = dateadd(second, @dec*@multiplier*10, '1985-01-01')

	set @prop_name = 'str_' + convert(varchar(250), @num)
	exec [orm].[property_add]	@template_name, @prop_name, 'nvarchar(max)'
	exec [orm].[value_change]	@template_name, @object_name, @prop_name, @str

	set @prop_name = 'num_' + convert(varchar(250), @num)
	exec [orm].[property_add]	@template_name, @prop_name, 'bigInt'
	exec [orm].[value_change]	@template_name, @object_name, @prop_name, @int

	set @prop_name = 'real_' + convert(varchar(250), @num)
	exec [orm].[property_add]	@template_name, @prop_name, 'decimal(19,8)'
	exec [orm].[value_change]	@template_name, @object_name, @prop_name, @dec
	
	set @prop_name = 'dt_' + convert(varchar(250), @num)
	exec [orm].[property_add]	@template_name, @prop_name, 'datetime'
	exec [orm].[value_change]	@template_name, @object_name, @prop_name, @dt

end 
go

--=============================================================================
--									Main script
--=============================================================================

print 'Running object value test...'

exec orm.test_init_object 'ONE'
exec orm.test_init_object 'TWO'
exec orm.test_init_object 'THREE'
exec orm.test_init_object 'FOUR'
exec orm.test_init_object 'FIVE'
exec orm.test_init_object 'SIX'

--print 'Testing object references...'

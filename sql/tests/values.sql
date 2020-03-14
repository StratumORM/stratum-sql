

--=============================================================================
--									  Reset!
--=============================================================================

exec orm_meta_PURGE_OBJECTS 'I really mean it'
go

--=============================================================================
--										
--=============================================================================

if OBJECT_ID('[dbo].[test_init_object]','P') is not null
	drop procedure [dbo].test_init_object
go

create procedure test_init_object
	@templateName varchar(250)
as
begin
	declare @num int, @objectName varchar(250), @propName varchar(250)
	declare @int bigint, @str nvarchar(max), @dt datetime, @dec decimal(19,8)
	declare @multiplier bigint
	
	print 'add a new template: ' + @templateName
	exec orm_template_add @templateName

	set @num = (select objNum
				from (	select name
						,	row_number() over (order by templateID) as objNum 
						from orm_meta_templates 
						where templateid > 4
					) as objnums
				where name = @templateName)
	set @objectName = 'obj_' + @templateName

	print 'instance an object: ' + @objectName
	set @propName = 'Test object ' + convert(varchar(250), @num)
	exec orm_create_object	@templateName, @objectName, @propName

	print 'add some properties and values to ' + @templateName

	set @multiplier = 10000
	set @dec = @multiplier * rand()
	set @int = round(@dec*@multiplier,0)
	set @str = 'some string ' + convert(nvarchar(max), @dec)
	set @dt = dateadd(second, @dec*@multiplier*10, '1985-01-01')

	set @propName = 'str_' + convert(varchar(250), @num)
	exec orm_property_add	@templateName, @propName, 'nvarchar(max)'
	exec orm_change_value	@templateName, @objectName, @propName, @str

	set @propName = 'num_' + convert(varchar(250), @num)
	exec orm_property_add	@templateName, @propName, 'bigInt'
	exec orm_change_value	@templateName, @objectName, @propName, @int

	set @propName = 'real_' + convert(varchar(250), @num)
	exec orm_property_add	@templateName, @propName, 'decimal(19,8)'
	exec orm_change_value	@templateName, @objectName, @propName, @dec
	
	set @propName = 'dt_' + convert(varchar(250), @num)
	exec orm_property_add	@templateName, @propName, 'datetime'
	exec orm_change_value	@templateName, @objectName, @propName, @dt

end 
go

--=============================================================================
--									Main script
--=============================================================================

print 'Running object value test...'

exec test_init_object 'ONE'
exec test_init_object 'TWO'
exec test_init_object 'THREE'
exec test_init_object 'FOUR'
exec test_init_object 'FIVE'
exec test_init_object 'SIX'

--print 'Testing object references...'


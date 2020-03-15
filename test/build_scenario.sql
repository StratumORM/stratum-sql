use orm_test
go


-- For convenience and clarity, gather the IDs as needed
declare @String_Type_ID   int
	,	@Integer_Type_ID  int
	,	@Decimal_Type_ID  int
	,	@Datetime_Type_ID int
	set @String_Type_ID   = (select top 1 template_id from [orm_meta].[templates] where name = 'nvarchar(max)')
	set @Integer_Type_ID  = (select top 1 template_id from [orm_meta].[templates] where name = 'bigint')
	set @Decimal_Type_ID  = (select top 1 template_id from [orm_meta].[templates] where name = 'decimal(19,8)')
	set @Datetime_Type_ID = (select top 1 template_id from [orm_meta].[templates] where name = 'datetime')



-- Create the types
insert into [orm_meta].[templates] (name)
values ('First Type'),('Another Thing')
exec [orm].[template_add] 'Third Type'

-- For convenience get the IDs for the types
declare @FirstType_ID int
	,	@AnotherThing_ID int
	,	@ThirdType_ID int
	set @FirstType_ID    = (select top 1 template_id from [orm_meta].[templates] where name = 'First Type')
	set @AnotherThing_ID = (select top 1 template_id from [orm_meta].[templates] where name = 'Another Thing')
	set @ThirdType_ID    = (select top 1 template_id from [orm_meta].[templates] where name = 'Third Type')


-- Add some properties to the types
exec [orm].[property_add] 'First Type', 'Integer', 'bigint'
insert into [orm_meta].[properties] (template_id, name, datatype_id)
values	(5, 'String', 1) -- 5 happens to be the first ID after the base 4. 
	,	(@FirstType_ID, 'DT', @Datetime_Type_ID)

exec [orm].[property_add] 'Another Thing', 'Realish', 'decimal(19,8)'
exec [orm].[property_add] 'Another Thing', 'Real 2', 'decimal(19,8)'

insert into [orm_meta].[properties] (template_id, name, datatype_id)
values	(@ThirdType_ID, 'Addon Prop', 1)
	,	(@ThirdType_ID, 'Beginning', @Datetime_Type_ID)
	,	(@ThirdType_ID, 'Ending', 4)

-- Create some instances
insert into [orm_meta].[instances] (template_id, name)
values	(5, 'FirstObj')
	,	(@ThirdType_ID, 'ThirdObj')

exec [orm].[instance_add] 'Another Thing', 'Another Obj'
exec [orm].[instance_add] 'Another Thing', 'AnotherObject2'

declare @FirstObj_ID int
	,	@ThirdObj_ID int
	,	@AnotherObj_ID int
	,	@AnotherObject2 int
	set @FirstObj_ID    = (select top 1 instance_id from [orm_meta].[instances] where name = 'FirstObj')
	set @ThirdObj_ID    = (select top 1 instance_id from [orm_meta].[instances] where name = 'ThirdObj')
	set @AnotherObj_ID  = (select top 1 instance_id from [orm_meta].[instances] where name = 'Another Obj')
	set @AnotherObject2 = (select top 1 instance_id from [orm_meta].[instances] where name = 'AnotherObject2')


-- Add some data
exec [orm].[value_change] 'First Type', 'FirstObj', 'String', 'First words.'
exec [orm].[value_change_datetime] 'First Type', 'FirstObj', 'DT', '2020-02-20 20:02'

declare @template_id int, @instance_id int, @property_id int
	set @template_id	= (select top 1 template_id from [orm_meta].[templates] where name = 'First Type')
	set @instance_id	= (select top 1 instance_id from [orm_meta].[instances] where name = 'FirstObj' and template_id = @template_id)
	set @property_id	= (select top 1 property_id from [orm_meta].[properties] where name = 'DT' and template_id = @template_id)

insert into [orm_meta].[values_decimal] (instance_id, property_id, value)
	values (  @AnotherObj_ID
			, (select top 1 property_id  
			   from [orm_meta].[properties]  
			   where template_id = @AnotherThing_ID 
			   and name = 'Real 2')
			, 123.45)

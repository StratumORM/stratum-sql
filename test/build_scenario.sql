use orm_test
go


-- For convenience and clarity, gather the IDs as needed
declare @String_Type_ID   int
	,	@Integer_Type_ID  int
	,	@Decimal_Type_ID  int
	,	@Datetime_Type_ID int
	set @String_Type_ID   = (select top 1 templateid from [orm_meta].[templates] where name = 'nvarchar(max)')
	set @Integer_Type_ID  = (select top 1 templateid from [orm_meta].[templates] where name = 'bigint')
	set @Decimal_Type_ID  = (select top 1 templateid from [orm_meta].[templates] where name = 'decimal(19,8)')
	set @Datetime_Type_ID = (select top 1 templateid from [orm_meta].[templates] where name = 'datetime')



-- Create the types
insert into [orm_meta].[templates] (name)
values ('FirstType'),('AnotherThing')
exec [orm].[template_add] 'ThirdType'

-- For convenience get the IDs for the types
declare @FirstType_ID int
	,	@AnotherThing_ID int
	,	@ThirdType_ID int
	set @FirstType_ID    = (select top 1 templateid from [orm_meta].[templates] where name = 'FirstType')
	set @AnotherThing_ID = (select top 1 templateid from [orm_meta].[templates] where name = 'AnotherThing')
	set @ThirdType_ID    = (select top 1 templateid from [orm_meta].[templates] where name = 'ThirdType')


-- Add some properties to the types
exec [orm].[property_add] 'FirstType', 'Integer', 'bigint'
insert into [orm_meta].[properties] (templateID, name, datatypeID)
values	(5, 'String', 1) -- 5 happens to be the first ID after the base 4. 
	,	(@FirstType_ID, 'DT', @Datetime_Type_ID)

exec [orm].[property_add] 'AnotherThing', 'Realish', 'decimal(19,8)'
exec [orm].[property_add] 'AnotherThing', 'Real2', 'decimal(19,8)'

insert into [orm_meta].[properties] (templateID, name, datatypeID)
values	(@ThirdType_ID, 'AddonProp', 1)
	,	(@ThirdType_ID, 'Beginning', @Datetime_Type_ID)
	,	(@ThirdType_ID, 'Ending', 4)

-- Create some instances
insert into [orm_meta].[instances] (templateID, name)
values	(5, 'FirstObj')
	,	(@ThirdType_ID, 'ThirdObj')

exec [orm].[instance_add] 'AnotherThing', 'AnotherObj'
exec [orm].[instance_add] 'AnotherThing', 'AnotherObject2'

declare @FirstObj_ID int
	,	@ThirdObj_ID int
	,	@AnotherObj_ID int
	,	@AnotherObject2 int
	set @FirstObj_ID    = (select top 1 instanceID from [orm_meta].[instances] where name = 'FirstObj')
	set @ThirdObj_ID    = (select top 1 instanceID from [orm_meta].[instances] where name = 'ThirdObj')
	set @AnotherObj_ID  = (select top 1 instanceID from [orm_meta].[instances] where name = 'AnotherObj')
	set @AnotherObject2 = (select top 1 instanceID from [orm_meta].[instances] where name = 'AnotherObject2')


-- Add some data
exec [orm].[value_change] 'FirstType', 'FirstObj', 'String', 'First words.'
exec [orm].[value_change_datetime] 'FirstType', 'FirstObj', 'DT', '2020-02-20 20:02'

declare @templateID int, @instanceID int, @propertyID int
	set @templateID	= (select top 1 templateID from [orm_meta].[templates] where name = 'FirstType')
	set @instanceID	= (select top 1 instanceID from [orm_meta].[instances] where name = 'FirstObj' and templateID = @templateID)
	set @propertyID	= (select top 1 propertyID from [orm_meta].[properties] where name = 'DT' and templateID = @templateID)

insert into [orm_meta].[values_decimal] (instanceID, propertyID, value)
	values (  @AnotherObj_ID
			, (select top 1 propertyID  
			   from [orm_meta].[properties]  
			   where templateID = @AnotherThing_ID 
			   and name = 'Real2')
			, 123.45)
print '
Adding in context execution flow flagging...'



if object_id('[orm_meta].[check_context]', 'FN') is not null
	drop function [orm_meta].[check_context]
go

IF object_id('[orm_meta].[context]', 'U') is not null
	drop table [orm_meta].[context]
go



create table [orm_meta].[context] 
(
	flag nvarchar(40)
,	bits bigint -- binary(64)

,	constraint pk__orm_meta_context__flag
		primary key
		clustered (flag, bits)
,	constraint u1__orm_meta_context__flag
		unique nonclustered (flag)
,	constraint u1__orm_meta_context__bits
		unique nonclustered (bits)
)

go


-- offset for history flagging: 0x000
declare @padding varbinary(128)
	set @padding = 0x000

insert into [orm_meta].[context] (flag, bits)
values	('bypass values string history'   , 0x01 + @padding)
	,	('bypass values integer history'  , 0x02 + @padding)
	,	('bypass values decimal history'  , 0x04 + @padding)
	,	('bypass values datetime history' , 0x08 + @padding)
	,	('bypass values instance history' , 0x10 + @padding)
	    -- all together now
	,	('bypass values history'          , 0x1F + @padding)


go



create function [orm_meta].[check_context]
(
	@flag nvarchar(40)
)
returns bit
	with schemabinding
as
begin
	return (
		select case
			when bits & CONTEXT_INFO() = bits then 1
			else 0
		end
		from [orm_meta].[context]
		where flag = @flag
	)
end
go


if object_id('[orm_meta].[apply_context]', 'P') is not null
	drop procedure [orm_meta].[apply_context]
go


create procedure [orm_meta].[apply_context]
	@flag nvarchar(40)
,	@state bit
as
begin
	set nocount on

	declare @bits bigint
		,	@mask bigint
		,	@result binary(128)

	set @bits = (select top 1 bits 
				 from orm_meta.context 
				 where flag = @flag   )

	set @mask = cast(substring(context_info(), 65, 64) as bigint)

	if @state = 1
		set @mask = @mask | @bits
	else
		set @mask = ~(~@mask | @bits)

	set @result = substring(context_info(),  1, 64) + @mask
	set context_info @result

end
go

/*
select top 1 bits 
from orm_meta.context 
where flag = 'bypass values history'
-- 126976
*/

--set context_info 0x0
/*
exec orm_meta.apply_context 'bypass values history', 1

exec orm_meta.apply_context 'bypass values string history', 0

print orm_meta.check_context('bypass values string history')
print orm_meta.check_context('bypass values integer history')

print context_info()
*/
-- set context_info 0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FF00111111
--set context_info 0x0
/*
	declare @flag nvarchar(40)
		,	@state bit

	set @flag = 'bypass values history'
	set @state = 0

	declare @bits bigint
		,	@mask bigint
		,	@result binary(128)

	set @bits = (select top 1 bits 
				 from orm_meta.context 
				 where flag = @flag   )

print 'starting context_info'
print context_info()
print substring(context_info(),  1, 64) 
print substring(context_info(), 65, 64)

print 'bits'
print convert(binary(64), @bits)

	set @mask = cast(substring(context_info(), 65, 64) as bigint)

print convert(binary(64), @mask)

		
	if @state = 1
		set @mask = @mask | @bits
	else
		set @mask = ~(~@mask | @bits)

print convert(binary(64), @mask)

	
	-- set @result = convert(binary(128),
	-- 				concat(
	-- 					@mask, substring(context_info(), 65, 64)
	-- 				))
					
	-- set @result = @mask

	set @result = substring(context_info(),  1, 64) + @mask


set context_info @result

print 'final context_info'
print context_info()
print substring(context_info(),  1, 64) 
print substring(context_info(), 65, 64)
*/
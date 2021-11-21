print '
Adding in context execution flow flagging...'

/*
	Some explanation is in order, because bit bashing in SQL is unorthidox.
	We're using them because flags are super handy for program flow control.
	Flow control is needed so that things can be interlocked and managed
	on a per-session OR per-batch OR per-statement setup. This way, we don't
	need to worry about making special procedures when a simple IF will do.

	First, a few foundational bits. In Transact-SQL, these are what we'll be
	working with:
	 - `tinyint`           1 byte   0xFF
	 - `bigint`            8 bytes  0xFFFFFFFFFFFFFFFF
	 - `varbinary(8)`      8 bytes  0xFFFFFFFFFFFFFFFF
	 - `context_info()`  128 bytes  ... it's big, ok?

	We can flip bits via bit-wise operations. But these can ONLY be performed
	on stuff that is of the integer type. But `context_info()` is of type
	varbinary, not integer. In fact, no integer is big enough to work on the
	whole of `context_info()` at once.

	To change `context_info()` we must work on chunks of it. That sounds tricky,
	but note that `varbinary` is essentially identical to an ASCII string. 
	As a result we can operate on it via the STUFF function, essentially
	deleting and STUFFing our replacement in.

	 - `SUBSTRING`
	   - expression
	   - start (chunk)
	   - length (8)

	 - `STUFF`   
	   - character_expression
	   - start (chunk)
	   - length (8)
	   - new_masked_values

	NOTE: bits are ONE INDEXED! That means that you start in the first bit: 1!


*/





if object_id('[orm_meta].[check_context]', 'FN') is not null
	drop function [orm_meta].[check_context]
go


if object_id('[orm_meta].[apply_context]', 'P') is not null
	drop procedure [orm_meta].[apply_context]
go


IF object_id('[orm_meta].[context]', 'U') is not null
	drop table [orm_meta].[context]
go


create table [orm_meta].[context] 
(
	flag nvarchar(40) not null
,	chunk tinyint     not null -- which 8-byte chunk bits apply to
,	bits bigint       not null -- binary(8)

,	constraint chk__orm_meta_context__valid_chunks
		check (chunk between 1 and 16)

,	constraint pk__orm_meta_context__flag_chunk_bits
		primary key
		clustered (flag, chunk, bits)
,	constraint u1__orm_meta_context__flag
		unique nonclustered (flag)
,	constraint u1__orm_meta_context__chunk_bits
		unique nonclustered (chunk, bits)
)

go



insert into [orm_meta].[context] (flag, chunk, bits)
values	('bypass values string history'   , 2, 0x01)
	,	('bypass values integer history'  , 2, 0x02)
	,	('bypass values decimal history'  , 2, 0x04)
	,	('bypass values datetime history' , 2, 0x08)
	,	('bypass values instance history' , 2, 0x10)
	    -- all together now
	,	('bypass values history'          , 2, 0x1F)


-- Molly Guards: prevent dangerous things by default
-- 
-- The scheme here is that you turn on master,
--   turn off interlock, and then always check
--   that it's armed but the interlock is off.
-- Roundabout? Yeah. It's meant to block wildly
--   destructive things.
insert into [orm_meta].[context] (flag, chunk, bits)
values	('purge master'          , 4, 0x07)  -- 111
	,	('purge armed'           , 4, 0x05)  -- 101
	,	('purge interlock'       , 4, 0x02)  -- 010

	,	('overwrite init backups', 4, 0x10)
	,	('restore init backups', 4, 0x20)


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
			when bits & 
				convert(bigint
					,	substring(
							context_info()
							,	((chunk-1)*8) + 1
							, 8
				)) = bits then 1
			else 0
		end
		from [orm_meta].[context]
		where flag = @flag
	)
end
go



create procedure [orm_meta].[apply_context]
	@flag nvarchar(40)
,	@state bit
as
begin
	set nocount on

	-- Make sure this is something we can work with
	if context_info() is null
		set context_info 0x0

	declare @chunk tinyint
		,	@bits bigint
		,	@mask bigint
		,	@result varbinary(128)

		select	@chunk = chunk
			,	@bits = bits
		from orm_meta.context 
		where flag = @flag

	set @mask = substring(context_info(), ((@chunk-1)*8) + 1, 8)

	if @state = 1
		set @mask = @mask | @bits
	else
		set @mask = ~(~@mask | @bits)

	-- effectively STUFF the new values in the middle of the current context_info
	-- get the preceding chunks, the current masked chunk, and the remaining chunks
	set @result = convert(binary(128), concat(
						substring(context_info()
								 , 1              -- start at the beginning
								 , (@chunk-1)*8)  -- lenght of preceding chunks (is 1-indexed (to follow convention))
					,	convert(binary(8), @mask) -- add in the new bit states
					,	substring(context_info()
					             , @chunk*8+1     -- start at the end, plus one (1-indexed!)
								 , (16-@chunk)*8) -- len (16 8-byte chunks in 128 bytes)
					))

		-- For posterity, note that this doens't work. I forget the error.
		--   But it led directly to the above which frankly should be fine.
		-- convert(binary(128), stuff(context_info(), @chunk*8, 8, @mask))

	set context_info @result

end
go

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

use xacttest
go

if object_id('t1', 'U') is not null
	drop table t1
if object_id('t2', 'U') is not null
	drop table t2

if object_id('handle_error', 'P') is not null
	drop procedure handle_error

if object_id('div_by_zero', 'P') is not null
	drop procedure div_by_zero
go

create procedure handle_error
	@calling_context nvarchar(50) = null
,	@message_context nvarchar(255) = null
,	@padding int = 30

as
begin
    declare @error_message nvarchar(max), @error_severity int, @error_state int
	begin try
		set @calling_context = OBJECT_NAME(@calling_context)
	end try begin catch
		set @calling_context = isnull(@calling_context, error_procedure())
	end catch

	if @message_context is not null
		set @message_context = '
		' + @message_context
	else
		set @message_context = ''

	if @padding is null
		set @error_message = @calling_context
	else
		set @error_message = right(space(@padding) + @calling_context, @padding) 

    select  @error_message = error_message()
    		+ @message_context
			+ '
			Found in ' + @error_message 
			+ ' at Line ' + cast(error_line() as nvarchar(5))
			+ ' (XACT: ' + cast(xact_state() as nvarchar(2)) + ')'
			+ ' [' + cast(error_number() as nvarchar(20)) + ', '
			+        cast(error_severity() as nvarchar(20)) + ']'
		,	@error_severity = error_severity()
		,	@error_state = error_state()
	
	-- Do we need to rollback?
	-- As a rule for Stratum, do not commit partial results,
	--   so this will rollback on both uncommittable AND partially valid
	--   transacted scripts
	--if @@TRANCOUNT > 0 -- a transaction is live
	if xact_state() <> 0 -- 0 means no transaction
	begin
		print 'WARNING: rolling back transaction!'
		rollback transaction -- rolls back all
	end

    raiserror (@error_message, @error_severity, @error_state)
end
go





create procedure div_by_zero
	@i int = null
as
begin
begin try
begin transaction

	set nocount on;

	if @i % 2 = 0
		set @i = 1/0

commit transaction
end try
begin catch
	exec handle_error 'div_by_zero', 'DIVIDE ZERO'
end catch
end
go




create table t1 (c1 int)

create table t2 (c2 int, c3 int)
go


create trigger tr_t1_ins
	on t1
	instead of insert
as 
begin
begin try
begin transaction
	
	set nocount on;

	insert into t2 (c2)
	select c1 from inserted

commit transaction
end try
begin catch
	exec handle_error 'tr_t1_ins!!', 'TRIGGER FAIL'
end catch
end
go


create trigger tr_t2_ins
	on t2
	instead of insert
as
begin
begin try
begin transaction

	set nocount on;

	insert into t2 (c3)
	select c2 from inserted

	exec div_by_zero 2

commit transaction
end try
begin catch
	exec handle_error @@PROCID
end catch
end

go



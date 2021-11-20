

IF OBJECT_ID('[orm_meta].[handle_error]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[handle_error]
go



create procedure [orm_meta].[handle_error]
	@calling_context nvarchar(50) = null
,	@message_context nvarchar(255) = null
,	@padding int = 30
,	@tx nvarchar(32) = null

as
begin
    declare @error_message nvarchar(max)
    	,	@error_severity int
    	,	@error_state int
    	,	@error_number int
    	set @error_number = error_number()

	begin try
		set @calling_context = OBJECT_SCHEMA_NAME(@calling_context) + '.' + OBJECT_NAME(@calling_context)
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
			+ ' (XACT: ' + cast(@@trancount as nvarchar(2)) 
			      + ': ' + cast(xact_state() as nvarchar(2)) + ')'
			+ ' [' + cast(@error_number as nvarchar(20)) + ', '
			+        cast(error_severity() as nvarchar(20)) + ']'
		,	@error_severity = error_severity()
		,	@error_state = error_state()
	;
	--print 'b4 (XACT: ' + cast(@@trancount as nvarchar(2)) + ': ' + cast(xact_state() as nvarchar(2)) + ')'
	
	-- Do we need to rollback?
	-- As a rule for Stratum, do not commit partial results,
	--   so this will rollback on both uncommittable AND partially valid
	--   transacted scripts	
	-- There's more logic here than needed, since we're gonna fail hard on any error
	-- if @@trancount = 0 rollback

	if xact_state() <> 0 or @@trancount > 0
	begin
		if @tx is null 
			rollback transaction
		else
			rollback transaction @tx
		-- if xact_state() = -1
		-- 	begin
		-- 		print 'ALERT: transaction failed - rolling back all transactions'
		-- 		rollback
		-- 	end
		-- else
		-- begin 
		-- 	if xact_state() = 1 and @@trancount = 0
		-- 		begin
		-- 			print 'Warning: error - rolling outer back'
		-- 			rollback
		-- 		end
		-- 	else 
		-- 	begin
		-- 		if xact_state() = 1 and @@trancount > 0
		-- 			begin
		-- 				print 'Warning: transactions failed - multiple rolling back'
		-- 				rollback
		-- 			end
		-- 	end
		-- end
	end
	--print 'after (XACT: ' + cast(@@trancount as nvarchar(2)) + ': ' + cast(xact_state() as nvarchar(2)) + ')'

	--commit -- reduce the transaction count by 1

    --raiserror (@error_message, @error_severity, @error_state)
    ;throw @error_number, @error_message, @error_state;
end
go
go
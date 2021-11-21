print '
Adding purge routines...'


/*
	NOTE: Each stored procedure is designed to DESTROY the data
	      in Stratum! Each will obliterate any data stored!

	Each sproc uses TRUNCATE TABLE (where possible)
	  to ensure that the data is immediately lost and deleted
	  without logging.

	These functions CAN NOT BE ROLLED BACK.

	Some tables have foreign key enforcement. These tables MUST
	  use a DELETE instead. These deletes have been chunked to
	  ensure SQL Server can't crash itself from log usage.

	You have been warned.
*/



IF OBJECT_ID('[orm_xo].[purge_history]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_xo].[purge_history]
go


create procedure [orm_xo].[purge_history]
	@cutoff datetimeoffset(7) = null
as
begin
begin try

  set nocount on;

    if (   [orm_meta].[check_context]('purge armed') = 0      -- purge must be armed on
	    or [orm_meta].[check_context]('purge interlock') = 1) -- interlock must be off
	begin             -- (NOTE: when setting master ON, interlock automatically turns on!)
		;throw 51000, 'Purge safety not met! To allow, set purge master on and then interlock off.', 1;
	end

	-- values
	TRUNCATE TABLE [orm_hist].[values_string];
	TRUNCATE TABLE [orm_hist].[values_integer];
	TRUNCATE TABLE [orm_hist].[values_decimal];
	TRUNCATE TABLE [orm_hist].[values_datetime];
	TRUNCATE TABLE [orm_hist].[values_instance];

	TRUNCATE TABLE [orm_hist].[instances];
	TRUNCATE TABLE [orm_hist].[inheritance];
	TRUNCATE TABLE [orm_hist].[properties];
	TRUNCATE TABLE [orm_hist].[templates];

end try
begin catch
	-- clear the purge setup for safety reasons
	exec [orm_meta].[apply_context] 'purge master', 0
	exec [orm_meta].[handle_error] @@PROCID

end catch
end
go



IF OBJECT_ID('[orm_xo].[purge_values]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_xo].[purge_values]
go


create procedure [orm_xo].[purge_values]
	@cutoff datetimeoffset(7) = null
as
begin
begin try

  set nocount on;

    if (   [orm_meta].[check_context]('purge armed') = 0      -- purge must be armed on
	    or [orm_meta].[check_context]('purge interlock') = 1) -- interlock must be off
	begin             -- (NOTE: when setting master ON, interlock automatically turns on!)
		;throw 51000, 'Purge safety not met! To allow, set purge master on and then interlock off.', 1;
	end

	-- values
	TRUNCATE TABLE [orm_meta].[values_string];
	TRUNCATE TABLE [orm_meta].[values_integer];
	TRUNCATE TABLE [orm_meta].[values_decimal];
	TRUNCATE TABLE [orm_meta].[values_datetime];
	TRUNCATE TABLE [orm_meta].[values_instance];

end try
begin catch
	-- clear the purge setup for safety reasons
	exec [orm_meta].[apply_context] 'purge master', 0
	exec [orm_meta].[handle_error] @@PROCID

end catch
end
go



IF OBJECT_ID('[orm_xo].[purge_metadata]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_xo].[purge_metadata]
go


create procedure [orm_xo].[purge_metadata]
	@cutoff datetimeoffset(7) = null
as
begin
begin try

  set nocount on;

    if (   [orm_meta].[check_context]('purge armed') = 0      -- purge must be armed on
	    or [orm_meta].[check_context]('purge interlock') = 1) -- interlock must be off
	begin             -- (NOTE: when setting master ON, interlock automatically turns on!)
		;throw 51000, 'Purge safety not met! To allow, set purge master on and then interlock off.', 1;
	end

  	declare @deleted_rows int

	-- metadata tables
	-- NOTE: these tables have foreign key constraints
	--   SQL Server will _not_ allow these table to truncate
	print 'Purging instances...'
  	set @deleted_rows = 1 -- get started
  	while @deleted_rows > 0
  	begin
  	  begin transaction row_purge

  	  	delete top (10000) [orm_meta].[instances];
  	  	set @deleted_rows = @@rowcount

  	  commit transaction row_purge
  	end

	print 'Purging inheritance...'
  	set @deleted_rows = 1 -- get started
  	while @deleted_rows > 0
  	begin
  	  begin transaction row_purge

  	  	delete top (100) [orm_meta].[inheritance];
  	  	set @deleted_rows = @@rowcount

  	  commit transaction row_purge
  	end

	print 'Purging properties...'
  	set @deleted_rows = 1 -- get started
  	while @deleted_rows > 0
  	begin
  	  begin transaction row_purge

  	  	delete top (1000) [orm_meta].[properties];
  	  	set @deleted_rows = @@rowcount

  	  commit transaction row_purge
  	end


	print 'Purging templates...'
  	set @deleted_rows = 1 -- get started
  	while @deleted_rows > 0
  	begin
  	  begin transaction row_purge

  	  	delete top (100) [orm_meta].[templates]
  	  		where template_id > 4
  	  	;
  	  	set @deleted_rows = @@rowcount

  	  commit transaction row_purge
  	end

end try
begin catch
	-- clear the purge setup for safety reasons
	exec [orm_meta].[apply_context] 'purge master', 0
	exec [orm_meta].[handle_error] @@PROCID

end catch
end
go



IF OBJECT_ID('[orm_xo].[purge_staged]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_xo].[purge_staged]
go


create procedure [orm_xo].[purge_staged]
	@cutoff datetimeoffset(7) = null
as
begin
begin try

  set nocount on;

    if (   [orm_meta].[check_context]('purge armed') = 0      -- purge must be armed on
	    or [orm_meta].[check_context]('purge interlock') = 1) -- interlock must be off
	begin             -- (NOTE: when setting master ON, interlock automatically turns on!)
		;throw 51000, 'Purge safety not met! To allow, set purge master on and then interlock off.', 1;
	end

	TRUNCATE TABLE [orm_temp].[values_string];
	TRUNCATE TABLE [orm_temp].[values_integer];
	TRUNCATE TABLE [orm_temp].[values_decimal];
	TRUNCATE TABLE [orm_temp].[values_datetime];
	TRUNCATE TABLE [orm_temp].[values_instance];

	-- metadata tables
	TRUNCATE TABLE [orm_temp].[instances];
	TRUNCATE TABLE [orm_temp].[properties];
	TRUNCATE TABLE [orm_temp].[inheritance];
	TRUNCATE TABLE [orm_temp].[templates];

end try
begin catch
	-- clear the purge setup for safety reasons
	exec [orm_meta].[apply_context] 'purge master', 0
	exec [orm_meta].[handle_error] @@PROCID

end catch
end
go



IF OBJECT_ID('[orm_xo].[clear_all_tables]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_xo].[clear_all_tables]
go

create procedure [orm_xo].[clear_all_tables]
	@final_interlock nvarchar(100) = NULL
as
begin
begin try

  set nocount on;

  	if @final_interlock <> 'Release restraint level ... 0'

    if (   [orm_meta].[check_context]('purge armed') <> 1      -- purge must be armed on
	    or [orm_meta].[check_context]('purge interlock') <> 0) -- interlock must be off
	begin             -- (NOTE: when setting master ON, interlock automatically turns on!)
		;throw 51000, 'Purge safety not met! To allow, set purge master on and then interlock off.', 1;
	end

	exec [orm_xo].[purge_history]
  	exec [orm_xo].[purge_staged]
  	exec [orm_xo].[purge_values]
  	exec [orm_xo].[purge_metadata]


	exec [orm_meta].[apply_context] 'restore init backups', 1
  	exec [orm_xo].[restore_init_tables]

end try
begin catch
	-- clear the purge setup for safety reasons
	exec [orm_meta].[apply_context] 'purge master', 0
	exec [orm_meta].[handle_error] @@PROCID

end catch
end
go


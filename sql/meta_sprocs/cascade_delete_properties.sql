print '
Generating value cleanup sproc...'

IF OBJECT_ID('[orm_meta].[cascade_delete_property]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[cascade_delete_property]
go


IF TYPE_ID('[orm_meta].[identities]') IS NULL
-- 	DROP TYPE [orm_meta].[identities]
-- go

	CREATE TYPE [orm_meta].[identities] AS TABLE(
		guid uniqueidentifier NOT NULL,
		PRIMARY KEY CLUSTERED (	[guid] ASC )
			WITH (IGNORE_DUP_KEY = OFF)
	)
GO


create procedure [orm_meta].[cascade_delete_property]
	@property_guids identities READONLY
as
begin
begin try
begin transaction cascaded_property_delete

	set nocount on;

	-- Perform the cascading delete on the values tables 
	delete v
	from [orm_meta].[values_string] as v 
		inner join @property_guids as dp 
			on v.property_guid = dp.guid

	delete v
	from [orm_meta].[values_integer] as v 
		inner join @property_guids as dp 
			on v.property_guid = dp.guid
		
	delete v
	from [orm_meta].[values_decimal] as v 
		inner join @property_guids as dp 
			on v.property_guid = dp.guid
		
	delete v
	from [orm_meta].[values_datetime] as v 
		inner join @property_guids as dp 
			on v.property_guid = dp.guid
		
	delete v
	from [orm_meta].[values_instance] as v 
		inner join @property_guids as dp 
			on v.property_guid = dp.guid

commit transaction cascaded_property_delete

end try
begin catch
    declare @error_message nvarchar(max), @error_severity int, @error_state int
    select  @error_message = ERROR_MESSAGE() 
			+ ' Found in ' + ERROR_PROCEDURE() 
			+ ' at Line ' + cast(ERROR_LINE() as nvarchar(5))
		,	@error_severity = ERROR_SEVERITY()
		,	@error_state = ERROR_STATE()
    rollback transaction
    raiserror (@error_message, @error_severity, @error_state)
end catch
end
go

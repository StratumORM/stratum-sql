print '
Generating value cleanup sproc...'

IF OBJECT_ID('[orm_meta].[cascadeDelete_property]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[cascadeDelete_property]
go

create procedure [orm_meta].[cascadeDelete_property]
	@propertyIDs identities READONLY
as
begin
begin try
begin transaction cascadedPropertyDelete

	set nocount on;

	-- Perform the cascading delete on the values tables 
	delete v
	from [orm_meta].[values_string] as v 
		inner join @propertyIDs as dp 
			on v.propertyID = dp.id

	delete v
	from [orm_meta].[values_integer] as v 
		inner join @propertyIDs as dp 
			on v.propertyID = dp.id
		
	delete v
	from [orm_meta].[values_decimal] as v 
		inner join @propertyIDs as dp 
			on v.propertyID = dp.id
		
	delete v
	from [orm_meta].[values_datetime] as v 
		inner join @propertyIDs as dp 
			on v.propertyID = dp.id
		
	delete v
	from [orm_meta].[values_instance] as v 
		inner join @propertyIDs as dp 
			on v.propertyID = dp.id

	commit transaction cascadedPropertyDelete

end try
begin catch
    declare @ErrorMessage nvarchar(max), @ErrorSeverity int, @ErrorState int
    select @ErrorMessage = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5)), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE()
    rollback transaction
    raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState)
end catch
end
go

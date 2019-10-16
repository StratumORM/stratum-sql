print '
Generating value cleanup sproc...'

IF OBJECT_ID('[dbo].[orm_meta_cascadeDelete_property]', 'P') IS NOT NULL
	DROP PROCEDURE [dbo].orm_meta_cascadeDelete_property
go

create procedure orm_meta_cascadeDelete_property
	@propertyIDs identities READONLY
as
begin
begin try
begin transaction cascadedPropertyDelete

	set nocount on;

	-- Perform the cascading delete on the values tables 
	delete v
	from orm_meta_values_string as v 
		inner join @propertyIDs as dp 
			on v.propertyID = dp.id

	delete v
	from orm_meta_values_integer as v 
		inner join @propertyIDs as dp 
			on v.propertyID = dp.id
		
	delete v
	from orm_meta_values_decimal as v 
		inner join @propertyIDs as dp 
			on v.propertyID = dp.id
		
	delete v
	from orm_meta_values_datetime as v 
		inner join @propertyIDs as dp 
			on v.propertyID = dp.id
		
	delete v
	from orm_meta_values_instance as v 
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

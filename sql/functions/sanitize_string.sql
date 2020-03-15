print '
Generating scalar function meta_sanitize_string...'



IF OBJECT_ID('[orm_meta].[sanitize_string]', 'FN') IS NOT NULL
	drop function [orm_meta].[sanitize_string]
go

-- =============================================
-- Author:		Andrew Geiger
-- Create date: 2015-06-02
-- Description: Only allows alphanumeric characters
--  to make sure templates and properties are clean to be
--  dynamically put in a sql query.
--  Gotted from http://stackoverflow.com/a/1008566
-- =============================================
create function [orm_meta].[sanitize_string]
(
	@Temp VarChar(1000)
)
Returns VarChar(1000)
AS
begin

    declare @KeepValues varchar(50)
    	Set @KeepValues = '%[^a-z0-9A-Z_]%'
    	
    While PatIndex(@KeepValues, @Temp) > 0
        Set @Temp = Stuff(@Temp, PatIndex(@KeepValues, @Temp), 1, '')

    return @Temp
end
go

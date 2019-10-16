print '
Generating update_columns decoder ring...'


IF OBJECT_ID('[dbo].[orm_meta_decodeUpdatedColumnsBitmask]', 'FN') IS NOT NULL
	drop function [dbo].orm_meta_decodeUpdatedColumnsBitmask
go

create function dbo.orm_meta_decodeUpdatedColumnsBitmask
(
	@updatedColumns varbinary(255)
,	@tableName varchar(100)
)
returns table
AS
return
(
	; with columnNames as
	(
		select 	COLUMN_NAME
			,	COLUMNPROPERTY(OBJECT_ID(@tableName), COLUMN_NAME, 'ColumnID') AS COLUMN_ID
		from INFORMATION_SCHEMA.COLUMNS c
		where TABLE_NAME = @tableName
	)
	select columnNames.COLUMN_NAME
	from columnNames 
	where power(2, columnNames.column_id) & @updatedColumns > 0
)
go

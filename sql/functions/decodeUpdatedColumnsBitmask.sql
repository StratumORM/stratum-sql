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
	with columnNames as
	(
		select 	COLUMN_NAME
			,	COLUMNPROPERTY(OBJECT_ID(@tableName), COLUMN_NAME, 'ColumnID') AS COLUMN_ID
		from INFORMATION_SCHEMA.COLUMNS c
		where TABLE_NAME = @tableName
	)
	select columnNames.COLUMN_NAME
	from columnNames 
	-- columns are from 1 to N, updated columns is a bitmask, so compensate for zero-indexing
	where power(2, columnNames.column_id - 1) & @updatedColumns > 0
)
go

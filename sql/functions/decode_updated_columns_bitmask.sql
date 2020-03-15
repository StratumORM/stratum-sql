print '
Generating update_columns decoder ring...'


IF OBJECT_ID('[orm_meta].[decode_updated_columns_bitmask]', 'FN') IS NOT NULL
	drop function [orm_meta].[decode_updated_columns_bitmask]
go

create function [orm_meta].[decode_updated_columns_bitmask]
(
	@updated_columns varbinary(255)
,	@table_name varchar(100)
)
returns table
AS
return
(
	with column_names as
	(
		select 	COLUMN_NAME
			,	COLUMNPROPERTY(OBJECT_ID(@table_name), COLUMN_NAME, 'ColumnId') AS COLUMN_ID
		from INFORMATION_SCHEMA.COLUMNS c
		where TABLE_NAME = @table_name
	)
	select column_names.COLUMN_NAME
	from column_names 
	-- columns are from 1 to N, updated columns is a bitmask, so compensate for zero-indexing
	where power(2, column_names.column_id - 1) & @updated_columns > 0
)
go

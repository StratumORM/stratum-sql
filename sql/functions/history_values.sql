print '
Generating history value functions...'



if object_id('[orm].[history_values_string]', 'IF') is not null
	drop function [orm].[history_values_string]
go



create function [orm].[history_values_string]
(
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
)
returns table
as
return
(
	select v.value, v.last_timestamp as dt
	from [orm_hist].[values_string] as v
	where v.property_guid = @property_guid
		and v.instance_guid = @instance_guid

	union all

	select v.value, getdate() as dt
	from [orm_meta].[values_string] as v
	where v.property_guid = @property_guid
		and v.instance_guid = @instance_guid
)



if object_id('[orm].[history_values_integer]', 'IF') is not null
	drop function [orm].[history_values_integer]
go



create function [orm].[history_values_integer]
(
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
)
returns table
as
return
(
	select v.value, v.last_timestamp as dt
	from [orm_hist].[values_integer] as v
	where v.property_guid = @property_guid
		and v.instance_guid = @instance_guid

	union all

	select v.value, getdate() as dt
	from [orm_meta].[values_integer] as v
	where v.property_guid = @property_guid
		and v.instance_guid = @instance_guid
)



if object_id('[orm].[history_values_decimal]', 'IF') is not null
	drop function [orm].[history_values_decimal]
go



create function [orm].[history_values_decimal]
(
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
)
returns table
as
return
(
	select v.value, v.last_timestamp as dt
	from [orm_hist].[values_decimal] as v
	where v.property_guid = @property_guid
		and v.instance_guid = @instance_guid

	union all

	select v.value, getdate() as dt
	from [orm_meta].[values_decimal] as v
	where v.property_guid = @property_guid
		and v.instance_guid = @instance_guid
)



if object_id('[orm].[history_values_datetime]', 'IF') is not null
	drop function [orm].[history_values_datetime]
go



create function [orm].[history_values_datetime]
(
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
)
returns table
as
return
(
	select v.value, v.last_timestamp as dt
	from [orm_hist].[values_datetime] as v
	where v.property_guid = @property_guid
		and v.instance_guid = @instance_guid

	union all

	select v.value, getdate() as dt
	from [orm_meta].[values_datetime] as v
	where v.property_guid = @property_guid
		and v.instance_guid = @instance_guid
)



if object_id('[orm].[history_values_instance]', 'IF') is not null
	drop function [orm].[history_values_instance]
go



create function [orm].[history_values_instance]
(
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
)
returns table
as
return
(
	select v.value, v.last_timestamp as dt
	from [orm_hist].[values_instance] as v
	where v.property_guid = @property_guid
		and v.instance_guid = @instance_guid

	union all

	select v.value, getdate() as dt
	from [orm_meta].[values_instance] as v
	where v.property_guid = @property_guid
		and v.instance_guid = @instance_guid
)

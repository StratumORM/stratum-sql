print '
Generating history spanning functions...'

/*
	A special note about the span functions: there is no clamping!

	This matters if the spans will be used to bucket or group ranges.

	The spans are returned in [beginning, ending) format, where the
	  ending is offset back by the datetimeoffset(7) epsilon of 100 nanoseconds.

	If you want clamping, this works:

	--	,	case when rh.beginning < @begining
	--			then @begining
	--			else rh.beginning
	--		end as beginning

	--	,	case when rh.ending > @ending
	--			then @ending
	--			else rh.ending
	--		end as ending


*/

if object_id('[orm_meta].[history_spans_string]', 'IF') is not null
	drop function [orm_meta].[history_spans_string]
go


create function [orm_meta].[history_spans_string]
(
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
,	@beginning datetimeoffset(7)
,	@ending datetimeoffset(7)
)
returns table
as
return
(
	with raw_history as
	(
		select	hvi.value
			,	lag(hvi.dt)
				over (order by hvi.dt) as beginning
			,	hvi.dt as ending
		from [orm_meta].[history_values_string](@instance_guid, @property_guid) as hvi
	)
	select	rh.value 
		,	rh.beginning
		,	dateadd(mcs, -1, rh.ending) as ending
	from raw_history as rh
	where	rh.ending > @beginning
		and rh.beginning < @ending
)
go



if object_id('[orm].[history_spans_string]', 'IF') is not null
	drop function [orm].[history_spans_string]
go


create function [orm].[history_spans_string]
(
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@beginning datetimeoffset(7)
,	@ending datetimeoffset(7)
)
returns table
as
return
(
	select 	hs.value
		,	hs.beginning
		,	hs.ending
	from [orm_meta].[history_spans_string](
			[orm].[resolve_instance_guid](@template_name, @instance_name)
		,	[orm].[resolve_property_guid](@template_name, @property_name)
		,	@beginning
		,	@ending
		) as hs
)
go



if object_id('[orm_meta].[history_spans_integer]', 'IF') is not null
	drop function [orm_meta].[history_spans_integer]
go


create function [orm_meta].[history_spans_integer]
(
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
,	@beginning datetimeoffset(7)
,	@ending datetimeoffset(7)
)
returns table
as
return
(
	with raw_history as
	(
		select	hvi.value
			,	lag(hvi.dt)
				over (order by hvi.dt) as beginning
			,	hvi.dt as ending
		from [orm_meta].[history_values_integer](@instance_guid, @property_guid) as hvi
	)
	select	rh.value 
		,	rh.beginning
		,	dateadd(mcs, -1, rh.ending) as ending
	from raw_history as rh
	where	rh.ending > @beginning
		and rh.beginning < @ending
)
go



if object_id('[orm].[history_spans_integer]', 'IF') is not null
	drop function [orm].[history_spans_integer]
go


create function [orm].[history_spans_integer]
(
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@beginning datetimeoffset(7)
,	@ending datetimeoffset(7)
)
returns table
as
return
(
	select 	hs.value
		,	hs.beginning
		,	hs.ending
	from [orm_meta].[history_spans_integer](
			[orm].[resolve_instance_guid](@template_name, @instance_name)
		,	[orm].[resolve_property_guid](@template_name, @property_name)
		,	@beginning
		,	@ending
		) as hs
)
go



if object_id('[orm_meta].[history_spans_decimal]', 'IF') is not null
	drop function [orm_meta].[history_spans_decimal]
go


create function [orm_meta].[history_spans_decimal]
(
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
,	@beginning datetimeoffset(7)
,	@ending datetimeoffset(7)
)
returns table
as
return
(
	with raw_history as
	(
		select	hvi.value
			,	lag(hvi.dt)
				over (order by hvi.dt) as beginning
			,	hvi.dt as ending
		from [orm_meta].[history_values_decimal](@instance_guid, @property_guid) as hvi
	)
	select	rh.value 
		,	rh.beginning
		,	dateadd(mcs, -1, rh.ending) as ending
	from raw_history as rh
	where	rh.ending > @beginning
		and rh.beginning < @ending
)
go



if object_id('[orm].[history_spans_decimal]', 'IF') is not null
	drop function [orm].[history_spans_decimal]
go


create function [orm].[history_spans_decimal]
(
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@beginning datetimeoffset(7)
,	@ending datetimeoffset(7)
)
returns table
as
return
(
	select 	hs.value
		,	hs.beginning
		,	hs.ending
	from [orm_meta].[history_spans_decimal](
			[orm].[resolve_instance_guid](@template_name, @instance_name)
		,	[orm].[resolve_property_guid](@template_name, @property_name)
		,	@beginning
		,	@ending
		) as hs
)
go



if object_id('[orm_meta].[history_spans_datetime]', 'IF') is not null
	drop function [orm_meta].[history_spans_datetime]
go


create function [orm_meta].[history_spans_datetime]
(
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
,	@beginning datetimeoffset(7)
,	@ending datetimeoffset(7)
)
returns table
as
return
(
	with raw_history as
	(
		select	hvi.value
			,	lag(hvi.dt)
				over (order by hvi.dt) as beginning
			,	hvi.dt as ending
		from [orm_meta].[history_values_datetime](@instance_guid, @property_guid) as hvi
	)
	select	rh.value 
		,	rh.beginning
		,	dateadd(mcs, -1, rh.ending) as ending
	from raw_history as rh
	where	rh.ending > @beginning
		and rh.beginning < @ending
)
go



if object_id('[orm].[history_spans_datetime]', 'IF') is not null
	drop function [orm].[history_spans_datetime]
go


create function [orm].[history_spans_datetime]
(
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@beginning datetimeoffset(7)
,	@ending datetimeoffset(7)
)
returns table
as
return
(
	select 	hs.value
		,	hs.beginning
		,	hs.ending
	from [orm_meta].[history_spans_datetime](
			[orm].[resolve_instance_guid](@template_name, @instance_name)
		,	[orm].[resolve_property_guid](@template_name, @property_name)
		,	@beginning
		,	@ending
		) as hs
)
go



if object_id('[orm_meta].[history_spans_instance]', 'IF') is not null
	drop function [orm_meta].[history_spans_instance]
go


create function [orm_meta].[history_spans_instance]
(
	@instance_guid uniqueidentifier
,	@property_guid uniqueidentifier
,	@beginning datetimeoffset(7)
,	@ending datetimeoffset(7)
)
returns table
as
return
(
	with raw_history as
	(
		select	hvi.value
			,	lag(hvi.dt)
				over (order by hvi.dt) as beginning
			,	hvi.dt as ending
		from [orm_meta].[history_values_instance](@instance_guid, @property_guid) as hvi
	)
	select	rh.value 
		,	rh.beginning
		,	dateadd(mcs, -1, rh.ending) as ending
	from raw_history as rh
	where	rh.ending > @beginning
		and rh.beginning < @ending
)
go



if object_id('[orm].[history_spans_instance]', 'IF') is not null
	drop function [orm].[history_spans_instance]
go


create function [orm].[history_spans_instance]
(
	@template_name varchar(250)
,	@instance_name varchar(250)
,	@property_name varchar(250)
,	@beginning datetimeoffset(7)
,	@ending datetimeoffset(7)
)
returns table
as
return
(
	select 	hs.value
		,	hs.beginning
		,	hs.ending
	from [orm_meta].[history_spans_instance](
			[orm].[resolve_instance_guid](@template_name, @instance_name)
		,	[orm].[resolve_property_guid](@template_name, @property_name)
		,	@beginning
		,	@ending
		) as hs
)
go

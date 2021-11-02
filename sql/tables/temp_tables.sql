print '
Generating staging (temp) tables...'

IF OBJECT_ID('[orm_temp].[values_string]', 'U') IS NOT NULL
	drop table [orm_temp].[values_string]
go

create table [orm_temp].[values_string]
(	-- template 1 or 0x00000000000000000000000000000001
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value nvarchar(max)
,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP

,	constraint pk__orm_temp_values_string__instance_property
		  primary key 
		  clustered (entry_timestamp, instance_guid, property_guid)
)
go



IF OBJECT_ID('[orm_temp].[values_integer]', 'U') IS NOT NULL
	drop table [orm_temp].[values_integer]
go

create table [orm_temp].[values_integer]
(	-- template 2 or 0x00000000000000000000000000000002
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value bigint
,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP

,	constraint pk__orm_temp_values_integer__instance_property
		  primary key 
		  clustered (entry_timestamp, instance_guid, property_guid)
)
go



IF OBJECT_ID('[orm_temp].[values_decimal]', 'U') IS NOT NULL
	drop table [orm_temp].[values_decimal]
go

create table [orm_temp].[values_decimal]
(	-- template 3 or 0x00000000000000000000000000000003
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value decimal(19,8)
,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP

,	constraint pk__orm_temp_values_decimal__instance_property
		  primary key 
		  clustered (entry_timestamp, instance_guid, property_guid)
)
go



IF OBJECT_ID('[orm_temp].[values_datetime]', 'U') IS NOT NULL
	drop table [orm_temp].[values_datetime]
go

create table [orm_temp].[values_datetime]
(	-- template 4 or 0x00000000000000000000000000000004
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value datetimeoffset(7)
,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP

,	constraint pk__orm_temp_values_datetime__instance_property
		  primary key 
		  clustered (entry_timestamp, instance_guid, property_guid)
)
go



IF OBJECT_ID('[orm_temp].[values_instance]', 'U') IS NOT NULL
	drop table [orm_temp].[values_instance]
go

create table [orm_temp].[values_instance]
(	-- template_guid >= 0x00000000000000000000000000000005
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value  uniqueidentifier
,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP

,	constraint pk__orm_temp_values_instance__instance_property
		  primary key 
		  clustered (entry_timestamp, instance_guid, property_guid)
)
go




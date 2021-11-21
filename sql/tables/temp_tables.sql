print '
Generating staging (temp) tables...'

-- BASE TABLES

IF OBJECT_ID('[orm_temp].[templates]', 'U') IS NOT NULL
	drop table [orm_temp].[templates]
go

create table [orm_temp].[templates]
(
	template_id int null
,	template_guid uniqueidentifier null -- null set by sproc on MERGE

,	name nvarchar(250) not null
,	no_auto_view int -- signal not to make the views for this template by default (to cut down on clutter)
,	signature nvarchar(max)

,	entry_timestamp datetimeoffset(7) not null default CURRENT_TIMESTAMP
,	transaction_order bigint null

-- Only PK on template name: we may want to have the DB merge in on already set IDs
--   or we may want to set our own
,	constraint pk__orm_temp_templates__name
		  primary key 
		  clustered (entry_timestamp, name)
)



IF OBJECT_ID('[orm_temp].[inheritance]', 'U') IS NOT NULL
	drop table [orm_temp].[inheritance]
go

create table [orm_temp].[inheritance]
(
	parent_template_guid uniqueidentifier not null
,	child_template_guid uniqueidentifier not null
,	ordinal int not null

,	entry_timestamp datetimeoffset(7) not null default CURRENT_TIMESTAMP
,	transaction_order bigint null

-- Only PK on everything (there's not really any other surrogate)
-- Note that the [templates] table MUST always merged first.
,	constraint pk__orm_temp_inheritance__all
		  primary key 
		  clustered (entry_timestamp, parent_template_guid, child_template_guid, ordinal)
)




IF OBJECT_ID('[orm_temp].[properties]', 'U') IS NOT NULL
	drop table [orm_temp].[properties]
go

create table [orm_temp].[properties]
(
	property_id int null 
,	property_guid uniqueidentifier null -- null set by sproc on MERGE

,	template_guid uniqueidentifier not null
,	name nvarchar(250) not null
,	datatype_guid uniqueidentifier not null
,	is_extended int -- 0 and NULL imply it's a base property. Using int for future polymorphism
,	no_history int -- signal that changes to this do _not_ get inserted automatically into the history tables
,	signature nvarchar(max)

,	entry_timestamp datetimeoffset(7) not null default CURRENT_TIMESTAMP
,	transaction_order bigint null

-- Only PK on template and property name: we may want to have the DB merge in already set IDs
--   or we may want to set our own. Moreso, we may need to mask.
-- Note that the [templates] table is always merged first.
,	constraint pk__orm_temp_properties__template_guid_name
		  primary key 
		  clustered (entry_timestamp, template_guid, name)
)


IF OBJECT_ID('[orm_temp].[instances]', 'U') IS NOT NULL
	drop table [orm_temp].[instances]
go

create table [orm_temp].[instances]
(
	instance_id int null 
,	instance_guid uniqueidentifier null

,	template_guid uniqueidentifier not null
,	name nvarchar(250) not null	-- A special property, here so it can be indexed (nvarchar(max) can't be)
,	signature nvarchar(max)

,	entry_timestamp datetimeoffset(7) not null default CURRENT_TIMESTAMP
,	transaction_order bigint null

-- Only PK on template and instance name: we may want to have the DB merge in already set IDs
--   or we may want to set our own. Moreso, we may need to mask.
-- Note that the [templates] table is always merged first.
,	constraint pk__orm_temp_instances__template_guid_name
		  primary key 
		  clustered (entry_timestamp, template_guid, name)
)







-- VALUE TABLES

IF OBJECT_ID('[orm_temp].[values_string]', 'U') IS NOT NULL
	drop table [orm_temp].[values_string]
go

create table [orm_temp].[values_string]
(	-- template 1 or 0x00000000000000000000000000000001
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value nvarchar(max)

,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP
,	transaction_order bigint null

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
,	transaction_order bigint null

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
,	transaction_order bigint null

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
,	transaction_order bigint null

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
,	transaction_order bigint null

,	constraint pk__orm_temp_values_instance__instance_property
		  primary key 
		  clustered (entry_timestamp, instance_guid, property_guid)
)
go









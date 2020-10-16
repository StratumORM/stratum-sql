print '
Generating historical logging tables...'

-- BASE TABLES

IF OBJECT_ID('[orm_hist].[templates]', 'U') IS NOT NULL
	drop table [orm_hist].[templates]
go


create table [orm_hist].[templates]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	template_id int not null
,	template_guid uniqueidentifier not null
,	name nvarchar(250)
,	signature nvarchar(max)
,	transaction_id bigint not null

,	constraint pk__orm_hist_templates__guid 
		  primary key 
		  nonclustered (last_timestamp, template_guid)
)
create unique clustered index cx__orm_hist_templates__id 
		  on [orm_hist].[templates] (last_timestamp, template_id)
create nonclustered index ix__orm_hist_templates__tx_guid
		  on [orm_hist].[templates] (transaction_id, template_guid) 
		  include (name, last_timestamp)
go


IF OBJECT_ID('[orm_hist].[properties]', 'U') IS NOT NULL
	drop table [orm_hist].[properties]
go

create table [orm_hist].[properties]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	property_id int not null
,	property_guid uniqueidentifier not null
,	template_guid uniqueidentifier
,	name nvarchar(250)
,	datatype_guid uniqueidentifier
,	is_extended int
,	signature nvarchar(max)
,	transaction_id bigint not null

,	constraint pk__orm_hist_properties__guid 
		  primary key 
		  nonclustered (last_timestamp, property_guid)
)
create unique clustered index cx__orm_hist_properties__id 
		  on [orm_hist].[properties] (last_timestamp, property_id)
create nonclustered index ix__orm_hist_properties__tx_guid_inc
		  on [orm_hist].[properties] (transaction_id, property_guid)
		  include (name, template_guid, last_timestamp)
go


IF OBJECT_ID('[orm_hist].[instances]', 'U') IS NOT NULL
	drop table [orm_hist].[instances]
go

create table [orm_hist].[instances]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_id int not null
,	instance_guid uniqueidentifier not null
,	template_guid uniqueidentifier
,	name nvarchar(250)
,	signature nvarchar(max)
,	transaction_id bigint not null

,	constraint pk__orm_hist_instances__guid 
		  primary key 
		  nonclustered (last_timestamp, instance_guid)
)
create unique clustered index cx__orm_hist_instances__id 
		  on [orm_hist].[instances] (last_timestamp, instance_id)
create nonclustered index ix__orm_hist_instances__tx_guid_inc
		  on [orm_hist].[instances] (transaction_id, instance_guid)
		  include (name, template_guid, last_timestamp)
go


-- VALUES  

IF OBJECT_ID('[orm_hist].[values_string]', 'U') IS NOT NULL
	drop table [orm_hist].[values_string]
go


create table [orm_hist].[values_string]
(	-- template 1 or 0x00000000000000000000000000000001
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value nvarchar(max)
,	transaction_id bigint not null

,	constraint pk__orm_hist_values_string__instance_property
		  primary key 
		  clustered (last_timestamp, instance_guid, property_guid)
)
create nonclustered index ix__orm_hist_values_string__tx_instance_property_inc
		  on [orm_hist].[values_string] (transaction_id, instance_guid, property_guid)
		  include (value, last_timestamp)
go



IF OBJECT_ID('[orm_hist].[values_integer]', 'U') IS NOT NULL
	drop table [orm_hist].[values_integer]
go

create table [orm_hist].[values_integer]
(	-- template 2 or 0x00000000000000000000000000000002
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value bigint
,	transaction_id bigint not null

,	constraint pk__orm_hist_values_integer__instance_property
		  primary key 
		  clustered (last_timestamp, instance_guid, property_guid)
)
create nonclustered index ix__orm_hist_values_integer__tx_instance_property_inc
		  on [orm_hist].[values_integer] (transaction_id, instance_guid, property_guid)
		  include (value, last_timestamp)
go



IF OBJECT_ID('[orm_hist].[values_decimal]', 'U') IS NOT NULL
	drop table [orm_hist].[values_decimal]
go

create table [orm_hist].[values_decimal]
(	-- template 3 or 0x00000000000000000000000000000003
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value decimal(19,8)
,	transaction_id bigint not null

,	constraint pk__orm_hist_values_decimal__instance_property
		  primary key 
		  clustered (last_timestamp, instance_guid, property_guid)
)
create nonclustered index ix__orm_hist_values_decimal__tx_instance_property_inc
		  on [orm_hist].[values_decimal] (transaction_id, instance_guid, property_guid)
		  include (value, last_timestamp)
go



IF OBJECT_ID('[orm_hist].[values_datetime]', 'U') IS NOT NULL
	drop table [orm_hist].[values_datetime]
go

create table [orm_hist].[values_datetime]
(	-- template 4 or 0x00000000000000000000000000000004
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value datetime
,	transaction_id bigint not null

,	constraint pk__orm_hist_values_datetime__instance_property
		  primary key 
		  clustered (last_timestamp, instance_guid, property_guid)
)
create nonclustered index ix__orm_hist_values_datetime__tx_instance_property_inc
		  on [orm_hist].[values_datetime] (transaction_id, instance_guid, property_guid)
		  include (value, last_timestamp)
go



IF OBJECT_ID('[orm_hist].[values_instance]', 'U') IS NOT NULL
	drop table [orm_hist].[values_instance]
go

create table [orm_hist].[values_instance]
(	-- template_guid >= 0x00000000000000000000000000000005
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value  uniqueidentifier
,	transaction_id bigint not null

,	constraint pk__orm_hist_values_instance__instance_property
		  primary key 
		  clustered (last_timestamp, instance_guid, property_guid)
)
create nonclustered index ix__orm_hist_values_instance__tx_instance_property_inc
		  on [orm_hist].[values_instance] (transaction_id, instance_guid, property_guid)
		  include (value, last_timestamp)
go



-- INHERITANCE

IF OBJECT_ID('[orm_hist].[inheritance]', 'U') IS NOT NULL
	drop table [orm_hist].[inheritance]
go

create table [orm_hist].[inheritance]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	parent_template_guid uniqueidentifier not null
,	child_template_guid uniqueidentifier not null
,	ordinal int
,	transaction_id bigint not null

,	constraint pk__orm_hist_inheritance__parent_child_ordinal
		  primary key 
		  clustered (last_timestamp, parent_template_guid, child_template_guid)
)
create nonclustered index ix__orm_hist_inheritance__parent_child_inc
		  on [orm_hist].[inheritance] (parent_template_guid, child_template_guid) 
		  include (ordinal, last_timestamp)
create nonclustered index ix__orm_hist_inheritance__tx_instance_property_inc
		  on [orm_hist].[inheritance] (transaction_id, parent_template_guid, child_template_guid)
		  include (ordinal, last_timestamp)
go


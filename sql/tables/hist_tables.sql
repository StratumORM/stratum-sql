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
,	name varchar(250) not null
,	signature nvarchar(max)
,	transaction_id bigint not null

,	constraint pk_orm_hist_templates_id primary key (last_timestamp, template_id)
)

create index ix_orm_hist_templates_name_id 
		  on [orm_hist].[templates] (name, template_id, last_timestamp)
--		  include (signature)
go


IF OBJECT_ID('[orm_hist].[properties]', 'U') IS NOT NULL
	drop table [orm_hist].[properties]
go

create table [orm_hist].[properties]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	property_id int not null
,	template_id int not null
,	name varchar(250) not null
,	datatype_id int not null
,	is_extended int
,	signature nvarchar(max)
,	transaction_id bigint not null

,	constraint pk_orm_hist_properties_id primary key (last_timestamp, property_id)
)

create index ix_orm_hist_properties_name_id 
		  on [orm_hist].[properties] (name, property_id, last_timestamp)
--		  include (signature)
create index ix_orm_hist_properties_template_id_name 
		  on [orm_hist].[properties] (template_id, name, last_timestamp)
--		  include (signature)
go


IF OBJECT_ID('[orm_hist].[instances]', 'U') IS NOT NULL
	drop table [orm_hist].[instances]
go

create table [orm_hist].[instances]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_id int not null
,	template_id int not null
,	name varchar(250) not null
,	signature nvarchar(max)
,	transaction_id bigint not null

,	constraint pk_orm_hist_instances_id primary key (last_timestamp, instance_id)
)

create index ix_orm_hist_instances_name_template_id 
		  on [orm_hist].[instances] (name, template_id, instance_id, last_timestamp)
--		  include (signature)
go


-- VALUES  

IF OBJECT_ID('[orm_hist].[values_string]', 'U') IS NOT NULL
	drop table [orm_hist].[values_string]
go


create table [orm_hist].[values_string]
(	-- template_id = 1
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_id int not null
,	property_id int not null
,	value nvarchar(max)
,	transaction_id bigint not null

,	constraint pk_orm_hist_values_string_instance_property 
   primary key (last_timestamp, instance_id, property_id)
)
go


IF OBJECT_ID('[orm_hist].[values_integer]', 'U') IS NOT NULL
	drop table [orm_hist].[values_integer]
go

create table [orm_hist].[values_integer]
(	-- template_id = 2
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_id int not null
,	property_id int not null
,	value bigint
,	transaction_id bigint not null

,	constraint pk_orm_hist_values_integer_instance_property 
   primary key (last_timestamp, instance_id, property_id)
)
go


IF OBJECT_ID('[orm_hist].[values_decimal]', 'U') IS NOT NULL
	drop table [orm_hist].[values_decimal]
go

create table [orm_hist].[values_decimal]
(	-- template_id = 3
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_id int not null
,	property_id int not null
,	value decimal(19,8)
,	transaction_id bigint not null

,	constraint pk_orm_hist_values_decimal_instance_property 
   primary key (last_timestamp, instance_id, property_id)
)
go


IF OBJECT_ID('[orm_hist].[values_datetime]', 'U') IS NOT NULL
	drop table [orm_hist].[values_datetime]
go

create table [orm_hist].[values_datetime]
(	-- template_id = 4
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_id int not null
,	property_id int not null
,	value datetime
,	transaction_id bigint not null

,	constraint pk_orm_hist_values_datetime_instance_property 
   primary key (last_timestamp, instance_id, property_id)
)
go


IF OBJECT_ID('[orm_hist].[values_instance]', 'U') IS NOT NULL
	drop table [orm_hist].[values_instance]
go

create table [orm_hist].[values_instance]
(	-- template_id >= 5
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instance_id int not null
,	property_id int not null
,	value varchar(250)
,	transaction_id bigint not null

,	constraint pk_orm_hist_values_instances_instance_property_instance_name 
   primary key (last_timestamp, instance_id, property_id)
)
go


-- INHERITANCE

IF OBJECT_ID('[orm_hist].[inheritance]', 'U') IS NOT NULL
	drop table [orm_hist].[inheritance]
go

create table [orm_hist].[inheritance]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	parent_template_id int not null
,	child_template_id int not null
,	ordinal int not null
,	transaction_id bigint not null

,	constraint pk_orm_hist_inheritance_parent_child_ordinal 
   primary key (last_timestamp, parent_template_id, child_template_id)

)
create index ix_orm_hist_inheritance_parent_child_ordinal 
		  on [orm_hist].[inheritance] (parent_template_id, child_template_id, last_timestamp) include (ordinal)
go

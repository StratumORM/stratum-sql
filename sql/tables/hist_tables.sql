print '
Generating historical logging tables...'

-- BASE TABLES

IF OBJECT_ID('[orm_hist].[templates]', 'U') IS NOT NULL
	drop table [orm_hist].[templates]
go


create table [orm_hist].[templates]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	templateID int not null
,	name varchar(250) not null
,	signature nvarchar(max)

,	constraint pk_orm_hist_templates_id primary key (last_timestamp, templateID)
)

create index ix_orm_hist_templates_name_id 
		  on [orm_hist].[templates] (name, templateID, last_timestamp)
--		  include (signature)
go


IF OBJECT_ID('[orm_hist].[properties]', 'U') IS NOT NULL
	drop table [orm_hist].[properties]
go

create table [orm_hist].[properties]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	propertyID int not null
,	templateID int not null
,	name varchar(250) not null
,	datatypeID int not null
,	isExtended int
,	signature nvarchar(max)

,	constraint pk_orm_hist_properties_id primary key (last_timestamp, propertyID)
)

create index ix_orm_hist_properties_name_id 
		  on [orm_hist].[properties] (name, propertyID, last_timestamp)
--		  include (signature)
create index ix_orm_hist_properties_templateID_name 
		  on [orm_hist].[properties] (templateID, name, last_timestamp)
--		  include (signature)
go


IF OBJECT_ID('[orm_hist].[instances]', 'U') IS NOT NULL
	drop table [orm_hist].[instances]
go

create table [orm_hist].[instances]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instanceID int not null
,	templateID int not null
,	name varchar(250) not null
,	signature nvarchar(max)

,	constraint pk_orm_hist_instances_id primary key (last_timestamp, instanceID)
)

create index ix_orm_hist_instances_name_templateID 
		  on [orm_hist].[instances] (name, templateID, instanceID, last_timestamp)
--		  include (signature)
go


-- VALUES  

IF OBJECT_ID('[orm_hist].[values_string]', 'U') IS NOT NULL
	drop table [orm_hist].[values_string]
go


create table [orm_hist].[values_string]
(	-- templateID = 1
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instanceID int not null
,	propertyID int not null
,	value nvarchar(max)

,	constraint pk_orm_hist_values_string_instance_property 
   primary key (last_timestamp, instanceID, propertyID)
)
go


IF OBJECT_ID('[orm_hist].[values_integer]', 'U') IS NOT NULL
	drop table [orm_hist].[values_integer]
go

create table [orm_hist].[values_integer]
(	-- templateID = 2
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instanceID int not null
,	propertyID int not null
,	value bigint

,	constraint pk_orm_hist_values_integer_instance_property 
   primary key (last_timestamp, instanceID, propertyID)
)
go


IF OBJECT_ID('[orm_hist].[values_decimal]', 'U') IS NOT NULL
	drop table [orm_hist].[values_decimal]
go

create table [orm_hist].[values_decimal]
(	-- templateID = 3
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instanceID int not null
,	propertyID int not null
,	value decimal(19,8)

,	constraint pk_orm_hist_values_decimal_instance_property 
   primary key (last_timestamp, instanceID, propertyID)
)
go


IF OBJECT_ID('[orm_hist].[values_datetime]', 'U') IS NOT NULL
	drop table [orm_hist].[values_datetime]
go

create table [orm_hist].[values_datetime]
(	-- templateID = 4
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instanceID int not null
,	propertyID int not null
,	value datetime

,	constraint pk_orm_hist_values_datetime_instance_property 
   primary key (last_timestamp, instanceID, propertyID)
)
go


IF OBJECT_ID('[orm_hist].[values_instance]', 'U') IS NOT NULL
	drop table [orm_hist].[values_instance]
go

create table [orm_hist].[values_instance]
(	-- templateID >= 5
	last_timestamp datetime default CURRENT_TIMESTAMP
,	instanceID int not null
,	propertyID int not null
,	value varchar(250)

,	constraint pk_orm_hist_values_instances_instance_property_instanceName 
   primary key (last_timestamp, instanceID, propertyID)
)
go


-- INHERITANCE

IF OBJECT_ID('[orm_hist].[inheritance]', 'U') IS NOT NULL
	drop table [orm_hist].[inheritance]
go

create table [orm_hist].[inheritance]
(
	last_timestamp datetime default CURRENT_TIMESTAMP
,	parentTemplateID int not null
,	childTemplateID int not null
,	ordinal int not null

,	constraint pk_orm_hist_inheritance_parent_child_ordinal 
   primary key (last_timestamp, parentTemplateID, childTemplateID)

)
create index ix_orm_hist_inheritance_parent_child_ordinal 
		  on [orm_hist].[inheritance] (parentTemplateID, childTemplateID, last_timestamp) include (ordinal)
go

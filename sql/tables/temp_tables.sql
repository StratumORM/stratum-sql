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

,	name nvarchar(250) null -- IFF guid is not null AND name is null, that signals a delete

,	no_auto_view int -- signal not to make the views for this template by default (to cut down on clutter)
,	signature nvarchar(max)

,	entry_timestamp datetimeoffset(7) not null default CURRENT_TIMESTAMP
,	transaction_order bigint null

-- IFF guid is not null AND name is null, that signals a delete
,	constraint ck__orm_temp_templates__guid_or_name
          check (   template_guid is not null
          		 or          name is not null)
)



IF OBJECT_ID('[orm_temp].[inheritance]', 'U') IS NOT NULL
	drop table [orm_temp].[inheritance]
go

create table [orm_temp].[inheritance]
(
	-- user friendly
	parent_template_name nvarchar(250) null
,	child_template_name nvarchar(250) null

,	ordinal int not null

	-- database fast
,	parent_template_guid uniqueidentifier null
,	child_template_guid uniqueidentifier null

,	entry_timestamp datetimeoffset(7) not null default CURRENT_TIMESTAMP
,	transaction_order bigint null

-- Ensure AT LEAST the guid or name is provided
,	constraint ck__orm_temp_inheritance__parent_guid_or_name
		  check (   parent_template_guid is not null
		  		 or parent_template_name is not null)
,	constraint ck__orm_temp_inheritance__child_guid_or_name
		  check (   child_template_guid is not null
		  		 or child_template_name is not null)
)



IF OBJECT_ID('[orm_temp].[properties]', 'U') IS NOT NULL
	drop table [orm_temp].[properties]
go

create table [orm_temp].[properties]
(
	property_id int null 
,	property_guid uniqueidentifier null -- null set by sproc on MERGE

,	template_name nvarchar(250) null    -- note that we MUST have EITHER
,	template_guid uniqueidentifier null -- a GUID or a name - sproc can resolve

,	name nvarchar(250) null

,	datatype_name nvarchar(250) null
,	datatype_guid uniqueidentifier null

,	is_extended int -- 0 and NULL imply it's a base property. Using int for future polymorphism
,	no_history int -- signal that changes to this do _not_ get inserted automatically into the history tables
,	signature nvarchar(max)

,	entry_timestamp datetimeoffset(7) not null default CURRENT_TIMESTAMP
,	transaction_order bigint null

-- Ensure AT LEAST the guid or name is provided
,	constraint ck__orm_temp_properties__template_guid_or_name
		  check (   template_guid is not null 
		  		 or template_name is not null)
,	constraint ck__orm_temp_properties__datatype_guid_or_name
		  check (   datatype_guid is not null
		  		 or datatype_name is not null)
		  
-- IFF guid is not null AND name is null, that signals a delete
,	constraint ck__orm_temp_properties__guid_or_name
          check (isnull(property_guid, name) is not null)
)


IF OBJECT_ID('[orm_temp].[instances]', 'U') IS NOT NULL
	drop table [orm_temp].[instances]
go

create table [orm_temp].[instances]
(
	instance_id int null 
,	instance_guid uniqueidentifier null

,	template_name nvarchar(250) null
,	template_guid uniqueidentifier null

,	name nvarchar(250) not null	-- A special property, here so it can be indexed (nvarchar(max) can't be)
,	signature nvarchar(max)

,	entry_timestamp datetimeoffset(7) not null default CURRENT_TIMESTAMP
,	transaction_order bigint null

-- Ensure AT LEAST the guid or name is provided
,	constraint ck__orm_temp_instances__template_guid_or_name
		  check (   template_guid is not null 
		  		 or template_name is not null)

-- IFF guid is not null AND name is null, that signals a delete
--   but AT LEAST one must be defined
,	constraint ck__orm_temp_instances__guid_or_name
          check (   instance_guid is not null
        		 or          name is not null)

)



-- VALUE TABLES


-- User friendly variant
IF OBJECT_ID('[orm_temp].[values]', 'U') IS NOT NULL
	drop table [orm_temp].[values]
go

create table [orm_temp].[values]
(
	template_name nvarchar(250) null
,	instance_name nvarchar(250) null
,	property_name nvarchar(250) null

,	value nvarchar(max) null

,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null

,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP
,	transaction_order bigint null

,	constraint ck__orm_temp_values__guid_or_name
		  check ( (instance_guid is not null 
		  	       or (    template_name is not null 
		  	           and instance_name is not null)
		  	      ) and (   property_guid is not null 
		  		 	     or property_name is not null)
		  		)
)
go



IF OBJECT_ID('[orm_temp].[values_string]', 'U') IS NOT NULL
	drop table [orm_temp].[values_string]
go

create table [orm_temp].[values_string]
(	-- template 1 or 0x00000000000000000000000000000001
	template_name nvarchar(250) null
,	instance_name nvarchar(250) null
,	property_name nvarchar(250) null

,	value nvarchar(max) null

,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null

,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP
,	transaction_order bigint null

,	constraint ck__orm_temp_values_string__guid_or_name
		  check ( (instance_guid is not null 
		  	       or (    template_name is not null 
		  	           and instance_name is not null)
		  	      ) and (   property_guid is not null 
		  		 	     or property_name is not null)
		  		)
)
go



IF OBJECT_ID('[orm_temp].[values_integer]', 'U') IS NOT NULL
	drop table [orm_temp].[values_integer]
go

create table [orm_temp].[values_integer]
(	-- template 2 or 0x00000000000000000000000000000002
	template_name nvarchar(250) null
,	instance_name nvarchar(250) null
,	property_name nvarchar(250) null

,	value bigint null

,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null

,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP
,	transaction_order bigint null

,	constraint ck__orm_temp_values_integer__guid_or_name
		  check ( (instance_guid is not null 
		  	       or (    template_name is not null 
		  	           and instance_name is not null)
		  	      ) and (   property_guid is not null 
		  		 	     or property_name is not null)
		  		)
)
go



IF OBJECT_ID('[orm_temp].[values_decimal]', 'U') IS NOT NULL
	drop table [orm_temp].[values_decimal]
go

create table [orm_temp].[values_decimal]
(	-- template 3 or 0x00000000000000000000000000000003
	template_name nvarchar(250) null
,	instance_name nvarchar(250) null
,	property_name nvarchar(250) null

,	value decimal(19,8) null

,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null

,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP
,	transaction_order bigint null

,	constraint ck__orm_temp_values_decimal__guid_or_name
		  check ( (instance_guid is not null 
		  	       or (    template_name is not null 
		  	           and instance_name is not null)
		  	      ) and (   property_guid is not null 
		  		 	     or property_name is not null)
		  		)
)
go



IF OBJECT_ID('[orm_temp].[values_datetime]', 'U') IS NOT NULL
	drop table [orm_temp].[values_datetime]
go

create table [orm_temp].[values_datetime]
(	-- template 4 or 0x00000000000000000000000000000004
	template_name nvarchar(250) null
,	instance_name nvarchar(250) null
,	property_name nvarchar(250) null

,	value datetimeoffset(7) null

,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null

,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP
,	transaction_order bigint null

,	constraint ck__orm_temp_values_datetime__guid_or_name
		  check ( (instance_guid is not null 
		  	       or (    template_name is not null 
		  	           and instance_name is not null)
		  	      ) and (   property_guid is not null 
		  		 	     or property_name is not null)
		  		)
)
go



IF OBJECT_ID('[orm_temp].[values_instance]', 'U') IS NOT NULL
	drop table [orm_temp].[values_instance]
go

create table [orm_temp].[values_instance]
(	-- template_guid >= 0x00000000000000000000000000000005
	template_name nvarchar(250) null
,	instance_name nvarchar(250) null
,	property_name nvarchar(250) null

,	value uniqueidentifier null

,	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null

,	entry_timestamp datetimeoffset(7) default CURRENT_TIMESTAMP
,	transaction_order bigint null

,	constraint ck__orm_temp_values_instance__guid_or_name
		  check ( (instance_guid is not null 
		  	       or (    template_name is not null 
		  	           and instance_name is not null)
		  	      ) and (   property_guid is not null 
		  		 	     or property_name is not null)
		  		)
)
go









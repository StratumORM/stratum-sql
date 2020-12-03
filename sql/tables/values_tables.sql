print '
Generating value tables...'

/*
--	Note that the GUID columns are clustered.
--  This is generally considered poor practice, but note that there's
--    no expectation of order or sequencing. There's not really
--    any advantage of an integer column here, aside from a very minor
--    size difference. 
--  These tables effectively statically hold the current value for properties.
--  As they change, their changes will be dumped to historical tables,
--    and these _are_ clustered differently.
--*/


IF OBJECT_ID('[orm_meta].[values_string]', 'U') IS NOT NULL
	drop table [orm_meta].[values_string]
go


create table [orm_meta].[values_string]
(	-- template_guid = 0x00000000000000000000000000000001
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value nvarchar(max)

,	constraint pk__orm_meta_values_string__instance_property 
		  primary key 
		  clustered (instance_guid, property_guid)
,	constraint fk__orm_meta_values_string__instance 
		  foreign key (instance_guid) 
		  references [orm_meta].[instances] (instance_guid) 
		  on delete cascade
,	constraint fk__orm_meta_values_string__property 
		  foreign key (property_guid) 
		  references [orm_meta].[properties] (property_guid) 
		  on delete cascade
)
go


IF OBJECT_ID('[orm_meta].[values_integer]', 'U') IS NOT NULL
	drop table [orm_meta].[values_integer]
go

create table [orm_meta].[values_integer]
(	-- template_guid = 0x00000000000000000000000000000002
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value bigint

,	constraint pk__orm_meta_values_integer__instance_property 
		  primary key 
		  clustered (instance_guid, property_guid)
,	constraint fk__orm_meta_values_integer__instance 
		  foreign key (instance_guid) 
		  references [orm_meta].[instances] (instance_guid) 
		  on delete cascade
,	constraint fk__orm_meta_values_integer__property 
		  foreign key (property_guid) 
		  references [orm_meta].[properties] (property_guid) 
		  on delete cascade
)
go


IF OBJECT_ID('[orm_meta].[values_decimal]', 'U') IS NOT NULL
	drop table [orm_meta].[values_decimal]
go

create table [orm_meta].[values_decimal]
(	-- template_guid = 0x00000000000000000000000000000003
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value decimal(19,8)

,	constraint pk__orm_meta_values_decimal__instance_property 
		  primary key 
		  clustered (instance_guid, property_guid)
,	constraint fk__orm_meta_values_decimal__instance 
		  foreign key (instance_guid) 
		  references [orm_meta].[instances] (instance_guid) 
		  on delete cascade
,	constraint fk__orm_meta_values_decimal__property 
		  foreign key (property_guid) 
		  references [orm_meta].[properties] (property_guid) 
		  on delete cascade
)
go


IF OBJECT_ID('[orm_meta].[values_datetime]', 'U') IS NOT NULL
	drop table [orm_meta].[values_datetime]
go

create table [orm_meta].[values_datetime]
(	-- template_guid = 0x00000000000000000000000000000004
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value datetimeoffset(7)

,	constraint pk__orm_meta_values_datetime__instance_property 
		  primary key 
		  clustered (instance_guid, property_guid)
,	constraint fk__orm_meta_values_datetime__instance 
		  foreign key (instance_guid) 
		  references [orm_meta].[instances] (instance_guid) 
		  on delete cascade
,	constraint fk__orm_meta_values_datetime__property 
		  foreign key (property_guid) 
		  references [orm_meta].[properties] (property_guid) 
		  on delete cascade
)
go


IF OBJECT_ID('[orm_meta].[values_instance]', 'U') IS NOT NULL
	drop table [orm_meta].[values_instance]
go

create table [orm_meta].[values_instance]
(	-- template_guid > 0x00000000000000000000000000000004
	instance_guid uniqueidentifier not null
,	property_guid uniqueidentifier not null
,	value uniqueidentifier

,	constraint pk__orm_meta_values_instances__instance_property_instance_name
		  primary key 
		  clustered (instance_guid, property_guid)
,	constraint fk__orm_meta_values_instances__instance 
		  foreign key (instance_guid) 
		  references [orm_meta].[instances] (instance_guid) 
		  on delete cascade
,	constraint fk__orm_meta_values_instances__property 
		  foreign key (property_guid) 
		  references [orm_meta].[properties] (property_guid) 
		  on delete cascade
)
go

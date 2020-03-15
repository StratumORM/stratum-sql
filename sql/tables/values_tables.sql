print '
Generating value tables...'

IF OBJECT_ID('[orm_meta].[values_string]', 'U') IS NOT NULL
	drop table [orm_meta].[values_string]
go


create table [orm_meta].[values_string]
(	-- template_id = 1
	instance_id int not null
,	property_id int not null
,	value nvarchar(max)

,	constraint pk_orm_meta_values_string_instance_property primary key (instance_id, property_id)
,	constraint fk_orm_meta_values_string_instance foreign key (instance_id) references [orm_meta].[instances] (instance_id) on delete cascade
,	constraint fk_orm_meta_values_string_property foreign key (property_id) references [orm_meta].[properties] (property_id) on delete cascade
)
go


IF OBJECT_ID('[orm_meta].[values_integer]', 'U') IS NOT NULL
	drop table [orm_meta].[values_integer]
go

create table [orm_meta].[values_integer]
(	-- template_id = 2
	instance_id int not null
,	property_id int not null
,	value bigint

,	constraint pk_orm_meta_values_integer_instance_property primary key (instance_id, property_id)
,	constraint fk_orm_meta_values_integer_instance foreign key (instance_id) references [orm_meta].[instances] (instance_id) on delete cascade
,	constraint fk_orm_meta_values_integer_property foreign key (property_id) references [orm_meta].[properties] (property_id) on delete cascade
)
go


IF OBJECT_ID('[orm_meta].[values_decimal]', 'U') IS NOT NULL
	drop table [orm_meta].[values_decimal]
go

create table [orm_meta].[values_decimal]
(	-- template_id = 3
	instance_id int not null
,	property_id int not null
,	value decimal(19,8)

,	constraint pk_orm_meta_values_decimal_instance_property primary key (instance_id, property_id)
,	constraint fk_orm_meta_values_decimal_instance foreign key (instance_id) references [orm_meta].[instances] (instance_id) on delete cascade
,	constraint fk_orm_meta_values_decimal_property foreign key (property_id) references [orm_meta].[properties] (property_id) on delete cascade
)
go


IF OBJECT_ID('[orm_meta].[values_datetime]', 'U') IS NOT NULL
	drop table [orm_meta].[values_datetime]
go

create table [orm_meta].[values_datetime]
(	-- template_id = 4
	instance_id int not null
,	property_id int not null
,	value datetime

,	constraint pk_orm_meta_values_datetime_instance_property primary key (instance_id, property_id)
,	constraint fk_orm_meta_values_datetime_instance foreign key (instance_id) references [orm_meta].[instances] (instance_id) on delete cascade
,	constraint fk_orm_meta_values_datetime_property foreign key (property_id) references [orm_meta].[properties] (property_id) on delete cascade
)
go


IF OBJECT_ID('[orm_meta].[values_instance]', 'U') IS NOT NULL
	drop table [orm_meta].[values_instance]
go

create table [orm_meta].[values_instance]
(	-- template_id >= 5
	instance_id int not null
,	property_id int not null
,	value varchar(250)

,	constraint pk_orm_meta_values_instances_instance_property_instance_name primary key (instance_id, property_id, value)
,	constraint fk_orm_meta_values_instances_instance foreign key (instance_id) references [orm_meta].[instances] (instance_id) on delete cascade
,	constraint fk_orm_meta_values_instances_property foreign key (property_id) references [orm_meta].[properties] (property_id) on delete cascade
)
create index ix_orm_meta_values_instances_instance_property on [orm_meta].[values_instance] (instance_id, property_id)
go

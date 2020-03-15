print '
Generating base tables...'

IF OBJECT_ID('[orm_meta].[templates]', 'U') IS NOT NULL
	drop table [orm_meta].[templates]
go

create table [orm_meta].[templates]
(
	template_id int identity(1,1) not null constraint pk_orm_meta_templates_id primary key
,	name varchar(250) not null
,	signature nvarchar(max)
,	constraint uq_orm_meta_templates_name unique nonclustered (name) 
)
create index ix_orm_meta_templates_name_id 
          on [orm_meta].[templates] (name, template_id)
go


set identity_insert [orm_meta].[templates] on
  -- We're co-opting the name as the datatype here for convenience
insert [orm_meta].[templates] (template_id, name) 
values	(1, 'nvarchar(max)')
	,	(2, 'bigint')
	,	(3, 'decimal(19,8)')
	,	(4, 'datetime')
set identity_insert [orm_meta].[templates] off


IF OBJECT_ID('[orm_meta].[properties]', 'U') IS NOT NULL
	drop table [orm_meta].[properties]
go

create table [orm_meta].[properties]
(
	property_id int identity(1,1) not null constraint pk_orm_meta_properties_id primary key
,	template_id int not null
,	name varchar(250) not null
,	datatype_id int not null
,	is_extended int -- 0 and NULL imply it's a base property. Using int for future polymorphism
,	signature nvarchar(max)
																							-- can't use cascade here due to the instead of trigger
--,	constraint fk_orm_meta_properties_template foreign key (template_id) references [orm_meta].[templates] (template_id) --on delete cascade 
--,	constraint fk_orm_meta_properties_datatype foreign key (template_id) references [orm_meta].[templates] (template_id)
,	constraint uq_orm_meta_properties_template_id_name unique nonclustered (template_id, name)
)
create index ix_orm_meta_properties_template_id_name 
          on [orm_meta].[properties] (template_id, name)
create index ix_orm_meta_properties_property_id_template_id_datatype_id_name 
          on [orm_meta].[properties] (property_id, template_id, datatype_id, name)
go


IF OBJECT_ID('[orm_meta].[instances]', 'U') IS NOT NULL
	drop table [orm_meta].[instances]
go

create table [orm_meta].[instances]
(
	instance_id int identity(1,1) not null constraint pk_orm_meta_instances_id primary key
,	template_id int not null
,	name varchar(250) not null	-- A special property, here so it can be indexed (nvarchar(max) can't be)
,	signature nvarchar(max)

,	constraint fk_orm_meta_instances_template foreign key (template_id) references [orm_meta].[templates] (template_id) on delete cascade
,	constraint uq_orm_meta_instances_template_id_name unique nonclustered (template_id, name)
)
go

print '
Generating base tables...'

IF OBJECT_ID('[orm_meta].[templates]', 'U') IS NOT NULL
	drop table [orm_meta].[templates]
go

create table [orm_meta].[templates]
(
	templateID int identity(1,1) not null constraint pk_orm_meta_templates_id primary key
,	name varchar(250) not null
,	signature nvarchar(max)
,	constraint uq_orm_meta_templates_name unique nonclustered (name) 
)
create index ix_orm_meta_templates_name_id on [orm_meta].[templates] (name, templateID)
go


set identity_insert [orm_meta].[templates] on
  -- We're co-opting the name as the datatype here for convenience
insert [orm_meta].[templates] (templateID, name) 
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
	propertyID int identity(1,1) not null constraint pk_orm_meta_properties_id primary key
,	templateID int not null
,	name varchar(250) not null
,	datatypeID int not null
,	isExtended int -- 0 and NULL imply it's a base property. Using int for future polymorphism
,	signature nvarchar(max)
																							-- can't use cascade here due to the instead of trigger
--,	constraint fk_orm_meta_properties_template foreign key (templateID) references [orm_meta].[templates] (templateID) --on delete cascade 
--,	constraint fk_orm_meta_properties_datatype foreign key (templateID) references [orm_meta].[templates] (templateID)
,	constraint uq_orm_meta_properties_templateID_name unique nonclustered (templateID, name)
)
create index ix_orm_meta_properties_templateID_name on [orm_meta].[properties] (templateID, name)
go


IF OBJECT_ID('[orm_meta].[instances]', 'U') IS NOT NULL
	drop table [orm_meta].[instances]
go

create table [orm_meta].[instances]
(
	instanceID int identity(1,1) not null constraint pk_orm_meta_instances_id primary key
,	templateID int not null
,	name varchar(250) not null	-- A special property, here so it can be indexed (nvarchar(max) can't be)
,	signature nvarchar(max)

,	constraint fk_orm_meta_instances_template foreign key (templateID) references [orm_meta].[templates] (templateID) on delete cascade
,	constraint uq_orm_meta_instances_templateID_name unique nonclustered (templateID, name)
)
go

print '
Generating base tables...'

IF OBJECT_ID('[orm_meta].[templates]', 'U') IS NOT NULL
	drop table [orm_meta].[templates]
go

create table [orm_meta].[templates]
(
	template_id int identity(1,1) not null
,	template_guid uniqueidentifier not null default (newsequentialid())
,	name nvarchar(250) not null
,	signature nvarchar(max)
,	constraint pk__orm_meta_templates__guid 
		  primary key 
		  nonclustered (template_guid)
,	constraint uq__orm_meta_templates__name 
		  unique nonclustered (name) 
)
create unique clustered index cx__orm_meta_templates__id
		  on [orm_meta].[templates] (template_id)
create index ix__orm_meta_templates__name_guid_id 
          on [orm_meta].[templates] (name, template_guid, template_id)
go


set identity_insert [orm_meta].[templates] on
  -- We're co-opting the name as the datatype here for convenience
insert [orm_meta].[templates] (name, template_id, template_guid) 
values	('string',   1, convert(uniqueidentifier, '00000000-0000-0000-0000-000000000001'))
	,	('integer',  2, convert(uniqueidentifier, '00000000-0000-0000-0000-000000000002'))
	,	('decimal',  3, convert(uniqueidentifier, '00000000-0000-0000-0000-000000000003'))
	,	('datetime', 4, convert(uniqueidentifier, '00000000-0000-0000-0000-000000000004'))
set identity_insert [orm_meta].[templates] off


IF OBJECT_ID('[orm_meta].[properties]', 'U') IS NOT NULL
	drop table [orm_meta].[properties]
go

create table [orm_meta].[properties]
(
	property_id int identity(1,1) not null 
,	property_guid uniqueidentifier not null default (newsequentialid())
,	template_guid uniqueidentifier not null
,	name nvarchar(250) not null
,	datatype_guid uniqueidentifier not null
,	is_extended int -- 0 and NULL imply it's a base property. Using int for future polymorphism
,	signature nvarchar(max)
																							-- can't use cascade here due to the instead of trigger
--,	constraint fk_orm_meta_properties_template foreign key (template_guid) references [orm_meta].[templates] (template_id) --on delete cascade 
--,	constraint fk_orm_meta_properties_datatype foreign key (template_guid) references [orm_meta].[templates] (template_id)
,	constraint pk__orm_meta_properties__guid 
		  primary key 
		  nonclustered (property_guid)
,	constraint uq__orm_meta_properties__template_name 
		  unique nonclustered (template_guid, name)
)
create unique clustered index cx__orm_meta_properties__id
		  on [orm_meta].[properties] (property_id)
create index ix__orm_meta_properties__template_name 
          on [orm_meta].[properties] (template_guid, name)
create index ix__orm_meta_properties__property_template_datatype_name 
          on [orm_meta].[properties] (property_guid, template_guid, datatype_guid, name)
go


IF OBJECT_ID('[orm_meta].[instances]', 'U') IS NOT NULL
	drop table [orm_meta].[instances]
go

create table [orm_meta].[instances]
(
	instance_id int identity(1,1) not null 
,	instance_guid uniqueidentifier not null default (newsequentialid())
,	template_guid uniqueidentifier not null
,	name nvarchar(250) not null	-- A special property, here so it can be indexed (nvarchar(max) can't be)
,	signature nvarchar(max)

,	constraint pk__orm_meta_instances__guid 
		  primary key 
		  nonclustered (instance_guid)
,	constraint fk__orm_meta_instances__template 
		  foreign key (template_guid) 
		  references [orm_meta].[templates] (template_guid) 
		  on delete cascade
,	constraint uq__orm_meta_instances__template_guid_name 
		  unique nonclustered (template_guid, name)
)
create unique clustered index cx__orm_meta_instances__id
		  on [orm_meta].[instances] (instance_id)
go

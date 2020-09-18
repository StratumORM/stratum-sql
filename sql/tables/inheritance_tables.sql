print '
Generating template inheritance definitions...'


IF OBJECT_ID('[orm_meta].[inheritance]', 'U') IS NOT NULL
	drop table [orm_meta].[inheritance]
go

create table [orm_meta].[inheritance]
(
	parent_template_guid uniqueidentifier not null
,	child_template_guid uniqueidentifier not null
,	ordinal int not null
,	constraint pk__orm_meta_inheritance__parent_child_ordinal
		  primary key
		  nonclustered (parent_template_guid, child_template_guid, ordinal)
,	constraint fk__orm_meta_inheritance__parent 
		  foreign key (parent_template_guid) 
		  references [orm_meta].[templates] (template_guid)
,	constraint fk__orm_meta_inheritance__child
		  foreign key (child_template_guid) 
		  references [orm_meta].[templates] (template_guid) 
,	constraint uq__orm_meta_inheritance__parent_child 
		  unique nonclustered (parent_template_guid, child_template_guid) -- only inherit once
,	constraint uq__orm_meta_inheritance__child_ordinal 
		  unique nonclustered (child_template_guid, ordinal) -- can't have two parents at the same level
)
-- possibly overconstrained, but needed to calculate backwards
create nonclustered index ix__orm_meta_inheritance__child_parent 
          on [orm_meta].[inheritance] (child_template_guid, parent_template_guid)
          include (ordinal)
go

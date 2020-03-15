print '
Generating template inheritance definitions...'


IF OBJECT_ID('[orm_meta].[inheritance]', 'U') IS NOT NULL
	drop table [orm_meta].[inheritance]
go

create table [orm_meta].[inheritance]
(
	parent_template_id int not null
,	child_template_id int not null
,	ordinal int not null
,	constraint fk_orm_meta_inheritance_parent_template foreign key (parent_template_id) references [orm_meta].[templates] (template_id)
,	constraint fk_orm_meta_inheritance_child_template foreign key (child_template_id) references [orm_meta].[templates] (template_id) 
,	constraint uq_orm_meta_inheritance_parent_child unique nonclustered (parent_template_id, child_template_id) -- only inherit once
,	constraint uq_orm_meta_inheritance_child_ordinal unique nonclustered (child_template_id, ordinal) -- can't have two parents at the same level
)
create index ix_orm_meta_inheritance_parent_child_ordinal 
          on [orm_meta].[inheritance] (parent_template_id, child_template_id, ordinal)
go

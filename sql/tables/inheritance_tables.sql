print '
Generating template inheritance definitions...'


IF OBJECT_ID('[orm_meta].[inheritance]', 'U') IS NOT NULL
	drop table [orm_meta].[inheritance]
go

create table [orm_meta].[inheritance]
(
	parentTemplateID int not null
,	childTemplateID int not null
,	ordinal int not null
,	constraint fk_orm_meta_inheritance_parent_template foreign key (parentTemplateID) references [orm_meta].[templates] (templateID)
,	constraint fk_orm_meta_inheritance_child_template foreign key (childTemplateID) references [orm_meta].[templates] (templateID) 
,	constraint uq_orm_meta_inheritance_parent_child unique nonclustered (parentTemplateID, childTemplateID) -- only inherit once
,	constraint uq_orm_meta_inheritance_child_ordinal unique nonclustered (childTemplateID, ordinal) -- can't have two parents at the same level
)
create index ix_orm_meta_inheritance_parent_child_ordinal 
          on [orm_meta].[inheritance] (parentTemplateID, childTemplateID, ordinal)
go

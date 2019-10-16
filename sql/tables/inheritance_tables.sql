print '
Generating template inheritance definitions...'


IF OBJECT_ID('[dbo].[orm_meta_inheritance]', 'U') IS NOT NULL
	drop table [dbo].orm_meta_inheritance
go

create table orm_meta_inheritance
(
	parentTemplateID int not null
,	childTemplateID int not null
,	ordinal int not null
,	constraint fk_orm_meta_inheritance_parent_template foreign key (parentTemplateID) references orm_meta_templates (templateID)
,	constraint fk_orm_meta_inheritance_child_template foreign key (childTemplateID) references orm_meta_templates (templateID) 
,	constraint uq_orm_meta_inheritance_parent_child unique nonclustered (parentTemplateID, childTemplateID) -- only inherit once
,	constraint uq_orm_meta_inheritance_child_ordinal unique nonclustered (childTemplateID, ordinal) -- can't have two parents at the same level
)
create index ix_orm_meta_inheritance_parent_child_ordinal on orm_meta_inheritance (parentTemplateID, childTemplateID, ordinal)
go

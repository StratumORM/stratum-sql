print '
Generating instance chaining functions...'



if object_id('[orm_meta].[sub_instance_by_property]', 'IF') is not null
	drop function [orm_meta].[sub_instance_by_property]
go

create function [orm_meta].[sub_instance_by_property]
(	
	@root_object_guid uniqueidentifier
,	@by_property_name varchar(255)
)
RETURNS TABLE 
AS
RETURN 
(
	with related_properties as
	(	-- get all properties that if the same (or sub) 
		-- of the given property's datatype
		select sp.property_guid
		from [orm_meta].[properties] as p
			inner join [orm_meta].[templates] as t
				on p.template_guid = t.template_guid
			inner join [orm_meta].[instances] as i
				on i.template_guid = t.template_guid
			cross apply [orm_meta].[sub_templates](p.datatype_guid) as sdt
			inner join [orm_meta].[properties] as sp
				on sp.datatype_guid = sdt.template_guid
		where i.instance_guid = @root_object_guid
			and p.name = @by_property_name
			and sp.name = @by_property_name
	)
	,	children as
	(
		select @root_object_guid as instance_guid, 0 as echelon

		union all

		--select vi.value as instance_guid, tree.echelon + 1 as echelon
		select vi.instance_guid, tree.echelon - 1 as echelon
		from [orm_meta].[values_instance] as vi
			inner join children as tree
			--	on vi.instance_guid = tree.instance_guid
				on vi.value = tree.instance_guid
			inner join related_properties as p
				on vi.property_guid = p.property_guid
	)
	select tree.instance_guid, tree.echelon --, i.name
	from children as tree
		inner join [orm_meta].[instances] as i
			on tree.instance_guid = i.instance_guid
)
GO


if object_id('[orm_meta].[suoer_instance_by_property]', 'IF') is not null
	drop function [orm_meta].[super_instance_by_property]
go

create function [orm_meta].[super_instance_by_property]
(	
	@root_object_guid uniqueidentifier
,	@by_property_name varchar(255)
)
RETURNS TABLE 
AS
RETURN 
(
	with related_properties as
	(	-- get all properties that if the same (or sub) 
		-- of the given property's datatype
		select sp.property_guid
		from [orm_meta].[properties] as p
			inner join [orm_meta].[templates] as t
				on p.template_guid = t.template_guid
			inner join [orm_meta].[instances] as i
				on i.template_guid = t.template_guid
			cross apply [orm_meta].[sub_templates](p.datatype_guid) as sdt
			inner join [orm_meta].[properties] as sp
				on sp.datatype_guid = sdt.template_guid
		where i.instance_guid = @root_object_guid
			and p.name = @by_property_name
			and sp.name = @by_property_name
	)
	,	parents as
	(
		select @root_object_guid as instance_guid, 0 as echelon

		union all

		select vi.value as instance_guid, tree.echelon + 1 as echelon
		from [orm_meta].[values_instance] as vi
			inner join parents as tree
				on vi.instance_guid = tree.instance_guid
			inner join related_properties as p
				on vi.property_guid = p.property_guid
	)
	select tree.instance_guid, tree.echelon --, i.name
	from parents as tree
		inner join [orm_meta].[instances] as i
			on tree.instance_guid = i.instance_guid
)
GO


if object_id('[orm_meta].[instance_by_property_tree]', 'IF') is not null
	drop function [orm_meta].[instance_by_property_tree]
go

create function [orm_meta].[instance_by_property_tree]
(	
	@root_object_guid uniqueidentifier
,	@by_property_name varchar(255)
)
RETURNS TABLE 
AS
RETURN 
(
	select instance_guid, echelon
	from (	select instance_guid, echelon
			from [orm_meta].[sub_instance_by_property](@root_object_guid, @by_property_name) as subs
			
			union
			
			select instance_guid, echelon
			from [orm_meta].[super_instance_by_property](@root_object_guid, @by_property_name) as supers
		) as structure			
)
GO


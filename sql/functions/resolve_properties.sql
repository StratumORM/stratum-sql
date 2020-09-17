print '
Generating property resolution function...'


IF OBJECT_ID('[orm_meta].[resolve_properties]', 'IF') IS NOT NULL
	DROP FUNCTION [orm_meta].[resolve_properties]
go


IF TYPE_ID('[orm_meta].[identities]') IS NULL
-- 	DROP TYPE [orm_meta].[identities]
-- go

	CREATE TYPE [orm_meta].[identities] AS TABLE(
		[id] [int] NOT NULL,
		PRIMARY KEY CLUSTERED (	[id] ASC )
			WITH (IGNORE_DUP_KEY = OFF)
	)
GO


CREATE FUNCTION [orm_meta].[resolve_properties]
(	
	@template_ids identities readonly
)
RETURNS TABLE 
AS
RETURN 
(
	with
		scoped_templates as
	(
		select distinct 
				tree.template_id as in_scope_template_id
		from @template_ids as t
			cross apply [orm_meta].[template_tree](t.id) as tree
	)
	,	current_scoped_template_properties as
	(
		select	
				p.template_id as affected_template_id
			,	p.name as property_name
			,	p.datatype_id as datatype_id
			,	p.is_extended
			,	p.signature
		from scoped_templates as s
			inner join [orm_meta].[properties] as p
				on p.template_id = s.in_scope_template_id
	)
	,	template_inheritance as
	(
		select distinct
				s.in_scope_template_id
			,	isnull(inherit.parent_template_id, s.in_scope_template_id) as source_id	--isnull allows us to make templates with no inheritance to be their own source
			,	DENSE_RANK() over (	partition by s.in_scope_template_id 
									order by	case supers.echelon
													when 0 then 32000 
													else inherit.ordinal 
												end
												, supers.echelon desc
								) as inherit_rank
		from scoped_templates as s 
			cross apply [orm_meta].[super_templates](s.in_scope_template_id) as supers
			left join [orm_meta].[inheritance] as inherit
				on supers.template_id = inherit.parent_template_id
	)
	,	all_inherited_properties as
	(
		select	
				p.property_id as masked_property_id
			,	p.template_id as masked_template_id
			,	p.name as masked_name
			,	p.datatype_id as masked_datatype_id
			,	p.is_extended as masked_is_extended
			,	p.signature as masked_signature
		
			,	case when isnull(p.is_extended,0) = 0 then 1
					else 0
				end as is_base

			,	i.in_scope_template_id
			,	i.inherit_rank
		from template_inheritance as i
			inner join [orm_meta].[properties] as p
				on p.template_id = i.source_id
	)
	,	in_scoped_template_overrides as
	(	-- Overridden properties
		select	distinct
				p.in_scope_template_id as top_most_in_scope_id
			,	p.masked_name as top_most_property_name
			,	min(p.inherit_rank) as top_most_inherit_rank
		from all_inherited_properties as p
		where isnull(p.masked_is_extended,0) = 0  -- Only include base properties
		group by p.in_scope_template_id, p.masked_name
		having sum(p.is_base) > 0				-- ANY parent property can force base properties
	)
	,	in_scoped_template_nonoverrides as
	(
		select	p.in_scope_template_id as top_most_in_scope_id
			,	p.masked_name as top_most_property_name
			,	max(p.inherit_rank) as top_most_inherit_rank
		from all_inherited_properties as p
			left join in_scoped_template_overrides as o
				on p.in_scope_template_id = o.top_most_in_scope_id
				and p.masked_name = o.top_most_property_name
		where o.top_most_in_scope_id is null 
			and p.masked_template_id = p.in_scope_template_id
		group by p.in_scope_template_id, p.masked_name
	)
	,	fully_scoped_mask as
	(
		select
				aip.in_scope_template_id as template_id
			,	isto.top_most_property_name as property_name
			,	AIP.in_scope_template_id

			,	aip.masked_property_id
			,	aip.masked_template_id
			,	aip.masked_name
			,	aip.masked_datatype_id
			,	aip.masked_is_extended
			,	aip.masked_signature
		from all_inherited_properties as aip
			inner join (select top_most_in_scope_id, top_most_property_name, top_most_inherit_rank 
						from in_scoped_template_nonoverrides
					
						union all
					
						select top_most_in_scope_id, top_most_property_name, top_most_inherit_rank
						from in_scoped_template_overrides) as isto
				on aip.in_scope_template_id = isto.top_most_in_scope_id
				and aip.masked_name = isto.top_most_property_name
				and aip.inherit_rank = isto.top_most_inherit_rank
			inner join [orm_meta].[templates] as t
				on aip.masked_template_id = t.template_id
			inner join [orm_meta].[templates] as it
				on aip.in_scope_template_id = it.template_id
	)
	select	
			fsm.in_scope_template_id as scoped_template_id -- we need this as a breadcrumb
		,	fsm.masked_property_id
		,	fsm.masked_template_id
		,	fsm.masked_name
		,	fsm.masked_datatype_id
		,	fsm.masked_is_extended
		,	fsm.masked_signature

		,	p.property_id as current_property_id
		,	p.template_id as current_template_id
		,	p.name as current_name
		,	p.datatype_id as current_datatype_id
		,	p.is_extended as current_is_extended
		,	p.signature as current_signature	
	from fully_scoped_mask as fsm
		left join [orm_meta].[properties] as p
			on fsm.template_id = p.template_id
			and fsm.property_name = p.name
)
GO

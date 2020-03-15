print '
Generating property resolution function...'


IF OBJECT_ID('[orm_meta].[resolve_properties]', 'IF') IS NOT NULL
	DROP FUNCTION [orm_meta].[resolve_properties]
go


IF TYPE_ID('[orm_meta].[identities]') IS NOT NULL
	DROP TYPE [orm_meta].[identities]
go

CREATE TYPE [orm_meta].[identities] AS TABLE(
	[id] [int] NOT NULL,
	PRIMARY KEY CLUSTERED (	[id] ASC )
		WITH (IGNORE_DUP_KEY = OFF)
)
GO


CREATE FUNCTION [orm_meta].[resolve_properties]
(	
	@templateIDs identities readonly
)
RETURNS TABLE 
AS
RETURN 
(
	with
		scopedTemplates as
	(
		select distinct 
				tree.templateID as inScopeTemplateID
		from @templateIDs as t
			cross apply [orm_meta].[templateTree](t.id) as tree
	)
	,	currentScopedTemplateProperties as
	(
		select	
				p.templateID as affectedTemplateID
			,	p.name as propertyName
			,	p.datatypeID as datatypeID
			,	p.isExtended
			,	p.signature
		from scopedTemplates as s
			inner join [orm_meta].[properties] as p
				on p.templateID = s.inScopeTemplateID
	)
	,	templateInheritance as
	(
		select distinct
				s.inScopeTemplateID
			,	isnull(inherit.parentTemplateID, s.inScopeTemplateID) as sourceID	--isnull allows us to make templates with no inheritance to be their own source
			,	DENSE_RANK() over (	partition by s.inScopeTemplateID 
									order by	case supers.echelon
													when 0 then 32000 
													else inherit.ordinal 
												end
												, supers.echelon desc
								) as inheritRank
		from scopedTemplates as s 
			cross apply [orm_meta].[superTemplates](s.inScopeTemplateID) as supers
			left join [orm_meta].[inheritance] as inherit
				on supers.templateID = inherit.parentTemplateID
	)
	,	allInheritedProperties as
	(
		select	
				p.propertyID as masked_propertyID
			,	p.templateID as masked_templateID
			,	p.name as masked_name
			,	p.datatypeID as masked_datatypeID
			,	p.isExtended as masked_isExtended
			,	p.signature as masked_signature
		
			,	case when isnull(p.isExtended,0) = 0 then 1
					else 0
				end as isBase

			,	i.inScopeTemplateID
			,	i.inheritRank
		from templateInheritance as i
			inner join [orm_meta].[properties] as p
				on p.templateID = i.sourceID
	)
	,	inScopedTemplateOverrides as
	(	-- Overridden properties
		select	distinct
				p.inScopeTemplateID as topMostInScopeID
			,	p.masked_name as topMostPropertyName
			,	min(p.inheritRank) as topMostInheritRank
		from allInheritedProperties as p
		where isnull(p.masked_isExtended,0) = 0  -- Only include base properties
		group by p.inScopeTemplateID, p.masked_name
		having sum(p.isBase) > 0				-- ANY parent property can force base properties
	)
	,	inScopedTemplateNonoverrides as
	(
		select	p.inScopeTemplateID as topMostInScopeID
			,	p.masked_name as topMostPropertyName
			,	max(p.inheritRank) as topMostInheritRank
		from allInheritedProperties as p
			left join inScopedTemplateOverrides as o
				on p.inScopeTemplateID = o.topMostInScopeID
				and p.masked_name = o.topMostPropertyName
		where o.topMostInScopeID is null 
			and p.masked_templateID = p.inScopeTemplateID
		group by p.inScopeTemplateID, p.masked_name
	)
	,	fullyScopedMask as
	(
		select
				aip.inScopeTemplateID as templateID
			,	isto.topMostPropertyName as propertyName
			,	AIP.inScopeTemplateID

			,	aip.masked_propertyID
			,	aip.masked_templateID
			,	aip.masked_name
			,	aip.masked_datatypeID
			,	aip.masked_isExtended
			,	aip.masked_signature
		from allInheritedProperties as aip
			inner join (select topMostInScopeID, topMostPropertyName, topMostInheritRank 
						from inscopedTemplateNonoverrides
					
						union all
					
						select topMostInScopeID, topMostPropertyName, topMostInheritRank
						from inScopedTemplateOverrides) as isto
				on aip.inScopeTemplateID = isto.topMostInscopeID
				and aip.masked_name = isto.topMostPropertyName
				and aip.inheritRank = isto.topMostInheritRank
			inner join [orm_meta].[templates] as t
				on aip.masked_templateID = t.templateID
			inner join [orm_meta].[templates] as it
				on aip.inScopeTemplateID = it.templateID
	)
	select	
			fsm.inScopeTemplateID as scoped_templateID -- we need this as a breadcrumb
		,	fsm.masked_propertyID
		,	fsm.masked_templateID
		,	fsm.masked_name
		,	fsm.masked_datatypeID
		,	fsm.masked_isExtended
		,	fsm.masked_signature

		,	p.propertyID as current_propertyID
		,	p.templateID as current_templateID
		,	p.name as current_name
		,	p.datatypeID as current_datatypeID
		,	p.isExtended as current_isExtended
		,	p.signature as current_signature	
	from fullyScopedMask as fsm
		left join [orm_meta].[properties] as p
			on fsm.templateID = p.templateID
			and fsm.propertyName = p.name
)
GO

print '
Generating template inheritance CRUD definitions...'


IF OBJECT_ID('[orm].[inherit_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[inherit_add]
go

IF OBJECT_ID('[orm_meta].[inherit_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[inherit_add]
go


create procedure [orm_meta].[inherit_add]
	@parent_template_id int
,	@child_template_id int
,	@ordinal int = null 	
as
begin

	-- by default we'll tack the ordinal to the end, so get the largest value + 1
	if @ordinal is null 	set @ordinal = (	select isnull(max(ordinal), 0) + 1
												from [orm_meta].[inheritance] as i
												where child_template_id = @child_template_id	)

	-- Perform a merge in case the ordinal is merely changing
	-- Triggers will take care of the resolution of the properties.
	merge into [orm_meta].[inheritance] as d
	using (	select	@parent_template_id as parent_template_id
				,	@child_template_id as child_template_id
				,	@ordinal as ordinal) as s
		on d.parent_template_id = s.parent_template_id
		and d.child_template_id = s.child_template_id
	when matched then
		update
		set d.ordinal = s.ordinal
	when not matched then
		insert (parent_template_id, child_template_id, ordinal)
		values (s.parent_template_id, s.child_template_id, s.ordinal)
	;

end
go


create procedure [orm].[inherit_add]
	@parent_template_name varchar(250)
,	@child_template_name varchar(250)
,	@ordinal int = null 	
as
begin
	
	-- resolve the IDs so that the meta sproc can take care of the rest
	declare @parent_template_id int, @child_template_id int
		set @parent_template_id = (select top 1 template_id from [orm_meta].[templates] where name = @parent_template_name)
		set @child_template_id = (select top 1 template_id from [orm_meta].[templates] where name = @child_template_name)

	exec [orm_meta].[inherit_add] @parent_template_id, @child_template_id, @ordinal

end
go


IF OBJECT_ID('[orm].[inherit_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[inherit_remove]
go

IF OBJECT_ID('[orm_meta].[inherit_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[inherit_remove]
go

create procedure [orm_meta].[inherit_remove]
	@parent_template_id int
,	@child_template_id int
as
begin

	delete [orm_meta].[inheritance]
	where 	parent_template_id = @parent_template_id
		and	child_template_id = @child_template_id

end
go


create procedure [orm].[inherit_remove]
	@parent_template_name varchar(250)
,	@child_template_name varchar(250)
as
begin
	
	-- resolve the IDs so that the meta sproc can take care of the rest
	declare @parent_template_id int, @child_template_id int
		set @parent_template_id = (select top 1 template_id from [orm_meta].[templates] where name = @parent_template_name)
		set @child_template_id = (select top 1 template_id from [orm_meta].[templates] where name = @child_template_name)

	exec [orm_meta].[inherit_remove] @parent_template_id, @child_template_id

end
go

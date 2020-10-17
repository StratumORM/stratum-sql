print '
Generating guid resolving functions...'



if object_id('[orm_meta].[resolve_template_guid]', 'FN') is not null
	drop function [orm_meta].[resolve_template_guid]
go

create function [orm_meta].[resolve_template_guid]
(
	@template_name varchar(250)
)
returns uniqueidentifier
as
begin
	return (
		select t.template_guid
		from [orm_meta].[templates] as t
		where t.name = @template_name
	)
end
go



if object_id('[orm_meta].[resolve_property_guid]', 'FN') is not null
	drop function [orm_meta].[resolve_property_guid]
go


create function [orm_meta].[resolve_property_guid]
(
	@template_name varchar(250)
,	@property_name varchar(250)
)
returns uniqueidentifier
as
begin
	return (
		select p.property_guid
		from [orm_meta].[properties] as p
			inner join [orm_meta].[templates] as t
				on p.template_guid = t.template_guid
		where p.name = @property_name
			and t.name = @template_name
	)
end
go



if object_id('[orm_meta].[resolve_instance_guid]', 'FN') is not null
	drop function [orm_meta].[resolve_instance_guid]
go


create function [orm_meta].[resolve_instance_guid]
(
	@template_name varchar(250)
,	@instance_name varchar(250)
)
returns uniqueidentifier
as
begin
	return (
		select i.instance_guid
		from [orm_meta].[instances] as i
			inner join [orm_meta].[templates] as t
				on i.template_guid = t.template_guid
		where i.name = @instance_name
			and t.name = @template_name
	)
end
go


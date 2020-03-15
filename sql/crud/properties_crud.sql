print '
Generating property CRUD definitions...'


IF OBJECT_ID('[orm].[property_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[property_add]
go

create procedure [orm].[property_add]
	@template_name varchar(250)
,	@new_property_name varchar(250)
,	@data_type varchar(250)
,	@is_extended int = 0
as
begin
	SET NOCOUNT ON;
	
	declare @template_id int, @datatype_id int
		select @template_id = template_id
		from [orm_meta].[templates]
		where name = @template_name

		select @datatype_id = template_id
		from [orm_meta].[templates] 
		where name = @data_type
	
	insert [orm_meta].[properties] (template_id, name, datatype_id, is_extended)
	values (@template_id, @new_property_name, @datatype_id, @is_extended)

	return @@identity
end
go

IF OBJECT_ID('[orm].[property_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[property_remove]
go

create procedure [orm].[property_remove]
	@template_name varchar(250)
,	@property_name varchar(250)
as
begin
	SET NOCOUNT ON;
	
	declare @template_id int, @datatype_id int, @property_id int

		select @template_id = template_id
		from [orm_meta].[templates]
		where name = @template_name

		select	@datatype_id = p.datatype_id
			,	@property_id = p.property_id
		from [orm_meta].[properties] as p
		where p.template_id = @template_id
			and p.name = @property_name

	-- remove the property
	delete [orm_meta].[properties]
	where	template_id = @template_id
		and name = @property_name
		
end
go


IF OBJECT_ID('[orm].[property_rename]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].[property_rename]
go

create procedure [orm].[property_rename]
	@template_name varchar(250)
,	@old_property_name varchar(250)
,	@new_property_name varchar(250)
as
begin

	update p
	set name = @new_property_name
	from [orm_meta].[properties] as p
		inner join [orm_meta].[templates] as t
			on t.template_id = p.template_id
	where	t.name = @template_name
		and p.name = @old_property_name

end 
go

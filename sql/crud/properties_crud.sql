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
,	@no_history int = 0
as
begin
	set nocount on;
	
	declare @template_guid uniqueidentifier
		, 	@datatype_guid uniqueidentifier
		
		select @template_guid = template_guid
		from [orm_meta].[templates]
		where name = @template_name

		select @datatype_guid = template_guid
		from [orm_meta].[templates] 
		where name = @data_type
	
	insert [orm_meta].[properties] 
		   ( template_guid,               name,  datatype_guid,  is_extended,  no_history)
	values (@template_guid, @new_property_name, @datatype_guid, @is_extended, @no_history)

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
	set nocount on;
	
	declare @template_guid uniqueidentifier

		select @template_guid = template_guid
		from [orm_meta].[templates]
		where name = @template_name

	-- remove the property
	delete [orm_meta].[properties]
	where	template_guid = @template_guid
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
	set nocount on;

	update p
	set name = @new_property_name
	from [orm_meta].[properties] as p
		inner join [orm_meta].[templates] as t
			on t.template_guid = p.template_guid
	where	t.name = @template_name
		and p.name = @old_property_name

end 
go

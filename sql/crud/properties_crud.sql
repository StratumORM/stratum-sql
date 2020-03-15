print '
Generating property CRUD definitions...'


IF OBJECT_ID('[orm].[orm_property_add]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_property_add
go

create procedure orm_property_add
	@templateName varchar(250)
,	@newPropertyName varchar(250)
,	@dataType varchar(250)
,	@isExtended int = 0
as
begin
	SET NOCOUNT ON;
	
	declare @templateID int, @datatypeID int
		select @templateID = templateID
		from orm_meta_templates
		where name = @templateName

		select @datatypeID = templateID
		from orm_meta_templates 
		where name = @dataType
	
	insert orm_meta_properties (templateID, name, datatypeID, isExtended)
	values (@templateID, @newPropertyName, @datatypeID, @isExtended)

	return @@identity
end
go

IF OBJECT_ID('[orm].[orm_property_remove]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_property_remove
go

create procedure orm_property_remove
	@templateName varchar(250)
,	@propertyName varchar(250)
as
begin
	SET NOCOUNT ON;
	
	declare @templateID int, @datatypeID int, @propertyID int

		select @templateID = templateID
		from orm_meta_templates
		where name = @templateName

		select	@datatypeID = p.datatypeID
			,	@propertyID = p.propertyID
		from orm_meta_properties as p
		where p.templateID = @templateID
			and p.name = @propertyName

	-- remove the property
	delete orm_meta_properties
	where	templateID = @templateID
		and name = @propertyName
		
end
go


IF OBJECT_ID('[orm].[orm_property_rename]', 'P') IS NOT NULL
	DROP PROCEDURE [orm].orm_property_rename
go

create procedure orm_property_rename
	@templateName varchar(250)
,	@oldPropertyName varchar(250)
,	@newPropertyName varchar(250)
as
begin

	update p
	set name = @newPropertyName
	from orm_meta_properties as p
		inner join orm_meta_templates as t
			on t.templateID = p.templateID
	where	t.name = @templateName
		and p.name = @oldPropertyName

end 
go

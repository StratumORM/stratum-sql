print '
Generating value cleanup sprocs...'


IF TYPE_ID('[orm_meta].[identities]') IS NULL
-- 	DROP TYPE [orm_meta].[identities]
-- go

	CREATE TYPE [orm_meta].[identities] AS TABLE(
		guid uniqueidentifier NOT NULL,
		PRIMARY KEY CLUSTERED (	[guid] ASC )
			WITH (IGNORE_DUP_KEY = OFF)
	)
GO



IF OBJECT_ID('[orm_meta].[cascade_delete_property]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[cascade_delete_property]
go



create procedure [orm_meta].[cascade_delete_property]
	@property_guids identities READONLY
as
begin
begin try
begin transaction cascaded_property_delete

  set nocount on; set xact_abort on;

	-- Perform the cascading delete on the values tables 
	delete v
	from [orm_meta].[values_string] as v 
		inner join @property_guids as d 
			on v.property_guid = d.guid

	delete v
	from [orm_meta].[values_integer] as v 
		inner join @property_guids as d 
			on v.property_guid = d.guid
		
	delete v
	from [orm_meta].[values_decimal] as v 
		inner join @property_guids as d 
			on v.property_guid = d.guid
		
	delete v
	from [orm_meta].[values_datetime] as v 
		inner join @property_guids as d 
			on v.property_guid = d.guid
		
	delete v
	from [orm_meta].[values_instance] as v 
		inner join @property_guids as d 
			on v.property_guid = d.guid

  commit transaction cascaded_property_delete

end try
begin catch
	exec [orm_meta].[handle_error] '[orm_meta].[cascade_delete_property]'
end catch
end
go



IF OBJECT_ID('[orm_meta].[cascade_delete_instance]', 'P') IS NOT NULL
	DROP PROCEDURE [orm_meta].[cascade_delete_instance]
go



create procedure [orm_meta].[cascade_delete_instance]
	@instance_guids identities READONLY
as
begin
begin try
begin transaction cascaded_instance_delete

  set nocount on; set xact_abort on;

	-- Perform the cascading delete on the values tables 
	delete v
	from [orm_meta].[values_string] as v 
		inner join @instance_guids as d 
			on v.instance_guid = d.guid

	delete v
	from [orm_meta].[values_integer] as v 
		inner join @instance_guids as d
			on v.instance_guid = d.guid
		
	delete v
	from [orm_meta].[values_decimal] as v 
		inner join @instance_guids as d
			on v.instance_guid = d.guid
		
	delete v
	from [orm_meta].[values_datetime] as v 
		inner join @instance_guids as d
			on v.instance_guid = d.guid
		
	delete v
	from [orm_meta].[values_instance] as v 
		inner join @instance_guids as d
			on v.instance_guid = d.guid

	-- -- Instances may be a bit exceptional, breaking the rule
	-- --   that values are not indexed. For referential
	-- --   integrity reasons we may want to make sure values
	-- --   can be found (say, for instance deletes)
	-- delete v
	-- from [orm_meta].[values_instance] as v 
	-- 	inner join @instance_guids as d
	-- 		on v.value = d.guid

  commit transaction cascaded_instance_delete

end try
begin catch
	exec [orm_meta].[handle_error] @@PROCID
end catch
end
go

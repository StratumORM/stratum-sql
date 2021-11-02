print '
Generating metadata for extensions...'


begin try

	begin transaction meta_init

		insert orm_meta.templates (name, template_guid, no_auto_view, signature)
		values 	('META', convert(uniqueidentifier, '00000000-ABCD-ABCD-ABCD-000000000000')
			    , 1, 'Root type - Stratum interface specification extensions')
			,	('Indexable', convert(uniqueidentifier, '00000000-ABCD-ABCD-ABCD-000000000002')
			    , 1, 'Signals that the template class can be referenced for indexing')
			,	('Index', convert(uniqueidentifier, '00000000-ABCD-ABCD-ABCD-000000000001')
			    , 1, 'Identify properties that should be indexed in the application')

	commit transaction meta_init

	begin transaction meta_add_index

		exec orm.inherit_add 'META', 'Index'
	
		exec orm.property_add 'Index', 'template', 'Indexable'
		exec orm.property_add 'Index', 'properties', 'string'
		exec orm.property_add 'Index', 'delimiter', 'string'
		-- exec orm.property_add 'Index', 'ordinal', 'integer'

	commit transaction meta_add_index

end try
begin catch
    declare @error_message nvarchar(max), @error_severity int, @error_state int
    select  @error_message = ERROR_MESSAGE() 
			+ ' Found in ' + ERROR_PROCEDURE() 
			+ ' at Line ' + cast(ERROR_LINE() as nvarchar(5))
		,	@error_severity = ERROR_SEVERITY()
		,	@error_state = ERROR_STATE()
    rollback transaction
    raiserror (@error_message, @error_severity, @error_state)
end catch

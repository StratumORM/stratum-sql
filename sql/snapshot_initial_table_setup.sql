print '
Initializing to initial and basic configuration...'


exec [orm_meta].[apply_context] 'overwrite init backups', 1
exec [orm_xo].[create_init_tables]
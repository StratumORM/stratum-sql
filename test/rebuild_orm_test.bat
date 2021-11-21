ECHO OFF
REM A simple Windows batch that rebuilds the datbase

cd %~dp0

cls

ECHO Rebuilding the test ORM database from scratch.
ECHO Command outputs are directed to rebuild_orm_test.log

ECHO Ensure that sqlcmd.exe is in the PATH environment variable!

SET INSTANCENAME=%COMPUTERNAME%\SQLEXPRESS
SET DATABASENAME=orm_test

SET USERNAME=
SET PASSWORD=

ECHO Interacting with (at %INSTANCENAME%) using %DATABASENAME%

IF "%USERNAME%"=="" (SET SQL_COMMAND=sqlcmd -S %INSTANCENAME% -r -d %DATABASENAME% -i ..\sql) ELSE (SET SQL_COMMAND=sqlcmd -U %USERNAME% -P %PASSWORD% -S %INSTANCENAME% -r -d %DATABASENAME% -i ..\sql)

SET LOGFILE=rebuild_orm_test.log

ECHO Starting batch for recreating orm_test > %LOGFILE%
ECHO %date% %time% >> %LOGFILE%

IF not "%DATABASENAME%" == "orm_test" (goto :not_test_db)

ECHO Dropping and creating orm_test
REM Note that this command doesn't connect to the database: that's so we can drop it!
sqlcmd -S %INSTANCENAME% -r -i ..\sql\create_database_orm_test.sql >> %LOGFILE%

ECHO --- --- --- --- --- ---
ECHO Error handler sproc...
%SQL_COMMAND%\meta_sprocs\error_handling.sql >> %LOGFILE%


ECHO Building base tables and views...
ECHO --- base tables
%SQL_COMMAND%\tables\base_tables.sql >> %LOGFILE%

ECHO --- values tables
%SQL_COMMAND%\tables\values_tables.sql >> %LOGFILE%

ECHO --- inheritance tables
%SQL_COMMAND%\tables\inheritance_tables.sql >> %LOGFILE%

ECHO --- hist tables
%SQL_COMMAND%\tables\hist_tables.sql >> %LOGFILE%

ECHO --- temp staging tables
%SQL_COMMAND%\tables\temp_tables.sql >> %LOGFILE%

ECHO --- meta context
%SQL_COMMAND%\meta_sprocs\context.sql >> %LOGFILE%


ECHO Building views onto the tables...
ECHO --- values views
%SQL_COMMAND%\views\values_views.sql >> %LOGFILE%

ECHO --- meta values views
%SQL_COMMAND%\views\meta_values_views.sql >> %LOGFILE%

ECHO --- helper views
%SQL_COMMAND%\views\helper_views.sql >> %LOGFILE%


ECHO Define functions ...
ECHO --- inheritance
%SQL_COMMAND%\functions\template_inheritance.sql >> %LOGFILE%

ECHO --- sanitize string
%SQL_COMMAND%\functions\sanitize_string.sql >> %LOGFILE%

ECHO --- properties
%SQL_COMMAND%\functions\resolve_properties.sql >> %LOGFILE%

ECHO --- values
%SQL_COMMAND%\functions\values.sql >> %LOGFILE%

ECHO --- instance chaining
%SQL_COMMAND%\functions\instance_chaining.sql >> %LOGFILE%

ECHO --- resolvers
%SQL_COMMAND%\functions\resolvers.sql >> %LOGFILE%

ECHO --- history values
%SQL_COMMAND%\functions\history_values.sql >> %LOGFILE%

ECHO --- history spans
%SQL_COMMAND%\functions\history_spans.sql >> %LOGFILE%


ECHO Define meta sprocs (sprocs that build sql)...
ECHO --- gen template view wide
%SQL_COMMAND%\meta_sprocs\generate_view_wide.sql >> %LOGFILE%

ECHO --- gen template view tall
%SQL_COMMAND%\meta_sprocs\generate_view_tall.sql >> %LOGFILE%

ECHO --- gen template view listing
%SQL_COMMAND%\meta_sprocs\generate_view_listing.sql >> %LOGFILE%

ECHO --- cascade deletes for values
%SQL_COMMAND%\meta_sprocs\value_cascade_delete.sql >> %LOGFILE%

ECHO --- column bitmask decoding
%SQL_COMMAND%\functions\decode_updated_columns_bitmask.sql >> %LOGFILE%

ECHO --- dynamic template view crud trigger
%SQL_COMMAND%\meta_sprocs\template_view_crud_triggers.sql >> %LOGFILE%

ECHO --- all values listing crud trigger
%SQL_COMMAND%\meta_sprocs\all_values_listing_crud_triggers.sql >> %LOGFILE%

ECHO --- purge routines....
%SQL_COMMAND%\meta_sprocs\purge.sql >> %LOGFILE%

ECHO --- backup routines....
%SQL_COMMAND%\meta_sprocs\save_setup.sql >> %LOGFILE%


ECHO Define CRUD sprocs...
ECHO --- template
%SQL_COMMAND%\crud\template_crud.sql >> %LOGFILE%

ECHO --- property
%SQL_COMMAND%\crud\properties_crud.sql >> %LOGFILE%

ECHO --- value
%SQL_COMMAND%\crud\value_crud.sql >> %LOGFILE%

ECHO --- instance
%SQL_COMMAND%\crud\instance_crud.sql >> %LOGFILE%

ECHO --- inheritance
%SQL_COMMAND%\crud\inheritance_crud.sql >> %LOGFILE%


ECHO Add triggers to tables...
ECHO --- template
%SQL_COMMAND%\triggers\template_triggers.sql >> %LOGFILE%

ECHO --- instance
%SQL_COMMAND%\triggers\instance_triggers.sql >> %LOGFILE%

ECHO --- values
%SQL_COMMAND%\triggers\values_triggers.sql >> %LOGFILE%

ECHO --- property
%SQL_COMMAND%\triggers\property_triggers.sql >> %LOGFILE%

ECHO --- inheritance
%SQL_COMMAND%\triggers\inheritance_triggers.sql >> %LOGFILE%


ECHO Configuring extension support...
%SQL_COMMAND%\tables\extensions.sql >> %LOGFILE%


ECHO Snapshotting state after setup...
%SQL_COMMAND%\snapshot_initial_table_setup.sql >> %LOGFILE%


ECHO ------------------------
ECHO Rebuild script finished!

GOTO :finished

:not_test_db

ECHO Rebuild only applies to orm_test.
ECHO Please run the individual scrips or generate a new one to affect another database.

:finished
PAUSE

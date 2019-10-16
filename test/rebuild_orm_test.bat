ECHO OFF
REM A simple Windows batch that rebuilds the datbase

cls

ECHO Rebuilding the test ORM database from scratch.
ECHO Command outputs are directed to rebuild_orm_test.log

IF "%COMPUTERNAME%" == "LINKED48" (
	SET INSTANCENAME=\SANDBOX
	ECHO Interacting with home machine...
) ELSE (
	IF "%COMPUTERNAME%" == "ANDREW-LT-E6540" (
		ECHO Interacting with TriMax machine...
		SET INSTANCENAME=
	) ELSE (
		SET INSTANCENAME=\SQLEXPRESS
		)
)
SET DATABASENAME=orm_test

ECHO Interacting with %COMPUTERNAME% (at %INSTANCENAME%) using %DATABASENAME%

SET SQL_COMMAND=sqlcmd -S %COMPUTERNAME%%INSTANCENAME% -r -d %DATABASENAME% -i .\sql
SET LOGFILE=rebuild_orm_test.log

ECHO Starting batch for recreating orm_test > %LOGFILE%
ECHO %date% %time% >> %LOGFILE%

IF not "%DATABASENAME%" == "orm_test" (goto :not_test_db)

ECHO Dropping and creating orm_test
REM Note that this command doesn't connect to the database: that's so we can drop it!
sqlcmd -S %COMPUTERNAME%%INSTANCENAME% -r -i .\sql\create_database_orm_test.sql >> %LOGFILE%

ECHO Building base tables and views...
%SQL_COMMAND%\tables\base_tables.sql >> %LOGFILE%
%SQL_COMMAND%\tables\values_tables.sql >> %LOGFILE%
%SQL_COMMAND%\tables\inheritance_tables.sql >> %LOGFILE%

ECHO Building views onto the tables...
%SQL_COMMAND%\views\values_views.sql >> %LOGFILE%
%SQL_COMMAND%\views\meta_values_views.sql >> %LOGFILE%
%SQL_COMMAND%\views\helper_views.sql >> %LOGFILE%

ECHO Define functions ...
%SQL_COMMAND%\functions\template_inheritance.sql >> %LOGFILE%
%SQL_COMMAND%\functions\sanitize_string.sql >> %LOGFILE%
%SQL_COMMAND%\functions\resolve_properties.sql >> %LOGFILE%
%SQL_COMMAND%\functions\values.sql >> %LOGFILE%

ECHO Define meta sprocs (sprocs that build sql)...
%SQL_COMMAND%\meta_sprocs\generate_view_wide.sql >> %LOGFILE%
%SQL_COMMAND%\meta_sprocs\generate_view_tall.sql >> %LOGFILE%
%SQL_COMMAND%\meta_sprocs\generate_view_listing.sql >> %LOGFILE%
%SQL_COMMAND%\meta_sprocs\cascadeDelete_properties.sql >> %LOGFILE%

ECHO Define CRUD sprocs...
%SQL_COMMAND%\crud\template_crud.sql >> %LOGFILE%
%SQL_COMMAND%\crud\properties_crud.sql >> %LOGFILE%
%SQL_COMMAND%\crud\value_crud.sql >> %LOGFILE%
%SQL_COMMAND%\crud\instance_crud.sql >> %LOGFILE%
%SQL_COMMAND%\crud\inheritance_crud.sql >> %LOGFILE%

ECHO Add triggers to tables...
%SQL_COMMAND%\triggers\template_triggers.sql >> %LOGFILE%
%SQL_COMMAND%\triggers\property_triggers.sql >> %LOGFILE%
%SQL_COMMAND%\triggers\inheritance_triggers.sql >> %LOGFILE%

ECHO Rebuild script finished!

GOTO :finished

:not_test_db

ECHO Rebuild only applies to orm_test.
ECHO Please run the individual scrips or generate a new one to affect another database.

:finished
PAUSE
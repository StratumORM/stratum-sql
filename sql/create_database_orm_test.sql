print 'Dropping ALL connections to orm_test...'

DECLARE @db_id int
DECLARE @is_stat_async_on bit
DECLARE @job_id int
DECLARE @sql_string nvarchar(500)

SELECT @db_id = database_id,
       @is_stat_async_on = is_auto_update_stats_async_on
FROM sys.databases
WHERE name = 'db_name'

IF @is_stat_async_on = 1
BEGIN
    ALTER DATABASE [db_name] SET  AUTO_UPDATE_STATISTICS_ASYNC OFF

    -- kill running jobs
    DECLARE jobs_cursor CURSOR FOR
    SELECT job_id
    FROM sys.dm_exec_background_job_queue
    WHERE database_id = @db_id

    OPEN jobs_cursor

    FETCH NEXT FROM jobs_cursor INTO @job_id
    WHILE @@FETCH_STATUS = 0
    BEGIN
        set @sql_string = 'KILL STATS JOB ' + STR(@job_id)
        EXECUTE sp_executesql @sql_string
        FETCH NEXT FROM jobs_cursor INTO @job_id
    END

    CLOSE jobs_cursor
    DEALLOCATE jobs_cursor
END

alter database orm_test set single_user with rollback immediate

print 'Dropping database orm_test...'
drop database orm_test
go

print 'Creating database orm_test...'
create database orm_test
go

print 'Setting database options...'

ALTER DATABASE orm_test SET READ_COMMITTED_SNAPSHOT ON
go
ALTER DATABASE orm_test SET ALLOW_SNAPSHOT_ISOLATION ON
go


print 'Setting up orm_test_user...'

use [master]
go

if exists ( select name  
            from master.sys.server_principals
            where name = 'orm_test_user')
     drop login [orm_test_user]
go


if exists ( select name  
            from master.sys.server_principals
            where name = 'orm_test_maintainer')
     drop login [orm_test_user]
go


create login [orm_test_user] with password=N'password', default_database=[orm_test], default_language=[us_english], check_expiration=off, check_policy=off
go
create login [orm_test_maintainer] with password=N'Capital pea no-S sassword 1', default_database=[orm_test], default_language=[us_english], check_expiration=off, check_policy=off
go


use [orm_test]
go

create user [orm_test_user] for login [orm_test_user] with default_schema=[dbo]
go
create user [orm_test_maintainer] for login [orm_test_maintainer] with default_schema=[dbo]
go

-- ensure it's connected to the new database
alter user [orm_test_user] with Login = [orm_test_user];
go
alter user [orm_test_maintainer] with Login = [orm_test_maintainer];
go

alter role db_owner add member orm_test_user
go
alter role db_owner add member orm_test_maintainer
go

-- User friendly access to stored procedures (Name based)
if not exists (select * from orm_test.sys.schemas where name = 'orm')
    exec('create schema orm')
go

-- Inner system sprocs and functions (GUID based)
if not exists (select * from orm_test.sys.schemas where name = 'orm_meta')
    exec('create schema orm_meta')
go

-- History tables to track changes to the system
if not exists (select * from orm_test.sys.schemas where name = 'orm_hist')
    exec('create schema orm_hist')
go

-- Staging tables for easier migration/merging/chunked inserts
if not exists (select * from orm_test.sys.schemas where name = 'orm_temp')
    exec('create schema orm_temp')
go

-- Executive control tables for high level init/purge/restart
if not exists (select * from orm_test.sys.schemas where name = 'orm_xo')
    exec('create schema orm_xo')
go

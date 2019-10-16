print 'Dropping ALL connections to orm_test...'

DECLARE @dbId int
DECLARE @isStatAsyncOn bit
DECLARE @jobId int
DECLARE @sqlString nvarchar(500)

SELECT @dbId = database_id,
       @isStatAsyncOn = is_auto_update_stats_async_on
FROM sys.databases
WHERE name = 'db_name'

IF @isStatAsyncOn = 1
BEGIN
    ALTER DATABASE [db_name] SET  AUTO_UPDATE_STATISTICS_ASYNC OFF

    -- kill running jobs
    DECLARE jobsCursor CURSOR FOR
    SELECT job_id
    FROM sys.dm_exec_background_job_queue
    WHERE database_id = @dbId

    OPEN jobsCursor

    FETCH NEXT FROM jobsCursor INTO @jobId
    WHILE @@FETCH_STATUS = 0
    BEGIN
        set @sqlString = 'KILL STATS JOB ' + STR(@jobId)
        EXECUTE sp_executesql @sqlString
        FETCH NEXT FROM jobsCursor INTO @jobId
    END

    CLOSE jobsCursor
    DEALLOCATE jobsCursor
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

create login [orm_test_user] with password=N'password', default_database=[orm_test], default_language=[us_english], check_expiration=off, check_policy=off
go

use [orm_test]
go

create user [orm_test_user] for login [orm_test_user] with default_schema=[dbo]
go

alter role db_owner add member orm_test_user
go


-- --a database for dba ------

create database dba;

-- --create a table to perpetuate the lock_wait info. not the  changeful view in sys or information_schema

create table lock_waits as
  select
        `r`.`trx_wait_started` AS `wait_started`,timediff(now(),
        `r`.`trx_wait_started`) AS `wait_age`,
        timestampdiff(SECOND,`r`.`trx_wait_started`,now()) AS `wait_age_secs`,
        `rl`.`lock_table` AS `locked_table`,`rl`.`lock_index` AS `locked_index`,
        `rl`.`lock_type` AS `locked_type`,`r`.`trx_id` AS `waiting_trx_id`,
        `r`.`trx_started` AS `waiting_trx_started`,
        timediff(now(),`r`.`trx_started`) AS `waiting_trx_age`,
        `r`.`trx_rows_locked` AS `waiting_trx_rows_locked`,
        `r`.`trx_rows_modified` AS `waiting_trx_rows_modified`,
        `r`.`trx_mysql_thread_id` AS `waiting_pid`,
        (`r`.`trx_query`) AS `waiting_query`,
        `rl`.`lock_id` AS `waiting_lock_id`,
        `rl`.`lock_mode` AS `waiting_lock_mode`,
        `b`.`trx_id` AS `blocking_trx_id`,
        `b`.`trx_mysql_thread_id` AS `blocking_pid`,
        (`b`.`trx_query`) AS `blocking_query`,
        `bl`.`lock_id` AS `blocking_lock_id`,
        `bl`.`lock_mode` AS `blocking_lock_mode`,
        `b`.`trx_started` AS `blocking_trx_started`,
        timediff(now(),`b`.`trx_started`) AS `blocking_trx_age`,
        `b`.`trx_rows_locked` AS `blocking_trx_rows_locked`,
        `b`.`trx_rows_modified` AS `blocking_trx_rows_modified`,
        concat('KILL QUERY ',`b`.`trx_mysql_thread_id`) AS `sql_kill_blocking_query`,
        concat('KILL ',`b`.`trx_mysql_thread_id`) AS `sql_kill_blocking_connection`
  from (
          (
            (
              (`information_schema`.`innodb_lock_waits` `w`   join `information_schema`.`innodb_trx` `b`  on((`b`.`trx_id` = `w`.`blocking_trx_id`))
              )
                   join `information_schema`.`innodb_trx` `r`  on((`r`.`trx_id` = `w`.`requesting_trx_id`))
            )
           join `information_schema`.`innodb_locks` `bl` on((`bl`.`lock_id` = `w`.`blocking_lock_id`))
         )
         join `information_schema`.`innodb_locks` `rl` on((`rl`.`lock_id` = `w`.`requested_lock_id`))
       )

-- --create a scheduled event to collect lock_wait info and save to the lock_waits created before

use dba;
create event collect_lock_waits
 ON SCHEDULE EVERY 1 SECOND

do
	insert into dba.lock_waits
    select
          `r`.`trx_wait_started` AS `wait_started`,timediff(now(),
          `r`.`trx_wait_started`) AS `wait_age`,
          timestampdiff(SECOND,`r`.`trx_wait_started`,now()) AS `wait_age_secs`,
          `rl`.`lock_table` AS `locked_table`,`rl`.`lock_index` AS `locked_index`,
          `rl`.`lock_type` AS `locked_type`,`r`.`trx_id` AS `waiting_trx_id`,
          `r`.`trx_started` AS `waiting_trx_started`,
          timediff(now(),`r`.`trx_started`) AS `waiting_trx_age`,
          `r`.`trx_rows_locked` AS `waiting_trx_rows_locked`,
          `r`.`trx_rows_modified` AS `waiting_trx_rows_modified`,
          `r`.`trx_mysql_thread_id` AS `waiting_pid`,
          (`r`.`trx_query`) AS `waiting_query`,
          `rl`.`lock_id` AS `waiting_lock_id`,
          `rl`.`lock_mode` AS `waiting_lock_mode`,
          `b`.`trx_id` AS `blocking_trx_id`,
          `b`.`trx_mysql_thread_id` AS `blocking_pid`,
          (`b`.`trx_query`) AS `blocking_query`,
          `bl`.`lock_id` AS `blocking_lock_id`,
          `bl`.`lock_mode` AS `blocking_lock_mode`,
          `b`.`trx_started` AS `blocking_trx_started`,
          timediff(now(),`b`.`trx_started`) AS `blocking_trx_age`,
          `b`.`trx_rows_locked` AS `blocking_trx_rows_locked`,
          `b`.`trx_rows_modified` AS `blocking_trx_rows_modified`,
          concat('KILL QUERY ',`b`.`trx_mysql_thread_id`) AS `sql_kill_blocking_query`,
          concat('KILL ',`b`.`trx_mysql_thread_id`) AS `sql_kill_blocking_connection`
    from (
            (
              (
                (`information_schema`.`innodb_lock_waits` `w`   join `information_schema`.`innodb_trx` `b`  on((`b`.`trx_id` = `w`.`blocking_trx_id`))
                )
                     join `information_schema`.`innodb_trx` `r`  on((`r`.`trx_id` = `w`.`requesting_trx_id`))
              )
             join `information_schema`.`innodb_locks` `bl` on((`bl`.`lock_id` = `w`.`blocking_lock_id`))
           )
           join `information_schema`.`innodb_locks` `rl` on((`rl`.`lock_id` = `w`.`requested_lock_id`))
         )
    order by `r`.`trx_wait_started`;

-- --switch on MySQL event scheduler

set GLOBAL EVENT_scheduler=1
 or
 <my.cnf>
 [mysqld]
 event_scheduler=1

-- --take a look at the table

select * from lock_waits

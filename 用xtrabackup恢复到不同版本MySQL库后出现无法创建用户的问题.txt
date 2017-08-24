创建用户时提示：Cannot load from MySQL.proc. The table is probably corrupted的解决办法

1.用grant方式和create user创建用户时提示：-Cannot load from MySQL.proc. The table is probably corrupted
2.但可以用insert into mysql.user values();进行添加，但密码部分可能需要实用select password()求出密码加密值后再插入。
3.需要对mysql.proc_priv表和mysql.procs表进行修复。
4.修复有三种方式：
			1.直接创建一个新的空实例，然后将没有被破坏的表文件覆盖到有问题的实力上。由于mysql库的表在5.6-5.7版本上都是myisam表。可以直接复制表文件进行修改。
			2.实用mysql_upgrade程序进行修复表结构
			  [centos:]mysql_upgrade  -ulocalhost -u root -p123
			  输出如下：
						Enter password: 
						Checking if update is needed.
						Checking server version.
						Running queries to upgrade MySQL server.
						Checking system database.
						mysql.columns_priv                                 OK
						mysql.db                                           OK
						mysql.engine_cost                                  OK
						mysql.event                                        OK
						mysql.func                                         OK
						mysql.general_log                                  OK
						mysql.gtid_executed                                OK
						mysql.help_category                                OK
						mysql.help_keyword                                 OK
						mysql.help_relation                                OK
						mysql.help_topic                                   OK
						mysql.innodb_index_stats                           OK
						mysql.innodb_table_stats                           OK
						mysql.mysql_recover                                OK
						mysql.ndb_binlog_index                             OK
						mysql.plugin                                       OK
						mysql.proc                                         OK
						mysql.procs_priv                                   OK
						mysql.proxies_priv                                 OK
						mysql.server_cost                                  OK
						mysql.servers                                      OK
						mysql.slave_master_info                            OK
						mysql.slave_relay_log_info                         OK
						mysql.slave_worker_info                            OK
						mysql.slow_log                                     OK
						mysql.tables_priv                                  OK
						mysql.time_zone                                    OK
						mysql.time_zone_leap_second                        OK
						mysql.time_zone_name                               OK
						mysql.time_zone_transition                         OK
						mysql.time_zone_transition_type                    OK
						mysql.user                                         OK
						The sys schema is already up to date (version 1.5.1).
				3.使用最矬但是对复制最友好的DML语句进行修改
				   使用show create table语句对新的空实例和旧的损坏实例进行比较，可以发现：某些字段上，新旧版本，percona和mysql官方版本的确在某些字段的长度定义上有所不同。旧版本，官方版本设定的字段长度可能相对于新版本和分支版本偏短。偏短虽然在理论上可以存放下插入的数据，但是服务器是不允许和不识别的，造成了无法插入新用户的问题出现。这就需要手工创建DML语句进行同步新旧版本的表结构。这样可以将修改同步到集群或者从库中，比较安全。
				  值得注意的是：虽然短于设定值，系统会认为表损坏。但是长于设定值，或者字段名大小写差异，系统虽然会检查到并在error log中显示出来，但会自行忽略这个错误。

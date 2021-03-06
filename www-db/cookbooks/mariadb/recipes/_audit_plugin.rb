# Prepare Configuration File
audit_plugin_options = {}

audit_plugin_options['comment1'] = '#'
audit_plugin_options['comment2'] = '# * MariaDB Audit Plugin'
audit_plugin_options['comment3'] = '#'

audit_plugin_options['server_audit_events'] = \
  node['mariadb']['audit_plugin']['server_audit_events']
audit_plugin_options['server_audit_output_type'] = \
  node['mariadb']['audit_plugin']['server_audit_output_type']
audit_plugin_options['server_audit_syslog_facility'] = \
  node['mariadb']['audit_plugin']['server_audit_syslog_facility']
audit_plugin_options['server_audit_syslog_priority'] = \
  node['mariadb']['audit_plugin']['server_audit_syslog_priority']

audit_plugin_options['enable'] = '#server_audit_logging = ON'

# Install the MariaDB Audit Plugin
mysql_cmd = mysqlbin_cmd(node['mariadb']['install']['prefer_scl_package'],
                         node['mariadb']['install']['version'],
                         'mysql')
execute 'install_mariadb_audit_plugin' do
  command "#{mysql_cmd} -e \"INSTALL PLUGIN server_audit "\
          "SONAME 'server_audit';\""
  notifies :run, 'execute[configure_mariadb_audit_plugin]', :immediately
  not_if do
    cmd = Mixlib::ShellOut.new("#{mysql_cmd} -u root -B -N -e \"SELECT 1 "\
                               'FROM information_schema.plugins '\
                               "WHERE PLUGIN_NAME = 'SERVER_AUDIT'"\
                               "AND PLUGIN_STATUS = 'ACTIVE';\"")
    cmd.run_command
    cmd.stdout.to_i == 1
  end
end

# Configure (Dynamic)
execute 'configure_mariadb_audit_plugin' do
  command 'echo "SET GLOBAL server_audit_events=\'' + \
    node['mariadb']['audit_plugin']['server_audit_events'] + '\';' \
    'SET GLOBAL server_audit_output_type=\'' + \
    node['mariadb']['audit_plugin']['server_audit_output_type'] + '\';' \
    'SET GLOBAL server_audit_syslog_facility=\'' + \
    node['mariadb']['audit_plugin']['server_audit_syslog_facility'] + '\';' \
    'SET GLOBAL server_audit_syslog_priority=\'' + \
    node['mariadb']['audit_plugin']['server_audit_syslog_priority'] + '\';"' \
    "| #{mysql_cmd}"
  action :nothing
end

# Create Configuration File
mariadb_configuration 'audit_plugin' do
  section 'mysqld'
  option audit_plugin_options
  action :add
end

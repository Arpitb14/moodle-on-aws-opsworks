db = search(:aws_opsworks_rds_db_instance, "*:*").first
thisinstance = search(:aws_opsworks_instance, "self:true").first
memcached = search(:aws_opsworks_instance, "role:moodle-web-server AND status:online").first
firstinstance = search(:aws_opsworks_instance, "role:moodle-web-server AND status:online").first
stack = search(:aws_opsworks_stack).first


# Add /srv/opsworks.php file - stores info that Moodle needs to know about other AWS resources
template 'opsworks.php' do
	path '/srv/opsworks.php'
	source 'opsworks.php.erb'
	owner 'apache'
	group 'ec2-user'
	mode '0770'
	variables(
		:db_host		=> db['address'],
		:db_user		=> db['db_user'],
		:db_pass		=> db['db_password'],
		:memcached_ip	=> memcached['private_ip']
	)
end

# Create and mount Moodledata NFS folder
directory '/mnt/nfs' do
  owner 'apache'
  group 'ec2-user'
  mode '0770'
  action :create
  recursive true
end

mount '/mnt/nfs' do
  device "#{thisinstance['availability_zone']}.#{node['EFS_ID']}.efs.#{stack['region']}.amazonaws.com:/"
  fstype 'nfs4'
  options 'rw'
  #action [:mount, :enable]
end

# manage php settings so we can modify upload limit
template 'php-5.6.ini' do
		path "/etc/php-5.6.ini"
		source "php-5.6.ini"
		owner "root"
		group "root"
		mode '0644'
end

# setup moodle cron
template '/etc/cron.d/minutely-moodle.cron' do
	# only run cron on the first webserver
	if thisinstance['instanceid'] == firstinstance['instanceid']
		source 'minutely-moodle.cron'
	else
		source 'empty'
	end		
end


# restart httpd to pickup any changes
service "httpd" do
	action :restart
end


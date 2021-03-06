if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
else

thisinstance = search(:aws_opsworks_instance, 'self:true').first
stack = search(:aws_opsworks_stack).first


mount '/mnt/nfs' do
  device "#{thisinstance['availability_zone']}.#{node['EFS_ID']}.efs.#{stack['region']}.amazonaws.com:/"
  fstype 'nfs4'
  options 'rw'
  #action [:mount, :enable]
end


end
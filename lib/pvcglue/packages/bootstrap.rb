#=======================================================================================================================
package 'bootstrap' do
#=======================================================================================================================
  depends_on 'time-zone'
  depends_on 'hostname'
  depends_on 'htop'
  depends_on 'ufw'
  depends_on 'applications_dir'
  depends_on 'authorized_keys_root'
  depends_on 'authorized_keys'
  depends_on 'sshd-config'
  depends_on 'firewall-config'
  depends_on 'firewall-enabled'
  depends_on 'unattended-security-upgrades'
end

package 'applications_dir' do
  depends_on 'deploy-user'
  validate do
    stat = run("stat --format=%U:%G:%a #{Pvcglue.configuration.web_app_base_dir}").strip
    stat == 'deploy:deploy:2755'
  end

  apply do
    dir = Pvcglue.configuration.web_app_base_dir
    # used following as a guide for next line: http://capistranorb.com/documentation/getting-started/authentication-and-authorisation/
    run "mkdir -p #{dir} && chown deploy:deploy #{dir} && umask 0002 && chmod g+s #{dir}"
  end
end

package 'deploy-user' do
  apply do
    run "mkdir -p ~/.pvc && chmod 600 ~/.pvc"
    #run 'adduser --disabled-password --gecos "" deploy'
    run "useradd -d /home/deploy -G sudo -m -U deploy"
    run "usermod -s /bin/bash deploy"
    # this next line will also append this every time this is run...which is less than ideal.  But it *should* only get run once per server due to the validate method
    run "echo 'deploy ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers" # this may be a security issue, and need refactoring, see the end of http://capistranorb.com/documentation/getting-started/authentication-and-authorisation/
  end

  remove do
    raise "removing user not supported, yet.  It needs some 'Are you *really* sure?' stuff."
    # run "userdel -f deploy"
    # run "rm -rf /home/deploy"
  end

  validate do
    sudo('getent passwd deploy') =~ /^deploy:/ &&
        sudo('groups deploy') =~ /deploy sudo/
  end


end

package 'authorized_keys' do

  file({
           :template => ::Pvcglue.template_file_name('authorized_keys.erb'),
           :destination => '/home/deploy/.ssh/authorized_keys',
           :create_dirs => true,
           :permissions => 0644,
           :user => 'deploy',
           :group => 'deploy'
       })
end

package 'authorized_keys_root' do

  file({
           :template => ::Pvcglue.template_file_name('authorized_keys.erb'),
           :destination => '/root/.ssh/authorized_keys',
           :create_dirs => true,
           :permissions => 0644,
           :user => 'root',
           :group => 'root'
       })
end

package 'sshd-config' do

  file({
           :template => Pvcglue.template_file_name('sshd_config.erb'),
           :destination => '/etc/ssh/sshd_config',
           :create_dirs => false,
           :permissions => 0644,
           :user => 'root',
           :group => 'root'
       }) { sudo('service ssh restart') }

end

apt_package 'unattended-upgrades'

package 'unattended-security-upgrades' do
  depends_on 'unattended-upgrades'
  file({
           :template => Pvcglue.template_file_name('20auto-upgrades.erb'),
           :destination => '/etc/apt/apt.conf.d/20auto-upgrades',
           :create_dirs => false,
           :permissions => 0644,
           :user => 'root',
           :group => 'root'
       }) { sudo('service unattended-upgrades restart') }
end


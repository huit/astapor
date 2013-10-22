class quickstack::hamysql::node (
  $mysql_root_password         = $quickstack::params::mysql_root_password,
  $keystone_db_password        = $quickstack::params::keystone_db_password,
  $glance_db_password          = $quickstack::params::glance_db_password,
  $nova_db_password            = $quickstack::params::nova_db_password,
  $cinder_db_password          = $quickstack::params::cinder_db_password,
  $mysql_bind_address          = '0.0.0.0',

  # TODO's:
  #  -mysql bind only on its vip, not 0.0.0.0
  #  -mysql account security
  #  -parameterize cluster member IP's
  #  -parameterize vip
) inherits quickstack::params {

    yumrepo { 'clusterlabs' :
      baseurl => "http://clusterlabs.org/64z.repo",
      enabled => 1,
      priority => 1,
      gpgcheck => 0, # since the packages (eg pcs) don't appear to be signed
    }

    package { 'mysql-server':
      ensure => installed,
    }

    package { 'MySQL-python':
      ensure => installed,
    }

    package { 'ccs' :
      ensure => installed,
    }

    class {'quickstack::hamysql::mysql::config':
      bind_address =>  $mysql_bind_address,
      require => [Package['mysql-server'],Package['MySQL-python']]
    }

    class {'pacemaker::corosync':
      cluster_name => "hamysql",
      cluster_members => "192.168.200.11 192.168.200.12 192.168.200.13 ",
      require => [Yumrepo['clusterlabs'],Package['mysql-server'],
                  Package['MySQL-python'],Package['ccs'],
                  Class['quickstack::hamysql::mysql::config']],
    }

    class {"pacemaker::resource::ip":
      ip_address => "192.168.200.50",
      group => "mygroup",
      #cidr_netmask => "24",
      #nic => "eth3",
    }

    class {"pacemaker::stonith":
      disable => true,
    }

    class {"pacemaker::resource::filesystem":
      device => "192.168.200.200:/mnt/mysql",
      directory => "/var/lib/mysql",
      fstype => "nfs",
      group => "mygroup",
      require => Class['pacemaker::resource::ip'],
    }

    class {"pacemaker::resource::mysql":
      name => "ostk-mysql",
      group => "mygroup",
      require => Class['pacemaker::resource::filesystem'],
    }

    exec {"wait-for-mysql-to-start":
      timeout => 3600,
      tries => 360,
      try_sleep => 10,
      command => "/usr/sbin/pcs status  | grep -q 'mysql-ostk-mysql.*Started' > /dev/null 2>&1",
      require => Class['pacemaker::resource::mysql'],
    }

    class {'quickstack::hamysql::mysql::rootpw':
      require => Exec['if-we-are-running-mysql'],
      root_password => $mysql_root_password,
    }

   file {"are-we-running-mysql-script":
     name => "/tmp/are-we-running-mysql.bash",
     ensure => present,
     owner => root,
     group => root,
     mode  => 777,
     content => "#!/bin/bash\n a=`/usr/sbin/pcs status | grep mysql-ostk-mysql | perl -p -e 's/^.*Started (\S*).*$/\$1/'`; b=`/usr/sbin/crm_node -n`; echo \$a; echo \$b; \ntest \$a = \$b;",
     require => Exec['wait-for-mysql-to-start'],
    }

    exec {"if-we-are-running-mysql":
      command => "/bin/touch /tmp/WE-ARE-ACTIVE",
      require => Exec['wait-for-mysql-to-start'],
      onlyif => "/tmp/are-we-running-mysql.bash",
    }

    class {'quickstack::hamysql::mysql::setup':
      keystone_db_password => $keystone_db_password,
      glance_db_password   => $glance_db_password,
      nova_db_password     => $nova_db_password,
      cinder_db_password   => $cinder_db_password,
      require              => Class['quickstack::hamysql::mysql::rootpw'],
    }
}
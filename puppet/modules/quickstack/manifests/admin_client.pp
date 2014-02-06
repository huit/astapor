class quickstack::admin_client(
  $admin_password,
  $controller_admin_host,
) {

  $clientdeps = ["python-iso8601"]
  package { $clientdeps: }

  $clientlibs = [ "python-novaclient", 
                  "python-keystoneclient", 
                  "python-glanceclient", 
                  "python-swiftclient", 
                  "python-cinderclient", 
                  "python-neutronclient", 
                  "python-heatclient" ]

  package { $clientlibs: }

  $rcadmin_content = "export OS_USERNAME=admin 
export OS_TENANT_NAME=admin   
export OS_PASSWORD=$admin_password
export OS_AUTH_URL=http://$controller_admin_host:35357/v2.0/
export PS1='[\\u@\\h \\W(keystone_admin)]\\$'
"
    
  file {"${::home_dir}/keystonerc_admin":
     ensure  => "present",
     mode => '0600',
     content => $rcadmin_content,
  }
}  
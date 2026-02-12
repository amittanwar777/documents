tomcat_dir  = '/opt/tomcat'
patch_file = '/opt/tomcat/conf/patching.txt'

if !::Dir.exist?(tomcat_dir) || ::File.exist?(patch_file)

  Xxxxxyyyzzzz 

else
  Chef::Log.info('Tomcat already installed and no patching.txt found. Skipping.')
end
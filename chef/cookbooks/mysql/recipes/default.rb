package 'mysql-server'
service 'mysql'
file '/etc/mysql/conf.d/listen.cnf' do
  content "[mysqld]\nbind-address=0.0.0.0\n"
  notifies :restart, 'service[mysql]'
end


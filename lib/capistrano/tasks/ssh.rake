desc "SSH into to an application server"
task :ssh do
  host = roles(:app).sample
  command = "exec $SHELL -l"
  puts command if fetch(:log_level) == :debug

  exec "ssh -l #{fetch(:ssh_options)[:user]} #{host.hostname} -p #{host.port || 22} -t '#{command}'"
end

desc "SSH into the cluster via csshX"
task :cssh do
  hosts = roles(:app, :worker)

  exec "csshX -l #{fetch(:ssh_options)[:user]} #{hosts.map { |h| h.hostname + ':' +  (h.port || 22).to_s}.join(' ')}"
end

desc "SSH into an application server and bring up a Rails console"
task :console do
  host = roles(:app).sample
  command = "cd ~/current && RAILS_ENV=#{fetch(:stage)} bundle exec rails c"
  puts command if fetch(:log_level) == :debug

  exec "ssh -l #{fetch(:ssh_options)[:user]} #{host.hostname} -p #{host.port || 22} -t '#{command}'"
end

desc "SSH into an application server and tail logs"
task :log do
  host = roles(:app).sample
  exec "ssh -l #{fetch(:ssh_options)[:user]} #{host.hostname} -p #{host.port || 22} -t 'tail -f ~/current/log/production.log'"
end

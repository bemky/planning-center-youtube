namespace :app do
  desc 'Start the application'
  task :start do
    on roles(:app, :worker) do
      execute "sudo systemctl start #{fetch(:application)}-app.service"
    end
  end

  desc 'Stop the application'
  task :stop do
    on roles(:app) do
      execute "sudo systemctl stop #{fetch(:application)}-app.socket"
      execute "sudo systemctl stop #{fetch(:application)}-app.service"
    end

    on roles(:worker) do
      # execute "sudo systemctl stop #{fetch(:application)}-workers.target"
    end
  end

  desc 'Restart the application'
  task :restart do
    on roles(:app, :worker) do
      execute "sudo systemctl restart #{fetch(:application)}-app.service"
    end
  end
end

after 'deploy:finished', 'app:restart'
# after 'app:start',    'start'
# after 'app:stop',     'stop'
# after 'app:restart',  'restart'

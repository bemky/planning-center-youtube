namespace :cron do
  desc 'Update crontab'
  task :clear do
    on roles(:app, :worker) do
      execute "crontab -r"
    end
  end
  task :update do
    on roles(:app, :worker) do
      execute "cd ~/current && bundle exec whenever --update-crontab"
    end
  end
end

after 'deploy:finished', 'cron:clear'
after 'deploy:finished', 'cron:update'
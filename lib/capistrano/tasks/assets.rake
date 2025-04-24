namespace :assets do

  desc "Precompile assets rsync to servers"
  task :precompile do

    on roles(:app, select: :primary) do
      within release_path do
        execute :npm, "install --production"
        execute :bundle, "exec rails assets:precompile"
      end

      # (roles(:app, :worker) - roles(:app, select: :primary)).each do |server|
      #   execute "rsync -aP -e 'ssh -o StrictHostKeyChecking=no' #{release_path}/config/manifest.json #{fetch(:application)}@#{server.hostname}:#{release_path}/config/manifest.json"
      #   execute "rsync -aP -e 'ssh -o StrictHostKeyChecking=no' #{shared_path}/public/assets/ #{fetch(:application)}@#{server.hostname}:#{shared_path}/public/assets/"
      # end
      #
      # roles(:web).each do |server|
      #   # execute "rsync -aP -e 'ssh -o StrictHostKeyChecking=no' #{shared_path}/public/assets/ #{fetch(:application)}@#{server.hostname}:#{shared_path}/public/assets/"
      # end
    end
  end

end

after 'deploy:migrate', 'assets:precompile'

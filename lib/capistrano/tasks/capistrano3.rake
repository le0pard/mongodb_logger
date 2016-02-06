namespace :load do
  task :defaults do
    set :mongodb_logger_asset_env, 'RAILS_GROUPS=assets'
    set :mongodb_logger_assets_dir, 'public/assets'
    set :mongodb_logger_assets_role, [:app]
    set :mongodb_logger_db_role, [:app]
  end
end

namespace :mongodb_logger do

  desc <<-DESC
      Run the asset precompilation rake task.
  DESC
  task :precompile do
    on roles(:mongodb_logger_assets_role) do
      execute "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{mongodb_logger_asset_env} mongodb_logger:assets:compile[#{mongodb_logger_assets_dir}]"
    end
  end

  desc <<-DESC
      Run collection migrate rake task.
  DESC
  task :migrate do
    on roles(:mongodb_logger_db_role) do
      execute "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} mongodb_logger:migrate"
    end
  end
end

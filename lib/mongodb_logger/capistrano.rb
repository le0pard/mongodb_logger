Capistrano::Configuration.instance.load do
  after 'deploy:update_code', 'mongodb_logger:precompile'
  _cset :mongodb_logger_asset_env, "RAILS_GROUPS=assets"
  _cset :mongodb_logger_assets_role, [:web]
  _cset :mongodb_logger_assets_dir, "public/assets"

  namespace :mongodb_logger do

    desc <<-DESC
      Run the asset precompilation rake task. 
    DESC
    task :precompile, :roles => mongodb_logger_assets_role, :except => { :no_release => true } do
      run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{mongodb_logger_asset_env} mongodb_logger:assets:compile[#{mongodb_logger_assets_dir}]"
    end

  end
end
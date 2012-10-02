libdir = File.dirname(__FILE__)+"/lib"
$: << libdir
confdir = File.dirname(__FILE__)+"/config"
$: << confdir

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 
end

require 'environment'
$: << GAMEBOX_PATH
load "tasks/gamebox_tasks.rake"
STATS_DIRECTORIES = [
  %w(Source            src/), 
  %w(Config            config/), 
  %w(Maps              maps/), 
  %w(Unit\ tests       specs/),
  %w(Libraries         lib/),
].collect { |name, dir| [ name, "#{APP_ROOT}/#{dir}" ] }.select { |name, dir| File.directory?(dir) }

desc "Run the game with debug server"
task :debugz do |t|
  sh "ruby src/app.rb --debug"                                         
end



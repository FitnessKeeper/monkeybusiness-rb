require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

# Warbler
require "warbler"
Warbler::Task.new

task :default => :spec

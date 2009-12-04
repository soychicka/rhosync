require 'rubygems'
require 'spec/rake/spectask'
require 'rcov/rcovtask'

task :default => :all

OPTS = { :spec_opts => %w(-fs --color), 
         :rcov      => true,
         :rcov_opts => ['--aggregate',File.join('tmp','aggregate.data'),'--exclude', 'spec/*,gems/*'] }
         
TYPES = { :spec     => 'spec/*_spec.rb',
          :perf     => 'spec/perf/*_spec.rb',
          :server   => 'spec/server/*_spec.rb'}

task :setup do
  mkdir_p 'tmp'
  rm_rf 'coverage'
end

task :cleanup do
  rm_rf 'tmp'
end

Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_files = FileList[TYPES[:spec]]
  t.spec_opts = OPTS[:spec_opts]
  t.rcov = OPTS[:rcov]
  t.rcov_opts = OPTS[:rcov_opts]
end
task :spec => :setup

Spec::Rake::SpecTask.new(:server) do |t|
  t.spec_files = FileList[TYPES[:server]]
  t.spec_opts = OPTS[:spec_opts]
  t.rcov = OPTS[:rcov]
  t.rcov_opts = OPTS[:rcov_opts]
end
task :server => :setup

Spec::Rake::SpecTask.new(:perf) do |t|
  t.spec_files = FileList[TYPES[:perf]]
  t.spec_opts = OPTS[:spec_opts]
  t.rcov = OPTS[:rcov]
  t.rcov_opts = OPTS[:rcov_opts]
end
task :perf => :setup

desc "Run all specs"
task :all => [:spec,:perf,:server,:cleanup]

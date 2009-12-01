require 'rubygems'
require 'spec/rake/spectask'
require 'rcov/rcovtask'

task :default => :spec
 
desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/*_spec.rb']
  t.spec_opts = %w(-fs --color)
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec/*,gems/*']
end

desc "Run performance specs"
Spec::Rake::SpecTask.new('spec:perf') do |t|
  t.spec_files = FileList['spec/perf/*_spec.rb']
  t.spec_opts = %w(-fs --color)
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec/*,gems/*']
end

desc "Run server specs"
Spec::Rake::SpecTask.new('spec:server') do |t|
  t.spec_files = FileList['spec/server/*_spec.rb']
  t.spec_opts = %w(-fs --color)
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec/*,gems/*']
end
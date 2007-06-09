require 'rubygems'
require 'rake'
Gem::manage_gems
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'
require 'iconv'

task :default => :spec

desc "Run the LLIP specifications"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/llip/*.rb']
	t.spec_opts = ["--diff c"]
end

desc "Run all the specifications"
Spec::Rake::SpecTask.new('spec:all') do |t|
  t.spec_files = FileList['spec/**/*.rb'] - ["specs/spec_helper.rb"]
	t.spec_opts = ["--diff c"]
end

desc "Run all the specifications and generate the output in html"
Spec::Rake::SpecTask.new('spec:html') do |t|
  t.spec_files = FileList['spec/**/*.rb'] - ["specs/spec_helper.rb"]
	t.spec_opts = ["-f html","--diff c","-o","specs.html"]
end

desc "Run all the specification with RCov support"
Spec::Rake::SpecTask.new('rcov') do |t|
  t.spec_files = FileList['spec/**/*.rb'] - ["specs/spec_helper.rb"]
	t.spec_opts = ["-c"]
	t.rcov = true
  t.rcov_opts = ['--exclude', "rcov,spec"] 
end

desc "Run all the specification and checks if the coverage is at the threshold"
RCov::VerifyTask.new(:verify_rcov => :rcov) do |t|
  t.threshold = 100.0
end

desc "Generate the rdoc documentation"
Rake::RDocTask.new(:rdoc) do |rd|
	rd.main = "README"
  rd.rdoc_files.include("README", "lib/**/*.rb")
	rd.options << "--title" 
	rd.options << 'LLIP Documentation'
end

task :commit => :verify_rcov do |t|
	exec "svn commit"
end

gem_spec = Gem::Specification.new do |s|
	s.name = "llip"
	s.version = "0.1"
	s.author = "Matteo Collina"
	s.email = "matteo.collina@gmail.com"
	s.platform = Gem::Platform::RUBY
	s.summary = "A tool for creating an LL(k) parser."
	s.files = FileList["{examples,lib,specs}/**/*"] + ["README"]
	s.autorequire = 'llip'
	s.require_paths << "lib/"
	s.has_rdoc = true
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
	pkg.need_tar = true
end

task :spec_and_build => [:spec,:repackage] do |t|
end

task :install => [:repackage] do |t|
  puts `sudo gem install pkg/#{gem_spec.name}-#{gem_spec.version}.gem`
end

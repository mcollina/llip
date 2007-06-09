require 'rake'
require 'hoe'
require 'lib/llip'
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'
require 'iconv'

Hoe.new('llip',LLIP::VERSION) do |p|
  p.author = "Matteo Collina"
  p.name = "llip"
  p.email = "matteo.collina@gmail.com"
  p.extra_deps = ["rspec",">= 1.0.0"]
  p.description = p.paragraphs_of('README.txt', 1..3).join("\n\n")
  p.summary = "LLIP is a tool to geneate a LL(k) parser."
  p.url = "http://llip.rubyforge.org"
  p.rdoc_pattern = /(^lib\/llip\/.*|.*\.txt)/
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")  
end

Rake.application["default"].prerequisites.shift

task :default => [:spec]

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
  t.rcov_opts = ['--exclude', "rcov,spec,gem"] 
end

desc "Run all the specification and checks if the coverage is at the threshold"
RCov::VerifyTask.new(:verify_rcov => :rcov) do |t|
  t.threshold = 100.0
end

desc "Creates the Manifest" 
task :create_manifest do
  files = FileList["{examples,lib,spec}/**/*"] + ["README.txt","Manifest.txt","History.txt","MIT-LICENSE","Rakefile"]
  files.sort!
  File.open("Manifest.txt", "w") do |io|
    io.write(files.join("\n"))
  end
end

task :commit => :verify_rcov do |t|
  exec "svn commit"
end

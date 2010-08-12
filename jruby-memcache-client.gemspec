# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{jruby-memcache-spy-client}
  s.version = "1.7.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Abhi Yerra", "Ikai Lan", "Frederic Jean", "Lennon Day-Reynolds", "slyphon", "Brayn Helmkamp", "Travis Tilley"]
  s.date = %q{2010-01-21}
  s.description = %q{A drop in replacement for Ruby's memcache-client.}
  s.email = %q{fred@fredjean.net}
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    ".gitignore",
     "MIT-LICENSE",
     "README",
     "Rakefile",
     "VERSION.yml",
     "jruby-memcache-client.gemspec",
     "lib/java/spy_memcached-2.5-3.jar",
     "lib/memcache.rb",
     "spec/jruby_memcache_spec.rb"
  ]
  s.homepage = %q{http://github.com/ikai/jruby-memcache-client}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A drop in replacement for Ruby's memcache-client.}
  s.test_files = [
    "spec/jruby_memcache_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end


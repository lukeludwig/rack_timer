# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rack_timer/version"

Gem::Specification.new do |s|
  s.name        = "rack_timer"
  s.version     = RackTimer::VERSION
  s.authors     = ["lukeludwig"]
  s.email       = ["luke.ludwig@tstmedia.com"]
  s.homepage    = "http://www.github.com/tstmedia/rack_timer"
  s.summary     = %q{Provides timing output around each of your Rails rack-based middleware classes.}
  s.description = %q{Provides timing output around each of your Rails rack-based middleware classes.}

  s.rubyforge_project = "rack_timer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end

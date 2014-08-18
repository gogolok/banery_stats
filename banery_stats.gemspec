Gem::Specification.new do |s|
  s.name        = 'banery_stats'
  s.version     = '0.0.1'
  s.date        = '2014-04-28'
  s.summary     = "Banery stats"
  s.description = "Simple kanbanery overview tool"
  s.authors     = ["Robert Gogolok"]
  s.email       = 'gogolok@gmail.com'
  s.executables << 'banery_stats'
  s.files       = ["lib/banery_stats.rb"]
  s.homepage    = 'https://github.com/gogolok/banery_stats'
  s.license     = 'MIT'

  s.add_runtime_dependency "activesupport", ["~> 4.1.0"]
end

Gem::Specification.new do |s|
  s.name        = 'ruby_heap_graph'
  s.version     = '0.0.0'
  s.date        = '2017-02-19'
  s.summary     = 'Exports the Ruby heap into a graph database'
  s.description = 'Provides the ability to visualise and query the relationships between objects in Ruby\'s heap by exporting the heap into a Neo4j database.'
  s.authors     = ['Joshua Fleck']
  s.email       = 'joshuafleck@gmail.com'
  s.files       = ['lib/ruby_heap_graph.rb']
  s.homepage    = 'http://rubygems.org/gems/ruby_heap_graph'
  s.license     = 'MIT'
  s.add_dependency 'neo4j', '~> 8.0'
end

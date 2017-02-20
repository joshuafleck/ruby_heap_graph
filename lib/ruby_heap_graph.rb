require 'neo4j/rake_tasks'
require 'objspace'
require 'rake'
require 'tempfile'

module RubyHeapGraph
  extend self

  def build
    return unless user_confirm?
    with_objects_file do |objects_file|
      with_relationships_file do |relationships_file|
        export_heap_to_file(objects_file, relationships_file)
        import_into_graph(objects_file, relationships_file)
      end
    end
  end

  private

  def user_confirm?
    puts "This will import the heap into a Neo4j database. If Neo4j is not installed, it will be automatically installed.\n\
WARNING: The database at #{NEO4J_DB_PATH} will be replaced with the latest heap dump.\n\
Proceed? (y/n)>"
    gets.strip.casecmp('y').zero?
  end

  def export_heap_to_file(objects_file, relationships_file)
    puts 'Exporting the heap...'
    processed_objects = 0
    ObjectSpace.each_object do |parent|
      print_progress(processed_objects)
      write_object_to_file(objects_file, parent)
      ObjectSpace.reachable_objects_from(parent).each do |reachable|
        write_relationship_to_file(relationships_file, parent, reachable)
      end
      processed_objects += 1
    end
    puts "Export complete. Exported #{processed_objects} objects."
  end

  NEO4J_BASE_PATH = 'db/neo4j/development'.freeze
  NEO4J_DB_PATH = "#{NEO4J_BASE_PATH}/data/databases/graph.db".freeze

  def import_into_graph(objects_file, relationships_file)
    puts 'Importing the heap to Neo4j...'
    Rake.application['neo4j:install'].invoke
    Rake.application['neo4j:stop'].invoke
    `rm -rf #{NEO4J_DB_PATH}`
    `#{NEO4J_BASE_PATH}/bin/neo4j-import --into #{NEO4J_DB_PATH} --id-type INTEGER --nodes:Object #{objects_file.path} --relationships:REACHABLE_FROM #{relationships_file.path} --skip-duplicate-nodes --bad-tolerance 100000`
    Rake.application['neo4j:start'].invoke
    puts 'Importing complete. View the graph at http://localhost:7474'
  end

  def with_objects_file
    Tempfile.open('objects.csv') do |objects_file|
      write_object_file_header(objects_file)
      yield objects_file
    end
  end

  def with_relationships_file
    Tempfile.open('relationships.csv') do |relationships_file|
      write_relationships_file_header(relationships_file)
      yield relationships_file
    end
  end

  def write_object_file_header(file)
    file.puts 'objectId:ID(Object),:LABEL'
  end

  def write_relationships_file_header(file)
    file.puts ':START_ID(Object),:END_ID(Object)'
  end

  def write_object_to_file(file, object)
    file.puts "#{object.object_id},Object;#{object.class.name || 'NONE'}"
  end

  def write_relationship_to_file(file, parent, reachable)
    file.puts "#{reachable.object_id},#{parent.object_id}"
  end

  def print_progress(processed_objects)
    puts "processed #{processed_objects} objects" if (processed_objects % 5000).zero?
  end
end

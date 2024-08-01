require 'csv'
require 'find'

class CsvLoader
  # Locate the CSV in the project directory and read it
  def self.load_csv(filename)
    # Regex to match the filename at the end of the current path
    csv_file_regex = /.*#{Regexp.quote(filename)}$/

    puts "Searching current directory and parent directories for #{filename}..."

    # Go two dirs up and search for the file in all subdirs
    Find.find(__dir__ + '/../..') do |path|
      # Check if path matches file
      if csv_file_regex.match?(path)
        puts "\tFound #{filename} at #{path}. Reading..."
        csv_content = File.read(path, mode: 'r:bom|utf-8')
        return CSV.parse(csv_content, headers: true)
      end
    end
    puts "ERROR: Couldn't find #{filename} anywhere."
  end
end
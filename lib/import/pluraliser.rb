# frozen_string_literal: true

module Import
  # Class to extract numerical ranges from a string input - e.g.:
  # '34, 35, 20-40' -> [{start:34, end:34},{start:35, end:35}, {start:20, end:40}]
  # Used to extract page & volume ranges from source excerpts, and also to parse
  # dates in the source CSV.
  class Pluraliser
    def self.pluralise(string)
      # Array of parts of the string that couldn't be parsed to a number or range
      failed_string_components = []

      # Successfully parsed numeric ranges
      number_ranges = []

      # TODO: make class of response instead of hash
      response = {
        failed: failed_string_components,
        ranges: number_ranges
      }

      return response unless string

      # Regex to extract numbers from a string
      num_regex = /^\s*(\d+)(?:(s)|-(\d+))?\s*$/

      # Split input string by commas, with optional whitespace either side of comma
      split = string.split /\s*,\s*/

      split.each do |current|
        match = num_regex.match current
        if match
          # Get start number (may be only component present )
          start_num_string = match[1]
          start_num = start_num_string&.to_i

          # Default end_num to same as start
          end_num = start_num

          # Decade match (1930s)
          if match[2]
            # Check decades end in 0 (1923s not valid, 1920s is)
            if start_num % 10 != 0
              failed_string_components << current
              next
            end
            end_num = start_num + 10
          end

          # Range match (1930-35)
          if match[3]
            # Get string representing the end of the range (e.g. '-35')
            end_num_partial_str = match[3]

            # Parse actual num nums from the two strings
            parsed_range = parse_num_range start_num_string, end_num_partial_str

            end_num = parsed_range[:end_num]
          end

          # TODO: class for this next range structure
          number_ranges << { start_num: start_num, end_num: end_num }
        else
          # Add string component to list of failures
          failed_string_components << current
        end
      end
      response
    end

    # For a string like '1935-48', return {start: 1935, end: 1948}
    def self.parse_num_range(start_num_string, end_num_string)
      # First step is to make a full num string for the end num. For example, -48 will be transformed to 1948.
      # To do this, we start with the start num string (e.g. 1935). We then replace the *end* of the string with
      # the characters from the end num string.

      # Get indices for the characters in the start string that will need to be replaced with the end num string
      replace_start_index = start_num_string.length - end_num_string.length
      replace_end_index = start_num_string.length

      # Duplicate the start string, which will be modified to form the end num str
      parsed_end_num_str = start_num_string.dup

      # Replace the chars at the end of the duplicated start string with those from the end num str
      parsed_end_num_str[replace_start_index..replace_end_index] = end_num_string

      # Convert both num strings to ints
      start_num = start_num_string.to_i
      end_num = parsed_end_num_str.to_i

      { start_num: start_num, end_num: end_num }
    end
  end
end

if $PROGRAM_NAME == __FILE__
  p Import::Pluraliser.pluralise '1930, 1935, 1923-32, 1920s, 1391s'
end

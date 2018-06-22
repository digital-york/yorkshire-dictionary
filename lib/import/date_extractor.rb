# frozen_string_literal: true

require_relative 'pluraliser'

module Import
  class DateExtractor
    def self.get_dates(input)
      # Initialise start/end_year
      dates = []

      is_estimate = false
      is_circa = false

      date_match = date_regex.match input
      unless date_match
        # TODO: error?
        return []
      end

      # Check estimates
      # date_hash[:estimate] 
      is_estimate = true if date_match[1] || date_match[2]

      # Check if the date is a circa date
      # date_hash[:circa]
      is_circa = true if date_match[3]

      years_string = date_match[4]

      years = Pluraliser.pluralise years_string

      if years[:error]
        # TODO: need to handle error? Does error still exist? Or is it failed now?
      end

      years[:ranges].each do |range|
        date_record = {
          circa: is_circa,
          estimate: is_estimate,
          start_year: range[:start_num],
          end_year: range[:end_num]
        }
        dates << date_record
      end

      return dates

      # # -------------------------------------------------------------

      # # Check estimates
      # estimated_date_match = date_regex_estimate.match current_string
      # if estimated_date_match
      #   current_string = estimated_date_match[1]
      #   date_hash[:estimate] = true
      # end

      # # Check if the date is a circa date
      # circa_match = date_regex_circa.match current_string
      # if circa_match
      #   current_string = circa_match[1]
      #   date_hash[:circa] = true
      # end

      # # Check if the date is a decade
      # decade_match = date_regex_decade.match current_string
      # if decade_match
      #   # Convert to range - remove trailing s, append '- ####' where #### is num+10
      #   decade_start = decade_match[1].to_i

      #   date_hash[:start_year] = decade_start
      #   date_hash[:end_year] = decade_start + 10
      # end

      # # Check if the date is a range
      # range_match = date_regex_range.match current_string
      # if range_match

      #   # Could also do something with reverse: s.reverse![0..partial.length-1]=partial.reverse
      #   start_year_str = range_match[1]
      #   end_year_partial_str = range_match[2]

      #   # Parse actual date nums from the two strings
      #   parsed_date = parse_date_range start_year_str, end_year_partial_str

      #   # Merge parsed date into date data. Will basically add in the fields from the parsed date to the data hash.
      #   date_hash.merge! parsed_date
      # end

      # # Check for a regular date
      # regular_match = date_regex_regular.match current_string
      # if regular_match
      #   start_year = regular_match[1].to_i
      #   date_hash[:start_year] = start_year
      #   date_hash[:end_year] = start_year
      # end

      # date_hash
    end

    # For a string like '1935-48', return {start: 1935, end: 1948}
    def self.parse_date_range(start_year_string, end_year_string)
      # First step is to make a full date string for the end date. For example, -48 will be transformed to 1948.
      # To do this, we start with the start date string (e.g. 1935). We then replace the *end* of the string with
      # the characters from the end date string.

      # Get indices for the characters in the start string that will need to be replaced with the end date string
      replace_start_index = start_year_string.length - end_year_string.length
      replace_end_index = start_year_string.length

      # Duplicate the start string, which will be modified to form the end date str
      parsed_end_year_str = start_year_string.dup

      # Replace the chars at the end of the duplicated start string with those from the end date str
      parsed_end_year_str[replace_start_index..replace_end_index] = end_year_string

      # Convert both date strings to ints
      start_year = start_year_string.to_i
      end_year = parsed_end_year_str.to_i

      return {start_year: start_year, end_year: end_year}
    end

    # # 4 digit date
    # def self.date_regex_regular
    #   /^(\d{4})$/
    # end

    # def self.date_regex_circa
    #   /^c\.\s*(.*)$/
    # end

    # def self.date_regex_estimate
    #   /^(?:nd\s*)?\[(.*)\]$/
    # end

    # def self.date_regex_range
    #   /^(\d{4})\s*\-\s*(\d+)$/
    # end

    # def self.date_regex_decade
    #   /^(\d{4})s$/
    # end

    # def self.valid_date_regex

    # end

    # Gets all except double hyphens, slashes and nd-ranges
    # Groups:   1:nd 2:open_square_bracket(estimate) 3:c 4:dates_text\
    # TODO: document this regex somehow
    def self.date_regex
      /^(n\.?d\.?\s?)?(?:(\[)?(c\.?)?((?:\d{4}(?:-\d+|s)?)(?:[,\s]?\d{4}(?:-\d+|s)?)*)(?:\??\])?)?$/
    end

    def self.nd_regex
      /^n\.?d\.?$/
    end
  end
end

# TEST: implement tests
# p Import::DateExtractor.get_dates 'nd [1934-1985]'
# p Import::DateExtractor.get_dates '[1934-1985]'
# p Import::DateExtractor.get_dates '[1934-85]'

# p Import::DateExtractor.get_dates '1934-5'

# p Import::DateExtractor.get_dates 'c. 1934'
# p Import::DateExtractor.get_dates 'c. 1934 - 6'

# p Import::DateExtractor.get_dates '1823'

# p Import::DateExtractor.get_dates '1990s'

# p Import::DateExtractor.get_dates ''

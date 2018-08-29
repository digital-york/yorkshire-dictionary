# frozen_string_literal: true

module Import
  class ErrorReporter
    # List of processing errors
    def initialize
      @errors = []
    end

    # Add an error message for a definition to be printed after import
    def report_error(subject, message, type)
      return if type.nil?
      @errors << {
        subject: subject,
        message: message,
        type: type
      }
    end

    def print
      @errors.each do |error|
        printf  "%-7s %-20s %s \n",
                error[:type].upcase,
                error[:subject],
                error[:message]
      end
    end
  end
end

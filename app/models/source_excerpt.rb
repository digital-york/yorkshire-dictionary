# frozen_string_literal: true

# Class to represent a reference to a specific part of a source. For example, a
# volume range, page range, or archival reference.
class SourceExcerpt < ApplicationRecord
  belongs_to :source_reference

  def excerpt_string
    if archival_ref
      archival_ref
    else
      s = StringIO.new
      if volume_start
        s << "Vol#{volume_start}"
        s << "-#{volume_end}" if volume_end && (volume_start != volume_end)
        s << ',' if page_start
      end
      if page_start
        s << "Pg#{page_start}"
        s << "-#{page_end}" if page_end && (page_end != page_start)
      end
      s.string
    end
  end
end

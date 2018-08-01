# frozen_string_literal: true

# Class to represent a reference to a specific part of a source. For example, a 
# volume range, page range, or archival reference.
class SourceExcerpt < ApplicationRecord
  belongs_to :source_reference

  def excerpt_string
    if archival_ref
      return archival_ref
    else
      s = StringIO.new
      if volume_start
        s << "vol#{volume_start}"
        if volume_end && volume_start!=volume_end
          s << "-#{volume_end}"
        end
        if page_start
          s << ","
        end
      end
      if page_start
        s << "pg#{page_start}"
        if page_end && page_end != page_start
          s << "-#{page_end}"
        end
      end
      s.string
    end
  end
end

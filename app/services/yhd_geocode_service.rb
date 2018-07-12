# frozen_string_literal: true

# See geocoder gem @ https://github.com/alexreisner/geocoder
# Set bounds to yorkshire and region to GB
# geocoded_by :name, params: { countrycode: 'gb' }
class YhdGeocodeService
  def self.geocode(place_name)
    results = geocode_results(place_name, true)
    results = geocode_results(place_name, false) if results&.empty?

    closest_result = closest_result(results)

    return nil unless closest_result

    {
      latitude: closest_result.latitude,
      longitude: closest_result.longitude
    }
  end

  class << self
    private

    def york
      { latitude: 53.95763, longitude: -1.08271 }
    end

    def service_params
      {
        google: {
          region: 'gb',
          bounds: [[54.9616, 0.72532], [52.9186, -3.05396]],
          components: 'administrative_area:yorkshire'
        },
        opencagedata: { countrycode: 'gb' }
      }
    end

    def search_term(place_name, append_yorkshire)
      if append_yorkshire
        "#{place_name}, yorkshire"
      else
        place_name
      end
    end

    def geocode_results(place_name, append_yorkshire)
      results = []
      services = %i[google opencagedata]
      services.each do |service|
        current_service_results =
          get_results_for_geocode_service(place_name, service, append_yorkshire)

        results += current_service_results

        break if append_yorkshire && service == :google && results.present?
      end
      results
    end

    def get_results_for_geocode_service(place_name, service, append_yorkshire)
      Geocoder.configure(lookup: service)
      search_term = search_term(place_name, append_yorkshire)
      Geocoder.search(search_term, params: service_params[service])
    end

    def get_distance_from_york(co_ords)
      Geocoder::Calculations.distance_between(
        [york[:latitude], york[:longitude]],
        [co_ords.latitude, co_ords.longitude]
      )
    end

    def closest_result(results)
      closest_distance = nil
      closest_result = nil

      results.each do |result|
        distance = get_distance_from_york result

        if closest_result.nil? || distance < closest_distance
          closest_distance = distance
          closest_result = result
        end
      end
      closest_result
    end
  end
end

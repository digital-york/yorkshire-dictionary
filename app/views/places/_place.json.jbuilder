json.extract! place, :id, :created_at, :updated_at, :name
json.url place_url(place)
json.json_url place_url(place, format: :json)

# app/views/places/index.json.jbuilder
json.array!(@places) do |place|
  json.extract! place, :id, :name, :address, :description
end

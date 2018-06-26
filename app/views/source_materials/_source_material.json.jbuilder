json.extract! source_material, :id, :title, :created_at, :updated_at
json.url source_material_url(source_material)
json.json_url source_material_url(source_material, format: :json)
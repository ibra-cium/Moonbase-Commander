extends SceneTree

# Tool script to resize NASA Blue Marble 5400x2700 image to 1024x512 for web performance.
# Usage:
#   & $GODOT --headless --path game --script res://../tools/resize_image.gd

func _init() -> void:
	var src_path := ProjectSettings.globalize_path("res://../../asset-packs/nasa-blue-marble/world.200401.3x5400x2700.jpg")
	var target_path := ProjectSettings.globalize_path("res://assets/textures/nasa/earth_bluemarble_jan_1024.jpg")
	
	print("Loading source image from: ", src_path)
	var img := Image.load_from_file(src_path)
	if img == null or img.is_empty():
		push_error("Failed to load source image: " + src_path)
		quit(1)
		return
	
	print("Original size: ", img.get_size())
	img.resize(1024, 512, Image.INTERPOLATE_LANCZOS)
	print("Resized size: ", img.get_size())
	
	var err := img.save_jpg(target_path, 0.9)
	if err != OK:
		push_error("Failed to save resized image: " + str(err))
		quit(1)
		return
	
	print("Successfully saved resized Earth map to: ", target_path)
	quit(0)

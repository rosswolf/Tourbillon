extends Node

enum TriggerType {
	RED,
	GREEN,
	BLUE
}

static func get_enum_name(enum_dict, enum_value) -> String:
	var keys = enum_dict.keys()
	var values = enum_dict.values()
	var index = values.find(enum_value)
	return keys[index] if index != -1 else "UNKNOWN"

var temp_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func set_seed(world_seed: int) -> void:
	temp_rng.seed = world_seed
	
func get_random_trigger_type() -> TriggerType:
	return temp_rng.randi() % TriggerType.size()

func get_engine_trigger_types() -> Array[TriggerType]:
	var activation_types: Array[TriggerType] = [
		TriggerType.GREEN, TriggerType.RED, TriggerType.BLUE]
	
	var fourth_type = temp_rng.randi() % TriggerType.size()
	
	# Ensure fifth type is different from the last one
	var fifth_type = temp_rng.randi() % TriggerType.size()
	while fifth_type == fourth_type:
		fifth_type = temp_rng.randi() % TriggerType.size()
		
	activation_types.append(fourth_type)
	activation_types.append(fifth_type)
	
	activation_types.shuffle()
	
	return activation_types


func load_image(name: String) -> Texture2D:
	return load_image_uid(UidManager.UIDS[name])

func load_slot_icon_image(name: String) -> Texture2D:
	return load_image_uid(UidManager.SLOT_ICON_UIDS[name])
		
func load_image_uid(uid: String) -> Texture2D:
	if uid == "":
		print("No UID provided when loading image")
		return
	
	var loaded_texture: Resource = load("uid://" + uid) as Texture2D
	if loaded_texture:
		return loaded_texture
	else:
		printerr("Invalid UID: %s" % uid)
		return null

# Returns an array of random numbers between 1 and 3. 
#    count = how many numbers to generate
#    target_sum = the sum of all the numbers generated must equal this	
func generate_random_numbers(count: int, target_sum: int) -> Array[int]:
	# Seed the output with these numbers to ensure we don't get something like all 2's
	var numbers: Array[int] = [1,1,2,2,3,3]	
	var excess_sum: int = target_sum - count
	
	# Validate input - minimum sum is count (all 1s), maximum is count * 3 (all 3s)
	if target_sum < count or target_sum > count * 3:
		printerr("Invalid parameters: target_sum must be between %d and %d for count %d" % [count, count * 3, count])
		return numbers
	
	var valid_combinations: Array[Array] = []
	
	# Find all valid combinations
	# z can be at most min(count, excess_sum/2) since we need y + 2z = excess_sum and y >= 0
	var max_z: int = min(count, excess_sum / 2)
	
	for z in range(0, max_z + 1):
		var y: int = excess_sum - 2 * z
		if y >= 0 and y <= count:  # y must be non-negative and not exceed count
			var x: int = count - y - z
			if x >= 0:
				valid_combinations.append([x, y, z])  # [ones, twos, threes]
	
	# Check if any valid combinations exist
	if valid_combinations.is_empty():
		printerr("No valid combinations found for count=%d, target_sum=%d" % [count, target_sum])
		return numbers
	
	# Pick a random valid combination
	var combo: Array = valid_combinations[randi() % valid_combinations.size()]
	var ones: int = combo[0]
	var twos: int = combo[1] 
	var threes: int = combo[2]
	
	# Build the array
	for i in range(ones):
		numbers.append(1)
	for i in range(twos):
		numbers.append(2)
	for i in range(threes):
		numbers.append(3)
	
	# Shuffle for randomness
	numbers.shuffle()
	
	return numbers

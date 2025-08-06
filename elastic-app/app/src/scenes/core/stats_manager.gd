extends RefCounted
class_name StatsManager

var stats: Dictionary[String, int] = {}

func _init() -> void:
	setup_stats_listeners()

# Connect to all stats signals on GlobalSignals
func setup_stats_listeners() -> void:
	# Get all signals from GlobalSignals that start with "stats_"
	for signal_info in GlobalSignals.get_signal_list():
		var signal_name = signal_info.name
		if signal_name.begins_with("stats_"):
			# Initialize stat to 0
			stats[signal_name] = 0
			
			# Connect to the signal
			GlobalSignals.connect(signal_name, _on_stat_signal.bind(signal_name))
			print("Connected to signal: ", signal_name, " -> stat: ", signal_name)

# Handle incoming stat signals
func _on_stat_signal(amount: int, signal_name: String, ) -> void:
	stats[signal_name] += amount
	#print("Stat updated: ", stat_name, " += ", amount, " (Total: ", stats[stat_name], ")")

# Print all current stats
func print_stats() -> void:
	print("=== Current Stats ===")
	for stat_name in stats:
		print("  ", stat_name, ": ", stats[stat_name])

extends SceneTree

func _init():
	print("Testing type safety fixes...")

	# Test instance_catalog
	var catalog = InstanceCatalog.new()
	print("✓ InstanceCatalog instantiated")

	# Test Effect class
	var effect = Effect.new()
	print("✓ Effect instantiated")

	# Test Gremlin (extends BeatListenerEntity)
	var gremlin = Gremlin.GremlinBuilder.new() \
		.with_name("Test Gremlin") \
		.with_hp(10) \
		.build()
	print("✓ Gremlin instantiated")

	# Test GremlinManager
	var gremlin_manager = GremlinManager.new()
	print("✓ GremlinManager instantiated")

	print("[DEBUG] All type safety fixes compile successfully!")
	quit(0)
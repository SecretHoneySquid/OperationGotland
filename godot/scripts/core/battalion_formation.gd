class_name BattalionFormation
extends RefCounted

## Returns array of 30 world positions for a battalion formation.
## Positions are calculated relative to target_position, facing toward facing direction.

static func get_positions(type: Battalion.Type, target_pos: Vector2, facing: Vector2) -> Array[Vector2]:
	var local_positions: Array[Vector2] = []

	match type:
		Battalion.Type.ASSAULT:
			local_positions = _assault_formation()
		Battalion.Type.DEFENSE:
			local_positions = _defense_formation()
		Battalion.Type.CONTROL:
			local_positions = _control_formation()
		Battalion.Type.AIR_DEFENSE:
			local_positions = _air_defense_formation()

	# Transform local positions to world positions
	return _transform_to_world(local_positions, target_pos, facing)


static func _transform_to_world(local: Array[Vector2], origin: Vector2, facing: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []

	# Calculate rotation from facing direction
	var angle := facing.angle()

	for pos in local:
		# Rotate position to face the right direction
		var rotated := pos.rotated(angle)
		result.append(origin + rotated)

	return result


static func _assault_formation() -> Array[Vector2]:
	## Assault fire team - wedge formation
	##      x           x        <- point men (front)
	##   x        x        x     <- fire team (staggered middle)
	##      x           x        <- support (rear)
	##        ─── toward enemy ───

	var positions: Array[Vector2] = []
	var spacing := GameBalance.BATTALION_FORMATION_SPACING

	# Point men (2 units) - front
	for i in range(2):
		var x := (i - 0.5) * spacing * 2.0
		positions.append(Vector2(spacing * 1.5, x))

	# Fire team middle (3 units) - staggered
	for i in range(3):
		var x := (i - 1) * spacing * 1.8
		var stagger: float = spacing * 0.3 if i % 2 == 0 else 0.0
		positions.append(Vector2(stagger, x))

	# Support rear (3 units)
	for i in range(3):
		var x := (i - 1) * spacing * 1.5
		positions.append(Vector2(-spacing * 1.5, x))

	return positions


static func _defense_formation() -> Array[Vector2]:
	## Defensive fire team - wide line formation
	##  x       x       x       x    <- front line (wide)
	##     x       x       x         <- support (staggered rear)
	##           x                   <- rear guard

	var positions: Array[Vector2] = []
	var spacing := GameBalance.BATTALION_FORMATION_SPACING * GameBalance.BATTALION_DEFENSE_WIDTH

	# Front line (4 units) - wide coverage
	for i in range(4):
		var x := (i - 1.5) * spacing * 1.5
		positions.append(Vector2(spacing, x))

	# Support line (3 units) - staggered
	for i in range(3):
		var x := (i - 1) * spacing * 1.3
		var stagger: float = spacing * 0.4 if i % 2 == 0 else 0.0
		positions.append(Vector2(-spacing * 0.5 + stagger, x))

	# Rear guard (1 unit)
	positions.append(Vector2(-spacing * 1.5, 0))

	return positions


static func _control_formation() -> Array[Vector2]:
	## Control/patrol formation - circular coverage
	## Units spread in a ring for area control

	var positions: Array[Vector2] = []
	var spread := GameBalance.BATTALION_CONTROL_SPREAD

	# Outer ring (6 units) - patrol perimeter
	for i in range(6):
		var angle := i * TAU / 6.0
		var radius := spread * 0.7
		positions.append(Vector2(cos(angle) * radius, sin(angle) * radius))

	# Inner pair (2 units) - center watch
	for i in range(2):
		var angle := (i + 0.5) * TAU / 2.0
		var radius := spread * 0.25
		positions.append(Vector2(cos(angle) * radius, sin(angle) * radius))

	return positions


static func _air_defense_formation() -> Array[Vector2]:
	## Air defense formation - clustered for overlapping fire
	##      x       x       x        <- outer security
	##         [AA] [AA]             <- AA weapons (rockets, center)
	##      x       x       x        <- close protection

	var positions: Array[Vector2] = []
	var spacing := GameBalance.BATTALION_FORMATION_SPACING

	# AA weapons center (2 units) - rocket troops
	for i in range(2):
		var x := (i - 0.5) * spacing * 0.8
		positions.append(Vector2(0, x))

	# Close protection (3 units) - inner ring
	for i in range(3):
		var angle := (i + 0.5) * TAU / 3.0
		var radius := spacing * 1.5
		positions.append(Vector2(cos(angle) * radius, sin(angle) * radius))

	# Outer security (3 units) - outer ring
	for i in range(3):
		var angle := i * TAU / 3.0
		var radius := spacing * 3.0
		positions.append(Vector2(cos(angle) * radius, sin(angle) * radius))

	return positions


## Returns positions for ghost preview (before placement)
static func get_preview_positions(type: Battalion.Type, center: Vector2, facing: Vector2) -> Array[Vector2]:
	return get_positions(type, center, facing)

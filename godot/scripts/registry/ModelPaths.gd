extends Node

## Model Paths Registry
##
## Centralized registry for all 3D model asset paths.
## Designed to be used as an autoload singleton.
##
## Usage:
##   ModelPaths.get_model("gripen")  # Returns "res://assets/models/gripen.glb"
##   ModelPaths.AIRCRAFT_GRIPEN      # Direct constant access

# =============================================================================
# AIRCRAFT MODELS
# =============================================================================

const AIRCRAFT_GRIPEN := "res://assets/models/gripen.glb"
const AIRCRAFT_F35 := "res://assets/models/f-35_lightning_ii_-_fighter_jet_-_free.glb"

# =============================================================================
# BUILDING MODELS
# =============================================================================

const BUILDING_BARRACKS := "res://assets/models/barracks.glb"
const BUILDING_FACTORY := "res://assets/models/factory.glb"
const BUILDING_AIRFIELD := "res://assets/models/airfield.glb"

# =============================================================================
# MODEL LOOKUP TABLE
# =============================================================================

const MODELS := {
	# Aircraft
	"gripen": AIRCRAFT_GRIPEN,
	"f35": AIRCRAFT_F35,
	"aircraft_gripen": AIRCRAFT_GRIPEN,
	"aircraft_f35": AIRCRAFT_F35,

	# Buildings
	"barracks": BUILDING_BARRACKS,
	"factory": BUILDING_FACTORY,
	"airfield": BUILDING_AIRFIELD,
	"building_barracks": BUILDING_BARRACKS,
	"building_factory": BUILDING_FACTORY,
	"building_airfield": BUILDING_AIRFIELD,
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Get a model path by key
## Returns the model path if found, empty string if not found
func get_model(key: String) -> String:
	return MODELS.get(key.to_lower(), "")

## Check if a model exists
func has_model(key: String) -> bool:
	return MODELS.has(key.to_lower())

## Get all available model keys
func get_model_keys() -> Array[String]:
	var keys: Array[String] = []
	keys.assign(MODELS.keys())
	return keys

## Get all aircraft model paths
func get_aircraft_models() -> Array[String]:
	return [AIRCRAFT_GRIPEN, AIRCRAFT_F35]

## Get all building model paths
func get_building_models() -> Array[String]:
	return [BUILDING_BARRACKS, BUILDING_FACTORY, BUILDING_AIRFIELD]

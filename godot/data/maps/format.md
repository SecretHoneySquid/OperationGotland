# Map Data Format (JSON)

This format defines a 2D RTS map for the prototype.

## Fields
- name: string (unique id)
- size: object with width/height (world units)
- start_positions: list of player start points
- build_zones: list of rectangles per player
- resource_nodes: list of supply nodes with an amount
- rally_targets: optional list of default push points

## Example
```
{
  "name": "test_map_01",
  "size": { "width": 2000, "height": 1200 },
  "start_positions": [
	{ "id": "p1", "x": 200, "y": 600 },
	{ "id": "p2", "x": 1800, "y": 600 }
  ],
  "build_zones": [
	{ "id": "p1", "x": 50, "y": 350, "width": 600, "height": 500 },
	{ "id": "p2", "x": 1350, "y": 350, "width": 600, "height": 500 }
  ],
  "resource_nodes": [
	{ "id": "supply_a", "x": 400, "y": 200, "amount": 5000 },
	{ "id": "supply_b", "x": 1600, "y": 1000, "amount": 5000 }
  ],
  "rally_targets": [
	{ "id": "p1_push", "x": 900, "y": 600 },
	{ "id": "p2_push", "x": 1100, "y": 600 }
  ]
}
```

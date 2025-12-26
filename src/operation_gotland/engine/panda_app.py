"""Panda3D bootstrapper for the Command & Conquer-style presentation."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

from operation_gotland.simulation.runtime import SimulationRuntime


@dataclass
class Sortie:
    node: "NodePath"
    side: str
    progress: float
    speed: float


class CncPandaApplication:
    """
    Thin wrapper around Panda3D that owns the render loop and bridges it to the
    simulation runtime. Importing Panda3D is deferred to runtime so the
    headless flow keeps working without the dependency installed.
    """

    def __init__(self, runtime: SimulationRuntime) -> None:
        self.runtime = runtime
        self._engine: Optional["ShowBase"] = None
        self._world: Optional["NodePath"] = None
        self._frontline_zone_p1: Optional["NodePath"] = None
        self._frontline_zone_p2: Optional["NodePath"] = None
        self._frontline_center: Optional["NodePath"] = None
        self._objective_nodes: List["NodePath"] = []
        self._unit_markers: Dict[str, Dict[str, List["NodePath"]]] = {}
        self._structure_nodes: Dict[str, Dict[str, List["NodePath"]]] = {}
        self._structure_labels: Dict[str, Dict[str, List["OnscreenText"]]] = {}
        self._sorties: List[Sortie] = []
        self._ui_text: Optional["OnscreenText"] = None
        self._info_text: Optional["OnscreenText"] = None
        self._upgrade_button: Optional["DirectButton"] = None
        self._stealth_button: Optional["DirectButton"] = None
        self._build_buttons: List["DirectButton"] = []
        self._side_button: Optional["DirectButton"] = None
        self._build_side: str = "p1"
        self._selected_asset: Optional[Dict[str, str]] = None
        self._factory_names = {
            "infantry_factory": "Infantry",
            "armor_factory": "Armor",
            "air_factory": "Air",
            "heli_factory": "Heli",
            "defense_factory": "Defense",
            "income": "Income",
            "logistics_hub": "Logistics",
            "def_arms": "AA-Inf",
            "def_vehicle": "AA-Arm",
            "def_air": "AA-Air",
        }
        self._factory_colors = {
            "infantry_factory": (0.22, 0.46, 0.28, 1.0),
            "armor_factory": (0.22, 0.32, 0.54, 1.0),
            "air_factory": (0.58, 0.56, 0.18, 1.0),
            "heli_factory": (0.35, 0.52, 0.32, 1.0),
            "defense_factory": (0.58, 0.28, 0.26, 1.0),
            "income": (0.34, 0.34, 0.34, 1.0),
            "logistics_hub": (0.28, 0.4, 0.4, 1.0),
            "def_arms": (0.4, 0.32, 0.18, 1.0),
            "def_vehicle": (0.4, 0.22, 0.32, 1.0),
            "def_air": (0.18, 0.3, 0.42, 1.0),
        }
        self._picker: Optional["CollisionTraverser"] = None
        self._picker_queue: Optional["CollisionHandlerQueue"] = None
        self._picker_ray: Optional["CollisionRay"] = None
        self._key_state: Dict[str, bool] = {"left": False, "right": False, "up": False, "down": False}
        self._camera_center = None
        self._camera_height = 260.0
        self._camera_pitch = -38.0
        self._map_length = 2000.0
        self._map_width = 700.0
        self._tick_accumulator = 0.0
        self._tick_interval = 1.0
        self._mouse_dragging = False
        self._last_mouse_pos = None
        self._ui_right_start = 0.0
        self._ui_bottom_end = 0.0

    def boot(self) -> None:
        from direct.showbase.ShowBase import ShowBase  # type: ignore
        from panda3d.core import WindowProperties, load_prc_file_data  # type: ignore

        load_prc_file_data("", "window-title Operation Gotland - Massive Front")
        self._engine = ShowBase()
        props = WindowProperties()
        props.setSize(1600, 900)
        self._engine.win.request_properties(props)
        self._engine.disable_mouse()
        self._engine.task_mgr.add(self._advance_simulation, "advance-simulation")
        self._engine.task_mgr.add(self._update_camera, "update-camera")
        self._build_scene()
        self._engine.run()

    def _build_scene(self) -> None:
        assert self._engine is not None
        from direct.gui.DirectGui import DirectButton, DirectFrame, DirectLabel, OnscreenText  # type: ignore
        from panda3d.core import (  # type: ignore
            CardMaker,
            CollisionHandlerQueue,
            CollisionNode,
            CollisionRay,
            CollisionTraverser,
            LPoint3f,
            NodePath,
            TextNode,
        )

        render = self._engine.render
        render.setShaderAuto()  # type: ignore[attr-defined]
        render.setDepthTest(True)
        render.setDepthWrite(True)
        render.setAntialias(True)

        self._world = render.attachNewNode("world")
        self._camera_center = LPoint3f(0.0, 0.0, 0.0)

        base = self._engine  # type: ignore[assignment]
        base.setBackgroundColor(0.04, 0.06, 0.07)

        terrain = CardMaker("terrain")
        terrain.setFrame(-self._map_length / 2, self._map_length / 2, -self._map_width / 2, self._map_width / 2)
        terrain_np = self._world.attachNewNode(terrain.generate())
        terrain_np.setP(-90)
        terrain_np.setColor(0.12, 0.16, 0.12, 1.0)

        grid = self._build_grid(step=100.0, color=(0.08, 0.12, 0.09, 1.0))
        grid.reparentTo(self._world)
        grid.setZ(0.1)

        self._frontline_zone_p2 = self._build_frontline_band(color=(0.7, 0.2, 0.15, 0.25))
        self._frontline_zone_p2.reparentTo(self._world)
        self._frontline_zone_p1 = self._build_frontline_band(color=(0.15, 0.35, 0.7, 0.25))
        self._frontline_zone_p1.reparentTo(self._world)
        self._frontline_center = self._build_frontline_band(color=(0.9, 0.9, 0.9, 0.4), width=12.0)
        self._frontline_center.reparentTo(self._world)

        self._build_bases()
        self._build_objectives()
        self._build_unit_markers()
        self._build_sorties()
        self._build_ui_panels()

        self._ui_text = OnscreenText(
            text="",
            pos=(-1.28, -0.86),
            scale=0.042,
            fg=(0.9, 0.92, 0.95, 1.0),
            align=TextNode.ALeft,
            parent=base.aspect2d,
        )
        self._info_text = OnscreenText(
            text="",
            pos=(self._ui_right_start + 0.06, 0.72),
            scale=0.038,
            fg=(0.9, 0.92, 0.95, 1.0),
            align=TextNode.ALeft,
            parent=base.aspect2d,
            mayChange=True,
        )
        OnscreenText(
            text="P1 WEST",
            pos=(-1.28, 0.92),
            scale=0.05,
            fg=(0.4, 0.7, 0.95, 1.0),
            align=TextNode.ALeft,
            parent=base.aspect2d,
        )
        OnscreenText(
            text="P2 EAST",
            pos=(0.6, 0.92),
            scale=0.05,
            fg=(0.95, 0.6, 0.35, 1.0),
            align=TextNode.ALeft,
            parent=base.aspect2d,
        )
        self._upgrade_button = DirectButton(
            text="Upgrade Tech",
            scale=0.052,
            pos=(self._ui_right_start + 0.2, 0, 0.26),
            command=self._handle_upgrade_click,
            parent=base.aspect2d,
        )
        self._upgrade_button.hide()
        self._stealth_button = DirectButton(
            text="Upgrade Stealth",
            scale=0.052,
            pos=(self._ui_right_start + 0.2, 0, 0.14),
            command=self._handle_stealth_click,
            parent=base.aspect2d,
        )
        self._stealth_button.hide()

        build_label = DirectLabel(
            text="Build",
            scale=0.055,
            pos=(self._ui_right_start + 0.12, 0, 0.0),
            text_fg=(0.9, 0.92, 0.95, 1.0),
            frameColor=(0, 0, 0, 0),
            parent=base.aspect2d,
        )
        self._side_button = DirectButton(
            text=f"Side: {self._build_side.upper()}",
            scale=0.042,
            pos=(self._ui_right_start + 0.2, 0, -0.08),
            command=self._toggle_side,
            parent=base.aspect2d,
        )
        self._build_buttons = []
        build_items = [
            ("Infantry Factory", "infantry_factory"),
            ("Armor Factory", "armor_factory"),
            ("Air Factory", "air_factory"),
            ("Heli Factory", "heli_factory"),
            ("Defense Factory", "defense_factory"),
            ("Income", "income"),
            ("Logistics", "logistics_hub"),
        ]
        for idx, (label, key) in enumerate(build_items):
            button = DirectButton(
                text=label,
                scale=0.042,
                pos=(self._ui_right_start + 0.2, 0, -0.18 - idx * 0.08),
                command=self._handle_build_button,
                extraArgs=[key],
                parent=base.aspect2d,
            )
            self._build_buttons.append(button)

        self._picker = CollisionTraverser()
        self._picker_queue = CollisionHandlerQueue()
        self._picker_ray = CollisionRay()
        picker_node = CollisionNode("mouseRay")
        picker_node.addSolid(self._picker_ray)
        picker_np = base.camera.attachNewNode(picker_node)
        self._picker.addCollider(picker_np, self._picker_queue)

        self._setup_controls()

    def _build_grid(self, step: float, color: Tuple[float, float, float, float]) -> "NodePath":
        from panda3d.core import LineSegs, NodePath  # type: ignore

        lines = LineSegs("grid")
        lines.setThickness(1.2)
        lines.setColor(*color)
        half_len = self._map_length / 2
        half_wid = self._map_width / 2
        x = -half_len
        while x <= half_len:
            lines.moveTo(x, -half_wid, 0)
            lines.drawTo(x, half_wid, 0)
            x += step
        y = -half_wid
        while y <= half_wid:
            lines.moveTo(-half_len, y, 0)
            lines.drawTo(half_len, y, 0)
            y += step
        return NodePath(lines.create())

    def _build_frontline_band(self, color: Tuple[float, float, float, float], width: float = 2000.0) -> "NodePath":
        from panda3d.core import CardMaker, NodePath  # type: ignore

        band = CardMaker("frontline")
        band.setFrame(-width / 2, width / 2, -self._map_width / 2, self._map_width / 2)
        node = band.generate()
        np = NodePath(node)
        np.setP(-90)
        np.setColor(*color)
        np.setTransparency(True)
        return np

    def _build_bases(self) -> None:
        assert self._world is not None
        p1_base = self._world.attachNewNode("base_p1")
        p2_base = self._world.attachNewNode("base_p2")
        p1_base.setPos(-self._map_length / 2 + 180, 0, 0)
        p2_base.setPos(self._map_length / 2 - 180, 0, 0)

        for idx in range(8):
            offset = (idx % 4) * 26 - 38
            row = (idx // 4) * 32 - 16
            self._spawn_box(p1_base, (offset, row, 0), (20, 20, 14), (0.22, 0.25, 0.3, 1))
            self._spawn_box(p2_base, (offset, row, 0), (20, 20, 14), (0.3, 0.22, 0.2, 1))

        self._spawn_runway(p1_base, (-40, -70, 0))
        self._spawn_runway(p2_base, (40, 70, 0))

        label_p1 = self._spawn_label(p1_base, "P1 WEST")
        label_p1.setZ(38)
        label_p2 = self._spawn_label(p2_base, "P2 EAST")
        label_p2.setZ(38)

        structure_slots = [
            ("infantry_factory", (70, -20, 0)),
            ("armor_factory", (70, 20, 0)),
            ("air_factory", (40, -40, 0)),
            ("heli_factory", (40, 40, 0)),
            ("defense_factory", (10, 0, 0)),
            ("income", (-20, -40, 0)),
            ("logistics_hub", (-20, 40, 0)),
            ("def_arms", (-50, -20, 0)),
            ("def_vehicle", (-50, 20, 0)),
            ("def_air", (-80, 0, 0)),
        ]
        self._structure_nodes = {"p1": {}, "p2": {}}
        self._structure_labels = {"p1": {}, "p2": {}}
        for side, base, side_color in (
            ("p1", p1_base, (0.22, 0.52, 0.9, 1.0)),
            ("p2", p2_base, (0.9, 0.45, 0.2, 1.0)),
        ):
            for key, pos in structure_slots:
                nodes: List["NodePath"] = []
                labels: List["OnscreenText"] = []
                color = self._factory_colors.get(key, side_color)
                label_text = self._factory_names.get(key, key)
                for idx in range(3):
                    node = base.attachNewNode(f"{side}_{key}_{idx}")
                    node.setTag("asset_type", "structure")
                    node.setTag("asset_key", key)
                    node.setTag("asset_side", side)
                    node.setTag("asset_index", str(idx))
                    self._spawn_pad(node, (0, 0, 0), 20, (0.08, 0.1, 0.12, 1.0))
                    self._spawn_box(node, (0, 0, 0), (28, 28, 18), color, collidable=True)
                    node.setPos(pos[0] + idx * 28, pos[1], pos[2])
                    nodes.append(node)
                    label = self._spawn_label(node, label_text)
                    labels.append(label)
                self._structure_nodes[side].setdefault(key, []).extend(nodes)
                self._structure_labels[side].setdefault(key, []).extend(labels)

    def _spawn_runway(self, parent: "NodePath", pos: Tuple[float, float, float]) -> None:
        from panda3d.core import CardMaker  # type: ignore

        runway = CardMaker("runway")
        runway.setFrame(-45, 45, -10, 10)
        runway_np = parent.attachNewNode(runway.generate())
        runway_np.setPos(*pos)
        runway_np.setP(-90)
        runway_np.setColor(0.15, 0.15, 0.17, 1)

    def _spawn_pad(self, parent: "NodePath", pos: Tuple[float, float, float], size: float, color) -> None:
        from panda3d.core import CardMaker  # type: ignore

        pad = CardMaker("pad")
        pad.setFrame(-size, size, -size, size)
        pad_np = parent.attachNewNode(pad.generate())
        pad_np.setPos(*pos)
        pad_np.setP(-90)
        pad_np.setColor(*color)

    def _spawn_label(self, parent: "NodePath", text: str) -> "OnscreenText":
        from direct.gui.DirectGui import OnscreenText  # type: ignore
        from panda3d.core import TextNode  # type: ignore

        label = OnscreenText(
            text=text,
            pos=(0, 0),
            scale=12,
            fg=(0.85, 0.88, 0.92, 1.0),
            align=TextNode.ACenter,
            parent=parent,
            mayChange=True,
        )
        label.setZ(22)
        return label

    def _spawn_box(
        self,
        parent: "NodePath",
        pos: Tuple[float, float, float],
        size: Tuple[float, float, float],
        color: Tuple[float, float, float, float],
        collidable: bool = False,
    ) -> None:
        from panda3d.core import (  # type: ignore
            CollisionBox,
            CollisionNode,
            Geom,
            GeomNode,
            GeomTriangles,
            GeomVertexData,
            GeomVertexFormat,
            GeomVertexWriter,
            LPoint3f,
        )

        fmt = GeomVertexFormat.getV3n3c4()
        vdata = GeomVertexData("box", fmt, Geom.UHStatic)
        vertex = GeomVertexWriter(vdata, "vertex")
        normal = GeomVertexWriter(vdata, "normal")
        color_writer = GeomVertexWriter(vdata, "color")

        sx, sy, sz = size
        hx, hy, hz = sx / 2, sy / 2, sz
        vertices = [
            (-hx, -hy, 0), (hx, -hy, 0), (hx, hy, 0), (-hx, hy, 0),
            (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz),
        ]
        faces = [
            (0, 1, 2, 3, (0, 0, -1)),
            (4, 5, 6, 7, (0, 0, 1)),
            (0, 1, 5, 4, (0, -1, 0)),
            (2, 3, 7, 6, (0, 1, 0)),
            (1, 2, 6, 5, (1, 0, 0)),
            (3, 0, 4, 7, (-1, 0, 0)),
        ]
        for face in faces:
            for idx in face[:4]:
                x, y, z = vertices[idx]
                vertex.addData3(x, y, z)
                normal.addData3(*face[4])
                color_writer.addData4f(*color)

        tris = GeomTriangles(Geom.UHStatic)
        for i in range(0, 24, 4):
            tris.addVertices(i, i + 1, i + 2)
            tris.addVertices(i, i + 2, i + 3)
        geom = Geom(vdata)
        geom.addPrimitive(tris)
        node = GeomNode("box")
        node.addGeom(geom)
        np = parent.attachNewNode(node)
        np.setPos(*pos)
        if collidable:
            cnode = CollisionNode("box-collider")
            cnode.addSolid(CollisionBox(LPoint3f(0, 0, 0), sx / 2, sy / 2, hz))
            collider = np.attachNewNode(cnode)
            collider.setTag("asset_type", parent.getTag("asset_type") or "")
            collider.setTag("asset_key", parent.getTag("asset_key") or "")
            collider.setTag("asset_side", parent.getTag("asset_side") or "")
            collider.setTag("asset_index", parent.getTag("asset_index") or "")

    def _build_objectives(self) -> None:
        from panda3d.core import NodePath  # type: ignore

        assert self._world is not None
        for obj in self.runtime.state.objectives:
            marker = self._world.attachNewNode("objective")
            marker.setPos(self._map_pos(obj.position), 0, 0)
            self._spawn_box(marker, (0, 0, 0), (10, 10, 30), (0.35, 0.35, 0.4, 1))
            self._objective_nodes.append(marker)

    def _build_unit_markers(self) -> None:
        assert self._world is not None
        self._unit_markers = {"p1": {}, "p2": {}}
        classes = ("infantry", "ifv", "tank", "helicopter", "aircraft", "def_arms", "def_vehicle", "def_air")
        for side in ("p1", "p2"):
            for unit in classes:
                nodes: List["NodePath"] = []
                for idx in range(18):
                    marker = self._world.attachNewNode(f"{side}_{unit}_{idx}")
                    self._spawn_box(marker, (0, 0, 0), (6, 6, 6), self._unit_color(side, unit))
                    nodes.append(marker)
                self._unit_markers[side][unit] = nodes

    def _build_sorties(self) -> None:
        assert self._world is not None
        self._sorties = []
        for side in ("p1", "p2"):
            color = (0.6, 0.8, 1.0, 1.0) if side == "p1" else (1.0, 0.6, 0.4, 1.0)
            for idx in range(6):
                node = self._world.attachNewNode(f"sortie_{side}_{idx}")
                self._spawn_box(node, (0, 0, 0), (6, 10, 3), color)
                self._sorties.append(Sortie(node=node, side=side, progress=idx / 6, speed=0.04 + idx * 0.004))

    def _build_ui_panels(self) -> None:
        from direct.gui.DirectGui import DirectFrame  # type: ignore

        assert self._engine is not None
        aspect = self._engine.getAspectRatio()
        self._ui_right_start = aspect * (1.0 - 0.2)
        self._ui_bottom_end = -1.0 + 0.2 * 2.0
        DirectFrame(
            frameColor=(0.08, 0.1, 0.12, 0.94),
            frameSize=(self._ui_right_start, aspect, -1.0, 1.0),
            parent=self._engine.aspect2d,
        )
        DirectFrame(
            frameColor=(0.1, 0.12, 0.14, 0.94),
            frameSize=(-aspect, aspect, -1.0, self._ui_bottom_end),
            parent=self._engine.aspect2d,
        )

    def _setup_controls(self) -> None:
        assert self._engine is not None
        base = self._engine
        base.accept("arrow_left", self._set_key, ["left", True])
        base.accept("arrow_left-up", self._set_key, ["left", False])
        base.accept("arrow_right", self._set_key, ["right", True])
        base.accept("arrow_right-up", self._set_key, ["right", False])
        base.accept("arrow_up", self._set_key, ["up", True])
        base.accept("arrow_up-up", self._set_key, ["up", False])
        base.accept("arrow_down", self._set_key, ["down", True])
        base.accept("arrow_down-up", self._set_key, ["down", False])
        base.accept("w", self._set_key, ["up", True])
        base.accept("w-up", self._set_key, ["up", False])
        base.accept("s", self._set_key, ["down", True])
        base.accept("s-up", self._set_key, ["down", False])
        base.accept("a", self._set_key, ["left", True])
        base.accept("a-up", self._set_key, ["left", False])
        base.accept("d", self._set_key, ["right", True])
        base.accept("d-up", self._set_key, ["right", False])
        base.accept("wheel_up", self._adjust_zoom, [1])
        base.accept("wheel_down", self._adjust_zoom, [-1])
        base.accept("mouse1", self._handle_click)
        base.accept("mouse3", self._start_drag)
        base.accept("mouse3-up", self._stop_drag)

    def _set_key(self, key: str, value: bool) -> None:
        self._key_state[key] = value

    def _adjust_zoom(self, direction: int) -> None:
        self._camera_height = max(70.0, min(520.0, self._camera_height - direction * 20))

    def _advance_simulation(self, task: "Task") -> int:
        """Advance the simulation and allow Panda3D to continue its task chain."""
        assert self._engine is not None
        dt = self._engine.clock.dt
        self._tick_accumulator += dt
        while self._tick_accumulator >= self._tick_interval:
            self.runtime.tick()
            self._tick_accumulator -= self._tick_interval
        self._update_world()
        return task.cont

    def _update_world(self) -> None:
        if not self._frontline_center:
            return
        front = self.runtime.state.frontline
        front_x = self._map_pos(front.position)
        if self._frontline_center:
            self._frontline_center.setX(front_x)
        if self._frontline_zone_p1:
            p1_width = self._map_length / 2 - front_x
            self._frontline_zone_p1.setX(front_x + p1_width / 2)
            self._frontline_zone_p1.setScale(p1_width / self._map_length, 1.0, 1.0)
        if self._frontline_zone_p2:
            p2_width = front_x + self._map_length / 2
            self._frontline_zone_p2.setX(-self._map_length / 2 + p2_width / 2)
            self._frontline_zone_p2.setScale(p2_width / self._map_length, 1.0, 1.0)

        self._update_objectives()
        self._update_structures()
        self._update_unit_markers()
        self._update_sorties()
        self._update_ui()

    def _update_objectives(self) -> None:
        for marker, obj in zip(self._objective_nodes, self.runtime.state.objectives):
            if obj.owner == self.runtime.state.player1.name:
                marker.setColor(0.2, 0.5, 0.8, 1)
            elif obj.owner == self.runtime.state.player2.name:
                marker.setColor(0.8, 0.35, 0.2, 1)
            else:
                marker.setColor(0.35, 0.35, 0.4, 1)

    def _update_unit_markers(self) -> None:
        front_x = self._map_pos(self.runtime.state.frontline.position)
        band = 120.0
        spacing = self._map_width / 12
        for side_key, player in (("p1", self.runtime.state.player1), ("p2", self.runtime.state.player2)):
            direction = -1 if side_key == "p1" else 1
            for unit_key, nodes in self._unit_markers[side_key].items():
                count = getattr(player.units, unit_key, 0.0) if hasattr(player.units, unit_key) else 0.0
                desired = max(1, min(len(nodes), int(count / 12) + 1))
                tier = player.unit_tiers.get(unit_key, 0)
                for idx, node in enumerate(nodes):
                    node.setColorScale(1, 1, 1, 1)
                    if idx < desired:
                        row = idx % 6
                        col = idx // 6
                        node.setPos(
                            front_x + direction * (25 + col * 18),
                            (row - 2.5) * spacing + (col * 4 * direction),
                            2.0,
                        )
                        node.setScale(1.6 + tier * 0.25)
                        node.show()
                    else:
                        node.hide()

    def _update_sorties(self) -> None:
        front_x = self._map_pos(self.runtime.state.frontline.position)
        p1_start = -self._map_length / 2 + 160
        p2_start = self._map_length / 2 - 160
        for sortie in self._sorties:
            sortie.progress = (sortie.progress + sortie.speed * 0.01) % 1.0
            leg = abs(0.5 - sortie.progress) * 2.0
            if sortie.side == "p1":
                x0, x1 = p1_start, front_x
                x = x1 + (x0 - x1) * leg
                y = -180 + (sortie.progress * 360)
            else:
                x0, x1 = p2_start, front_x
                x = x1 + (x0 - x1) * leg
                y = 180 - (sortie.progress * 360)
            z = 80 + 30 * (1.0 - leg)
            sortie.node.setPos(x, y, z)

    def _update_ui(self) -> None:
        if not self._ui_text:
            return
        state = self.runtime.state
        text = (
            f"Tick {state.tick} | Front {state.frontline.ratio(state.settings):.1f}%\n"
            f"P1 Credits {state.player1.credits} | Logi {state.player1.logistics_health:.0f} | Air {state.player1.air_posture}\n"
            f"P2 Credits {state.player2.credits} | Logi {state.player2.logistics_health:.0f} | Air {state.player2.air_posture}\n"
            f"Escalation {state.escalation:.1f}"
        )
        self._ui_text.setText(text)
        if self._info_text is not None:
            self._info_text.setText(self._selection_text())
        self._update_buttons()

    def _update_camera(self, task: "Task") -> int:
        if not self._engine or self._camera_center is None:
            return task.cont
        dt = self._engine.clock.dt
        speed = 240 * dt
        self._update_drag()
        if self._key_state["left"]:
            self._camera_center.x -= speed
        if self._key_state["right"]:
            self._camera_center.x += speed
        if self._key_state["up"]:
            self._camera_center.y += speed
        if self._key_state["down"]:
            self._camera_center.y -= speed
        half_len = self._map_length / 2 - 100
        half_wid = self._map_width / 2 - 80
        self._camera_center.x = max(-half_len, min(half_len, self._camera_center.x))
        self._camera_center.y = max(-half_wid, min(half_wid, self._camera_center.y))

        cam = self._engine.camera
        cam.setPos(self._camera_center.x, self._camera_center.y - 220, self._camera_height)
        cam.setHpr(0, self._camera_pitch, 0)
        return task.cont

    def _update_structures(self) -> None:
        for side_key, player in (("p1", self.runtime.state.player1), ("p2", self.runtime.state.player2)):
            for key, nodes in self._structure_nodes.get(side_key, {}).items():
                built = player.structures.get(key, 0)
                for idx, node in enumerate(nodes):
                    if idx < built:
                        node.setColorScale(1, 1, 1, 1)
                        node.show()
                    else:
                        node.setColorScale(0.4, 0.4, 0.4, 0.6)
                        node.show()
                labels = self._structure_labels.get(side_key, {}).get(key, [])
                for idx, label in enumerate(labels):
                    if idx < built:
                        label.setColor(0.95, 0.95, 1.0, 1.0)
                    else:
                        label.setColor(0.5, 0.5, 0.5, 1.0)
        self._highlight_selection()

    def _handle_click(self) -> None:
        if not self._engine or not self._picker or not self._picker_queue or not self._picker_ray:
            return
        if not self._engine.mouseWatcherNode.hasMouse():
            return
        mouse = self._engine.mouseWatcherNode.getMouse()
        self._picker_ray.setFromLens(self._engine.camNode, mouse.getX(), mouse.getY())
        self._picker.traverse(self._engine.render)
        if self._picker_queue.getNumEntries() == 0:
            self._selected_asset = None
            return
        self._picker_queue.sortEntries()
        hit = self._picker_queue.getEntry(0)
        node = hit.getIntoNodePath()
        asset_node = node.findNetTag("asset_type")
        if asset_node.isEmpty():
            self._selected_asset = None
            return
        asset_key = asset_node.getTag("asset_key")
        asset_side = asset_node.getTag("asset_side")
        asset_index = asset_node.getTag("asset_index")
        self._selected_asset = {"key": asset_key, "side": asset_side, "index": asset_index}
        self._highlight_selection()
        self._attempt_build(asset_key, asset_side, int(asset_index))

    def _attempt_build(self, asset_key: str, side: str, index: int) -> None:
        player = self.runtime.state.player1 if side == "p1" else self.runtime.state.player2
        if player.structures.get(asset_key, 0) > index:
            return
        try:
            self.runtime.queue_structure(side, asset_key, 1)
            self._pulse_build_slot(side, asset_key, index)
        except ValueError:
            return

    def _handle_upgrade_click(self) -> None:
        if not self._selected_asset:
            return
        key = self._selected_asset["key"]
        side = self._selected_asset["side"]
        factory_key = self._factory_key_from_structure(key)
        if not factory_key:
            return
        try:
            self.runtime.upgrade_factory(side, factory_key)
        except ValueError:
            return

    def _handle_stealth_click(self) -> None:
        if not self._selected_asset:
            return
        key = self._selected_asset["key"]
        side = self._selected_asset["side"]
        if key != "air_factory":
            return
        try:
            self.runtime.upgrade_stealth(side)
        except ValueError:
            return

    def _selection_text(self) -> str:
        if not self._selected_asset:
            return "Select a structure to view upgrades."
        key = self._selected_asset["key"]
        side = self._selected_asset["side"]
        player = self.runtime.state.player1 if side == "p1" else self.runtime.state.player2
        lines = [f"{player.name} - {self._factory_names.get(key, key)}"]
        if key.endswith("_factory"):
            factory_key = self._factory_key_from_structure(key)
            tier = player.tech_levels.get(factory_key, 0) + 1
            lines.append(f"Tech tier: {tier}")
            cost = self._next_factory_cost(player, factory_key)
            if cost:
                lines.append(f"Upgrade cost: {cost}")
        if key == "air_factory":
            lines.append(f"Stealth tier: {player.air_stealth_level + 1}")
            cost = self._next_stealth_cost(player)
            if cost:
                lines.append(f"Stealth cost: {cost}")
        if key == "defense_factory":
            lines.append(f"Defense range: {player.defense_range_tier + 1}")
        return "\n".join(lines)

    def _update_buttons(self) -> None:
        if not self._upgrade_button or not self._stealth_button:
            return
        if not self._selected_asset:
            self._upgrade_button.hide()
            self._stealth_button.hide()
            return
        key = self._selected_asset["key"]
        if key.endswith("_factory"):
            self._upgrade_button.show()
        else:
            self._upgrade_button.hide()
        if key == "air_factory":
            self._stealth_button.show()
        else:
            self._stealth_button.hide()

    def _highlight_selection(self) -> None:
        for side_nodes in self._structure_nodes.values():
            for nodes in side_nodes.values():
                for node in nodes:
                    node.setColorScale(1, 1, 1, 1)
        if not self._selected_asset:
            return
        side = self._selected_asset["side"]
        key = self._selected_asset["key"]
        index = int(self._selected_asset["index"])
        nodes = self._structure_nodes.get(side, {}).get(key, [])
        if 0 <= index < len(nodes):
            nodes[index].setColorScale(1.3, 1.3, 1.3, 1.0)

    def _factory_key_from_structure(self, structure_key: str) -> Optional[str]:
        mapping = {
            "infantry_factory": "infantry",
            "armor_factory": "armor",
            "air_factory": "air",
            "heli_factory": "heli",
            "defense_factory": "defense",
        }
        return mapping.get(structure_key)

    def _next_factory_cost(self, player, factory_key: str) -> Optional[int]:
        tier = player.tech_levels.get(factory_key, 0)
        costs = self.runtime.settings.upgrades.factory_upgrade_costs
        if tier >= len(costs):
            return None
        return costs[tier]

    def _next_stealth_cost(self, player) -> Optional[int]:
        tier = player.tech_levels.get("stealth", 0)
        costs = self.runtime.settings.upgrades.stealth_upgrade_costs
        if tier >= len(costs):
            return None
        return costs[tier]

    def _handle_build_button(self, key: str) -> None:
        try:
            self.runtime.queue_structure(self._build_side, key, 1)
            self._pulse_next_slot(self._build_side, key)
        except ValueError:
            return

    def _toggle_side(self) -> None:
        self._build_side = "p2" if self._build_side == "p1" else "p1"
        if self._side_button:
            self._side_button["text"] = f"Side: {self._build_side.upper()}"

    def _pulse_next_slot(self, side: str, key: str) -> None:
        player = self.runtime.state.player1 if side == "p1" else self.runtime.state.player2
        current = player.structures.get(key, 0)
        self._pulse_build_slot(side, key, current)

    def _pulse_build_slot(self, side: str, key: str, index: int) -> None:
        nodes = self._structure_nodes.get(side, {}).get(key, [])
        if 0 <= index < len(nodes):
            nodes[index].setColorScale(1.4, 1.4, 1.4, 1.0)

    def _start_drag(self) -> None:
        if not self._engine or not self._engine.mouseWatcherNode.hasMouse():
            return
        self._mouse_dragging = True
        self._last_mouse_pos = self._engine.mouseWatcherNode.getMouse()

    def _stop_drag(self) -> None:
        self._mouse_dragging = False
        self._last_mouse_pos = None

    def _update_drag(self) -> None:
        if not self._mouse_dragging or not self._engine or self._camera_center is None:
            return
        if not self._engine.mouseWatcherNode.hasMouse():
            return
        current = self._engine.mouseWatcherNode.getMouse()
        if self._last_mouse_pos is None:
            self._last_mouse_pos = current
            return
        dx = current.getX() - self._last_mouse_pos.getX()
        dy = current.getY() - self._last_mouse_pos.getY()
        self._camera_center.x -= dx * 260
        self._camera_center.y -= dy * 260
        self._last_mouse_pos = current

    def _unit_color(self, side: str, unit: str) -> Tuple[float, float, float, float]:
        if side == "p1":
            base = (0.2, 0.55, 0.9, 1.0)
        else:
            base = (0.9, 0.4, 0.2, 1.0)
        if unit.startswith("def_"):
            return (base[0] * 0.7, base[1] * 0.7, base[2] * 0.7, 1.0)
        if unit == "helicopter":
            return (0.6, 0.85, 0.7, 1.0)
        if unit == "aircraft":
            return (0.9, 0.9, 0.95, 1.0)
        return base

    def _map_pos(self, frontline_position: float) -> float:
        span = self.runtime.settings.frontline.max_position - self.runtime.settings.frontline.min_position
        ratio = (frontline_position - self.runtime.settings.frontline.min_position) / span
        return self._map_length / 2 - ratio * self._map_length

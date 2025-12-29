from __future__ import annotations

import math
import random
import tkinter as tk
from dataclasses import dataclass
from tkinter import messagebox, ttk
from typing import Dict, List, Optional

from operation_gotland.simulation.actions import launch_sortie, queue_factory_purchase
from operation_gotland.simulation.engine import SimulationEngine
from operation_gotland.simulation.events import EventKind, SimEvent
from operation_gotland.simulation.factories import FactoryCatalog
from operation_gotland.simulation.rules import (
    build_capacity,
    clamp,
    income_this_tick,
    logistics_factor,
    total_production,
)
from operation_gotland.simulation.state import PlayerState, SimulationConfig


@dataclass
class VisualDot:
    start: float
    progress: float
    y: float
    direction: int
    speed: float
    side: str
    lane: Dict[str, float]
    kind: str
    phase: str
    x: float = 0.0


class GameUI:
    def __init__(
        self,
        engine: SimulationEngine,
        factories: FactoryCatalog,
        config: SimulationConfig,
    ) -> None:
        self.engine = engine
        self.state = engine.state
        self.factories = factories
        self.config = config
        self.history: List[str] = []
        self.rng = random.Random(42)

        self.root = tk.Tk()
        self.root.title("Operation Gotland - System Warfare")
        screen_w = self.root.winfo_screenwidth()
        screen_h = self.root.winfo_screenheight()
        width = max(1200, min(screen_w - 80, 1800))
        height = max(700, min(screen_h - 120, 1000))
        self.root.geometry(f"{width}x{height}")
        self.root.minsize(1100, 600)
        self._init_vars()
        self._build_layout()
        self.root.update_idletasks()
        self._init_canvas()
        self.update_status()
        self._animate()

    def _init_vars(self) -> None:
        self.frontline_pct = tk.DoubleVar(value=self.frontline_ratio())
        self.frontline_label = tk.StringVar()
        self.pressure_p1 = tk.DoubleVar()
        self.pressure_p2 = tk.DoubleVar()
        self.pressure_label = tk.StringVar()
        self.logi_penalty_label = tk.StringVar()
        self.sortie_label = tk.StringVar()
        self.p1_panel: Dict[str, tk.Variable] = {}
        self.p2_panel: Dict[str, tk.Variable] = {}
        self.frontline_line_id: Optional[int] = None
        self.dots: List[VisualDot] = []
        self.lanes: List[Dict[str, float]] = []
        self.obstacles: List[Dict[str, float]] = []
        self.structure_icons: List[int] = []
        self.effects: List[Dict[str, float]] = []
        self.base_icons: List[int] = []
        self._canvas_size: Optional[tuple[int, int]] = None

    def _build_layout(self) -> None:
        self.root.columnconfigure(0, weight=1)
        self.root.columnconfigure(1, weight=0)
        self.root.rowconfigure(0, weight=1)

        self.canvas = tk.Canvas(self.root, width=1200, height=700, bg="#0b1612", highlightthickness=0)
        self.canvas.grid(row=0, column=0, sticky="nsew")
        self.canvas.bind("<Configure>", self._on_canvas_resize)

        style = ttk.Style()
        military_bg = "#0e1f16"
        military_fg = "#e4f1d7"
        style.configure("Overlay.TFrame", background=military_bg, relief="flat")
        style.configure("Overlay.TLabelframe", background=military_bg, relief="flat", foreground=military_fg)
        style.configure("Overlay.TLabelframe.Label", background=military_bg, foreground=military_fg)
        style.configure("Military.TLabel", background=military_bg, foreground=military_fg, font=("TkFixedFont", 10))
        style.configure("MilitaryBold.TLabel", background=military_bg, foreground=military_fg, font=("TkFixedFont", 10, "bold"))
        style.configure("Military.TButton", font=("TkFixedFont", 10))

        sidebar = ttk.Frame(self.root, padding=10, style="Overlay.TFrame")
        sidebar.grid(row=0, column=1, sticky="ns")
        sidebar.columnconfigure(0, weight=1)

        status_frame = ttk.LabelFrame(sidebar, text="Status", style="Overlay.TLabelframe")
        status_frame.grid(row=0, column=0, sticky="nsew", pady=(0, 8))
        status_frame.columnconfigure(0, weight=1)

        frontline_row = ttk.Frame(status_frame, padding=(6, 6))
        frontline_row.grid(row=0, column=0, sticky="ew")
        ttk.Label(frontline_row, text="Front line", style="MilitaryBold.TLabel").grid(row=0, column=0, sticky="w", padx=(0, 8))
        ttk.Progressbar(frontline_row, maximum=100.0, variable=self.frontline_pct).grid(row=0, column=1, sticky="ew")
        frontline_row.columnconfigure(1, weight=1)
        ttk.Label(frontline_row, textvariable=self.frontline_label, width=8, style="MilitaryBold.TLabel").grid(row=0, column=2, padx=(8, 0))

        pressure_row = ttk.Frame(status_frame, padding=(6, 0))
        pressure_row.grid(row=1, column=0, sticky="ew")
        ttk.Label(pressure_row, text="Pressure P1 -> P2", style="MilitaryBold.TLabel").grid(row=0, column=0, sticky="w", padx=(0, 8))
        ttk.Progressbar(pressure_row, maximum=self.config.pressure_threshold, variable=self.pressure_p1).grid(row=0, column=1, sticky="ew")
        ttk.Label(pressure_row, text="P2 -> P1", padding=(12, 0), style="MilitaryBold.TLabel").grid(row=1, column=0, sticky="w")
        ttk.Progressbar(pressure_row, maximum=self.config.pressure_threshold, variable=self.pressure_p2).grid(row=1, column=1, sticky="ew")
        pressure_row.columnconfigure(1, weight=1)
        ttk.Label(pressure_row, textvariable=self.pressure_label, style="Military.TLabel").grid(row=2, column=0, columnspan=2, sticky="w", pady=(4, 0))

        ttk.Label(status_frame, textvariable=self.logi_penalty_label, padding=(6, 6), style="Military.TLabel").grid(row=2, column=0, sticky="w")

        players_frame = ttk.Frame(status_frame)
        players_frame.grid(row=3, column=0, sticky="nsew", padx=6, pady=(0, 6))
        players_frame.columnconfigure(0, weight=1)
        players_frame.columnconfigure(1, weight=1)
        self.p1_panel = self._build_player_panel(players_frame, "Player 1", column=0)
        self.p2_panel = self._build_player_panel(players_frame, "Player 2", column=1)

        ttk.Label(status_frame, textvariable=self.sortie_label, padding=(6, 2), style="Military.TLabel").grid(row=4, column=0, sticky="w")

        controls = ttk.LabelFrame(sidebar, text="Controls", style="Overlay.TLabelframe")
        controls.grid(row=1, column=0, sticky="nsew", pady=(0, 8))

        tick_row = ttk.Frame(controls)
        tick_row.grid(row=0, column=0, sticky="w", padx=6, pady=6)
        ttk.Label(tick_row, text="Advance ticks:").grid(row=0, column=0, padx=(0, 6))
        ttk.Button(tick_row, text="+1", command=self.handle_single_tick).grid(row=0, column=1, padx=2)
        ttk.Button(tick_row, text="+5", command=lambda: self.handle_multiple_ticks(5)).grid(row=0, column=2, padx=2)
        ttk.Button(tick_row, text="+25", command=lambda: self.handle_multiple_ticks(25)).grid(row=0, column=3, padx=2)

        buy_frame = ttk.LabelFrame(controls, text="Purchase factory", style="Overlay.TLabelframe")
        buy_frame.grid(row=1, column=0, sticky="ew", padx=6, pady=6)
        buy_frame.columnconfigure(1, weight=1)

        ttk.Label(buy_frame, text="Player").grid(row=0, column=0, sticky="w", padx=(0, 6))
        self.buy_player = tk.StringVar(value="P1")
        ttk.Combobox(buy_frame, values=["P1", "P2"], textvariable=self.buy_player, width=6, state="readonly").grid(row=0, column=1, sticky="ew")

        ttk.Label(buy_frame, text="Factory").grid(row=1, column=0, sticky="w", padx=(0, 6), pady=(4, 0))
        self.factory_options = [
            f"{factory_id}: {factory.name} ({factory.cost} cr)"
            for factory_id, factory in sorted(self.factories.factories.items())
        ]
        default_factory = self.factory_options[0] if self.factory_options else ""
        self.factory_var = tk.StringVar(value=default_factory)
        ttk.Combobox(buy_frame, values=self.factory_options, textvariable=self.factory_var, state="readonly").grid(row=1, column=1, sticky="ew", pady=(4, 0))

        ttk.Label(buy_frame, text="Quantity").grid(row=2, column=0, sticky="w", padx=(0, 6), pady=(4, 0))
        self.quantity_var = tk.StringVar(value="1")
        ttk.Spinbox(buy_frame, from_=1, to=9, textvariable=self.quantity_var, width=6).grid(row=2, column=1, sticky="w", pady=(4, 0))

        ttk.Button(buy_frame, text="Queue Purchase", command=self.handle_buy).grid(row=3, column=0, columnspan=2, pady=(6, 0))

        sortie_frame = ttk.LabelFrame(controls, text="Launch air sortie", style="Overlay.TLabelframe")
        sortie_frame.grid(row=2, column=0, sticky="ew", padx=6, pady=6)
        sortie_frame.columnconfigure(1, weight=1)

        ttk.Label(sortie_frame, text="Player").grid(row=0, column=0, sticky="w", padx=(0, 6))
        self.sortie_player = tk.StringVar(value="P1")
        ttk.Combobox(sortie_frame, values=["P1", "P2"], textvariable=self.sortie_player, width=6, state="readonly").grid(row=0, column=1, sticky="ew")

        ttk.Label(sortie_frame, text="Size").grid(row=1, column=0, sticky="w", padx=(0, 6), pady=(4, 0))
        self.sortie_size = tk.StringVar(value="small")
        ttk.Combobox(sortie_frame, values=["small", "med", "large"], textvariable=self.sortie_size, width=10, state="readonly").grid(row=1, column=1, sticky="ew", pady=(4, 0))

        ttk.Label(sortie_frame, text="Target").grid(row=2, column=0, sticky="w", padx=(0, 6), pady=(4, 0))
        self.sortie_target = tk.StringVar(value="vehicles")
        ttk.Combobox(
            sortie_frame,
            values=["vehicles", "arms", "air", "def", "logi"],
            textvariable=self.sortie_target,
            width=10,
            state="readonly",
        ).grid(row=2, column=1, sticky="ew", pady=(4, 0))

        ttk.Button(sortie_frame, text="Launch Sortie", command=self.handle_sortie).grid(row=3, column=0, columnspan=2, pady=(6, 0))

        store_frame = ttk.LabelFrame(sidebar, text="Store (read-only)", style="Overlay.TLabelframe")
        store_frame.grid(row=2, column=0, sticky="nsew")
        store_frame.columnconfigure(0, weight=1)
        store_frame.rowconfigure(0, weight=1)
        self.store_text = tk.Text(store_frame, width=40, height=12, wrap="word", state="disabled", bg="#0f2019", fg="#e4f1d7", insertbackground="#e4f1d7")
        self.store_text.grid(row=0, column=0, sticky="nsew")
        self._refresh_store()

        history_frame = ttk.LabelFrame(sidebar, text="Recent events", style="Overlay.TLabelframe")
        history_frame.grid(row=3, column=0, sticky="nsew", pady=(8, 0))
        history_frame.columnconfigure(0, weight=1)
        history_frame.rowconfigure(0, weight=1)
        self.history_text = tk.Text(history_frame, width=40, height=10, wrap="word", state="disabled", bg="#0f2019", fg="#e4f1d7", insertbackground="#e4f1d7")
        self.history_text.grid(row=0, column=0, sticky="nsew")

    def _build_player_panel(self, parent: ttk.Frame, title: str, column: int) -> Dict[str, tk.Variable]:
        frame = ttk.LabelFrame(parent, text=title, padding=6, style="Overlay.TLabelframe")
        frame.grid(row=0, column=column, sticky="nsew", padx=4)
        frame.columnconfigure(1, weight=1)

        credits = tk.StringVar()
        logi_text = tk.StringVar()
        logi_bar = tk.DoubleVar()
        production = tk.StringVar()
        units = tk.StringVar()
        build = tk.StringVar()
        purchases = tk.StringVar()

        ttk.Label(frame, textvariable=credits, style="MilitaryBold.TLabel").grid(row=0, column=0, columnspan=2, sticky="w")

        ttk.Label(frame, text="Logistics", style="MilitaryBold.TLabel").grid(row=1, column=0, sticky="w", pady=(2, 0))
        ttk.Progressbar(frame, maximum=250.0, variable=logi_bar).grid(row=1, column=1, sticky="ew", pady=(2, 0))
        ttk.Label(frame, textvariable=logi_text, style="Military.TLabel").grid(row=2, column=0, columnspan=2, sticky="w")

        ttk.Label(frame, text="Production", style="MilitaryBold.TLabel").grid(row=3, column=0, sticky="nw", pady=(4, 0))
        ttk.Label(frame, textvariable=production, wraplength=260, justify="left", style="Military.TLabel").grid(row=3, column=1, sticky="w", pady=(4, 0))

        ttk.Label(frame, text="Units", style="MilitaryBold.TLabel").grid(row=4, column=0, sticky="nw", pady=(2, 0))
        ttk.Label(frame, textvariable=units, wraplength=260, justify="left", style="Military.TLabel").grid(row=4, column=1, sticky="w", pady=(2, 0))

        ttk.Label(frame, text="Build queue", style="MilitaryBold.TLabel").grid(row=5, column=0, sticky="nw", pady=(2, 0))
        ttk.Label(frame, textvariable=build, wraplength=260, justify="left", style="Military.TLabel").grid(row=5, column=1, sticky="w", pady=(2, 0))

        ttk.Label(frame, text="Purchases", style="MilitaryBold.TLabel").grid(row=6, column=0, sticky="nw", pady=(2, 0))
        ttk.Label(frame, textvariable=purchases, wraplength=260, justify="left", style="Military.TLabel").grid(row=6, column=1, sticky="w", pady=(2, 0))

        return {
            "credits": credits,
            "logi_text": logi_text,
            "logi_bar": logi_bar,
            "production": production,
            "units": units,
            "build": build,
            "purchases": purchases,
        }

    def _init_canvas(self) -> None:
        self.canvas.delete("all")
        self.canvas.configure(bg="#0b1612")
        width = int(self.canvas.cget("width"))
        height = int(self.canvas.cget("height"))
        self._canvas_size = (width, height)
        ground_y = height - 40
        self._draw_map_background(width, height, ground_y)
        self.base_icons = [
            self.canvas.create_oval(20, ground_y - 90, 90, ground_y - 20, fill="#1b5fc1", outline=""),
            self.canvas.create_oval(width - 90, ground_y - 90, width - 20, ground_y - 20, fill="#c12c2c", outline=""),
        ]
        self.obstacles = self._build_obstacles(width, ground_y)
        self._render_structures()
        self.frontline_line_id = self.canvas.create_line(
            self._frontline_x(width),
            10,
            self._frontline_x(width),
            ground_y,
            fill="#d3d7de",
            width=2,
            dash=(4, 4),
        )
        self.canvas.create_text(30, 24, text="P1 Base", fill="#b7e1ff", anchor="w", font=("TkFixedFont", 11, "bold"))
        self.canvas.create_text(width - 30, 24, text="P2 Base", fill="#ffd8d8", anchor="e", font=("TkFixedFont", 11, "bold"))
        self.lanes = self._build_lanes(height)

    def _on_canvas_resize(self, event: tk.Event) -> None:
        if event.width < 200 or event.height < 200:
            return
        if self._canvas_size == (event.width, event.height):
            return
        self.dots = []
        self.effects = []
        self._init_canvas()

    def _frontline_x(self, width: int) -> float:
        return self.config.frontline_min + (self.frontline_ratio() / 100.0) * width

    def _spawn_dots(self) -> None:
        width = int(self.canvas.cget("width"))
        height = int(self.canvas.cget("height"))
        ground_y = height - 50
        spawn_band = (40, ground_y - 20)
        p1_spawn = self._spawn_count(self.state.player1)
        p2_spawn = self._spawn_count(self.state.player2)

        for _ in range(p1_spawn):
            y = self.rng.randint(*spawn_band)
            kind = self._choose_kind(self.state.player1)
            lane = self.rng.choice(self.lanes)
            start_x = 60.0 if kind not in ("aircraft", "helicopter") else self._airfield_x("p1")
            self.dots.append(
                VisualDot(
                    start=start_x,
                    progress=0.0,
                    y=float(y),
                    direction=1,
                    speed=self._speed_for_kind(kind),
                    side="p1",
                    lane=lane,
                    kind=kind,
                    phase="outbound",
                )
            )
        for _ in range(p2_spawn):
            y = self.rng.randint(*spawn_band)
            kind = self._choose_kind(self.state.player2)
            lane = self.rng.choice(self.lanes)
            start_x = float(width - 60) if kind not in ("aircraft", "helicopter") else self._airfield_x("p2")
            self.dots.append(
                VisualDot(
                    start=start_x,
                    progress=0.0,
                    y=float(y),
                    direction=-1,
                    speed=self._speed_for_kind(kind),
                    side="p2",
                    lane=lane,
                    kind=kind,
                    phase="outbound",
                )
            )
        if len(self.dots) > 400:
            self.dots = self.dots[-400:]

    def _spawn_count(self, player: PlayerState) -> int:
        prod = player.production
        effective_prod = (prod.vehicles + prod.arms + prod.aircraft) * logistics_factor(player)
        return int(clamp(int(effective_prod / 40), 1, 8))

    def _resolve_dot_collisions(self) -> None:
        survivors: List[VisualDot] = []
        grid: Dict[tuple, Dict[str, VisualDot]] = {}
        cell_size = 10
        for dot in self.dots:
            cell_x = int(dot.x // cell_size)
            cell_y = int(dot.y // cell_size)
            key = (cell_x, cell_y)
            bucket = grid.setdefault(key, {})
            if bucket and bucket.get("side") != dot.side:
                bucket.clear()
            else:
                bucket["dot"] = dot
                bucket["side"] = dot.side
        for bucket in grid.values():
            dot = bucket.get("dot")
            if dot:
                survivors.append(dot)
        self.dots = survivors
        if self.effects:
            self.effects = [eff for eff in self.effects if eff.get("ttl", 0) > 0]

    def _step_dots(self) -> None:
        width = int(self.canvas.cget("width"))
        travel = width - 120
        next_dots: List[VisualDot] = []
        for dot in self.dots:
            dot.progress += dot.speed
            lane = dot.lane
            base_x = dot.start + dot.direction * dot.progress
            sway = math.sin((dot.progress / lane["period"]) + lane["phase"]) * lane["amplitude"]
            candidate_x = base_x
            candidate_y = lane["y"] + sway
            if dot.kind not in ("aircraft", "helicopter"):
                for obs in self.obstacles:
                    if obs["x1"] <= candidate_x <= obs["x2"] and obs["y1"] <= candidate_y <= obs["y2"]:
                        if candidate_y < (obs["y1"] + obs["y2"]) / 2:
                            candidate_y = obs["y1"] - 5
                        else:
                            candidate_y = obs["y2"] + 5
            dot.x = candidate_x
            dot.y = candidate_y
            if dot.kind in ("aircraft", "helicopter"):
                target_x = self._frontline_x(width)
                reached_target = (dot.direction == 1 and candidate_x >= target_x) or (
                    dot.direction == -1 and candidate_x <= target_x
                )
                if dot.phase == "outbound" and reached_target:
                    self.effects.append({"x": target_x, "y": candidate_y, "ttl": 18})
                    dot.phase = "return"
                    dot.direction *= -1
                    dot.start = candidate_x
                    dot.progress = 0.0
            if dot.phase == "return" and dot.progress > travel / 2:
                continue
            next_dots.append(dot)
        self.dots = next_dots

    def _render_dots(self) -> None:
        width = int(self.canvas.cget("width"))
        height = int(self.canvas.cget("height"))
        ground_y = height - 40
        self.canvas.delete("dot")
        if self.frontline_line_id:
            self.canvas.coords(
                self.frontline_line_id,
                self._frontline_x(width),
                10,
                self._frontline_x(width),
                ground_y,
            )
        for dot in self.dots:
            self._draw_unit_sprite(dot)

    def _animate(self) -> None:
        self._spawn_dots()
        self._step_dots()
        self._resolve_dot_collisions()
        self._render_dots()
        self._render_effects()
        self.root.after(30, self._animate)

    def _draw_unit_sprite(self, dot: VisualDot) -> None:
        kind = dot.kind
        side = dot.side
        color = self._color_for_kind(kind, side)
        outline = "#0a0a0a"
        scale = self._size_for_kind(kind)
        cx, cy = dot.x, dot.y
        if kind in ("tank", "vehicle"):
            body = [(-1.2, -0.5), (1.4, -0.5), (1.6, 0.0), (1.4, 0.5), (-1.2, 0.5), (-1.4, 0.0)]
            turret = [(-0.2, -0.2), (0.8, -0.2), (0.8, 0.2), (-0.2, 0.2)]
            gun = [(0.8, -0.05), (1.6, -0.05), (1.6, 0.05), (0.8, 0.05)]
            for poly in (body, turret, gun):
                pts = []
                for x, y in poly:
                    pts.extend([cx + x * scale, cy + y * scale])
                self.canvas.create_polygon(pts, fill=color, outline=outline, width=1, tags="dot")
            return
        if kind == "infantry":
            body = [(-0.6, -0.8), (0.6, -0.8), (0.6, 0.8), (-0.6, 0.8)]
            pts = []
            for x, y in body:
                pts.extend([cx + x * scale, cy + y * scale])
            self.canvas.create_polygon(pts, fill=color, outline=outline, width=1, tags="dot")
            self.canvas.create_line(cx, cy - 0.8 * scale, cx, cy - 1.5 * scale, fill=color, width=2, tags="dot")
            return
        if kind in ("aircraft", "helicopter"):
            nose = (1.5, 0.0)
            tail = (-1.2, 0.0)
            wing1 = (0.2, 0.8)
            wing2 = (0.2, -0.8)
            pts = []
            for x, y in (nose, wing1, tail, wing2):
                pts.extend([cx + x * scale, cy + y * scale])
            self.canvas.create_polygon(pts, fill=color, outline=outline, width=1, tags="dot")
            if kind == "helicopter":
                self.canvas.create_oval(
                    cx - 1.0 * scale,
                    cy - 1.0 * scale,
                    cx + 1.0 * scale,
                    cy + 1.0 * scale,
                    outline=color,
                    width=2,
                    tags="dot",
                )
            return
        if kind == "missile":
            body = [(-0.6, -0.2), (1.2, -0.2), (1.4, 0.0), (1.2, 0.2), (-0.6, 0.2)]
            tail1 = [(-0.6, -0.2), (-0.9, -0.5), (-0.6, -0.5)]
            tail2 = [(-0.6, 0.2), (-0.9, 0.5), (-0.6, 0.5)]
            for poly in (body, tail1, tail2):
                pts = []
                for x, y in poly:
                    pts.extend([cx + x * scale, cy + y * scale])
                self.canvas.create_polygon(pts, fill=color, outline=outline, width=1, tags="dot")
            return
        self.canvas.create_oval(cx - scale, cy - scale, cx + scale, cy + scale, fill=color, outline="", tags="dot")

    def _render_effects(self) -> None:
        if not self.effects:
            return
        self.canvas.delete("effect")
        survivors: List[Dict[str, float]] = []
        for eff in self.effects:
            r = max(4, eff.get("ttl", 0) // 2)
            self.canvas.create_oval(
                eff["x"] - r,
                eff["y"] - r,
                eff["x"] + r,
                eff["y"] + r,
                outline="#ffd36f",
                width=2,
                tags="effect",
            )
            eff["ttl"] -= 1
            if eff["ttl"] > 0:
                survivors.append(eff)
        self.effects = survivors

    def _draw_map_background(self, width: int, height: int, ground_y: int) -> None:
        self.canvas.create_rectangle(0, 0, width, height, fill="#0b1612", outline="")
        band_height = max(1, ground_y // 3)
        self.canvas.create_rectangle(0, 0, width, band_height, fill="#102c1f", outline="")
        self.canvas.create_rectangle(0, band_height, width, band_height * 2, fill="#143424", outline="")
        self.canvas.create_rectangle(0, band_height * 2, width, ground_y, fill="#1a4230", outline="")

        for x in range(0, width, 60):
            self.canvas.create_line(x, 0, x, height, fill="#143021", width=1, tags="map")
        for y in range(0, height, 60):
            self.canvas.create_line(0, y, width, y, fill="#143021", width=1, tags="map")

        land_colors = ("#123e2c", "#1a4d36", "#1f5a40")
        for _ in range(8):
            cx = self.rng.randint(80, width - 80)
            cy = self.rng.randint(60, ground_y - 60)
            points = []
            radius = self.rng.randint(80, 160)
            for i in range(10):
                angle = (math.pi * 2 * i) / 10
                r = radius * self.rng.uniform(0.6, 1.15)
                points.extend([cx + math.cos(angle) * r, cy + math.sin(angle) * r])
            self.canvas.create_polygon(points, fill=self.rng.choice(land_colors), outline="")

        river_points = []
        river_y = ground_y * 0.55
        for x in range(0, width + 1, 40):
            y = river_y + math.sin(x / 140.0) * 18
            river_points.extend([x, y])
        self.canvas.create_line(river_points, fill="#1d2d3d", width=16, smooth=True, tags="map")
        self.canvas.create_line(river_points, fill="#2d4b5f", width=6, smooth=True, tags="map")

        road_y = ground_y * 0.25
        self.canvas.create_line(40, road_y, width - 40, road_y + 20, fill="#2b3a2f", width=4, tags="map")
        self.canvas.create_line(40, road_y + 6, width - 40, road_y + 26, fill="#36463a", width=2, tags="map")

        self.canvas.create_rectangle(0, ground_y, width, height, fill="#0c141a", outline="")
        self.canvas.create_rectangle(20, ground_y - 24, 120, ground_y - 8, fill="#1f2e2a", outline="#4a5b50", tags="map")
        self.canvas.create_rectangle(width - 120, ground_y - 24, width - 20, ground_y - 8, fill="#2e1f1f", outline="#5b4a4a", tags="map")

    def _build_lanes(self, height: int) -> List[Dict[str, float]]:
        lanes: List[Dict[str, float]] = []
        base_y_positions = [height * 0.28, height * 0.38, height * 0.48, height * 0.58, height * 0.68, height * 0.78]
        for base_y in base_y_positions:
            amplitude = self.rng.uniform(8.0, 16.0)
            period = self.rng.uniform(70.0, 130.0)
            phase = self.rng.uniform(0, math.pi * 2)
            lanes.append({"y": base_y, "amplitude": amplitude, "period": period, "phase": phase})
        return lanes

    def _build_obstacles(self, width: int, ground_y: int) -> List[Dict[str, float]]:
        obstacles: List[Dict[str, float]] = []
        for _ in range(9):
            w = self.rng.randint(40, 90)
            h = self.rng.randint(30, 70)
            x1 = self.rng.randint(160, width - 200)
            y1 = self.rng.randint(80, int(ground_y - 120))
            x2 = x1 + w
            y2 = y1 + h
            obstacles.append({"x1": x1, "y1": y1, "x2": x2, "y2": y2})
            self.canvas.create_rectangle(x1, y1, x2, y2, fill="#4a5b50", outline="#2a3a30", width=2, tags="obstacle")
        return obstacles

    def _airfield_x(self, side: str) -> float:
        width = int(self.canvas.cget("width"))
        return 70.0 if side == "p1" else float(width - 70)

    def _render_structures(self) -> None:
        for item in self.structure_icons:
            self.canvas.delete(item)
        self.structure_icons = []
        width = int(self.canvas.cget("width"))
        icon_size = 8
        spacing = 14
        for idx, (factory_id, factory) in enumerate(sorted(self.factories.factories.items())):
            x_left = 28
            x_right = width - 28
            y_base = 36 + idx * spacing
            for _ in range(self.state.player1.purchases.get(factory_id, 0)):
                self.structure_icons.append(
                    self.canvas.create_rectangle(
                        x_left - icon_size,
                        y_base - icon_size,
                        x_left + icon_size,
                        y_base + icon_size,
                        outline="#9ad69a",
                        fill="#1b3326",
                        tags="structure",
                    )
                )
            for _ in range(self.state.player2.purchases.get(factory_id, 0)):
                self.structure_icons.append(
                    self.canvas.create_rectangle(
                        x_right - icon_size,
                        y_base - icon_size,
                        x_right + icon_size,
                        y_base + icon_size,
                        outline="#ff9a7b",
                        fill="#3b1f1f",
                        tags="structure",
                    )
                )
            self.structure_icons.append(
                self.canvas.create_text(
                    x_left + 18,
                    y_base,
                    text=factory.name,
                    anchor="w",
                    fill="#9ad69a",
                    font=("TkFixedFont", 8),
                    tags="structure",
                )
            )

    def _choose_kind(self, player: PlayerState) -> str:
        units = player.units
        weights = {
            "tank": units.tanks,
            "vehicle": units.vehicles,
            "infantry": units.arms,
            "aircraft": units.aircraft,
            "helicopter": units.helicopters,
            "missile": units.missiles,
        }
        total = sum(weights.values())
        if total <= 0:
            return "infantry"
        pick = self.rng.uniform(0, total)
        cumulative = 0.0
        for kind, val in weights.items():
            cumulative += val
            if pick <= cumulative:
                return kind
        return "infantry"

    def _speed_for_kind(self, kind: str) -> float:
        base = {
            "infantry": 1.4,
            "vehicle": 1.9,
            "tank": 1.7,
            "aircraft": 3.2,
            "helicopter": 2.6,
            "missile": 1.8,
        }
        return base.get(kind, 1.2)

    def _size_for_kind(self, kind: str) -> float:
        sizes = {
            "infantry": 3.5,
            "vehicle": 5.0,
            "tank": 5.5,
            "aircraft": 4.5,
            "helicopter": 4.2,
            "missile": 3.8,
        }
        return sizes.get(kind, 3.0)

    def _color_for_kind(self, kind: str, side: str) -> str:
        base = {
            "infantry": "#9ad69a",
            "vehicle": "#7fb0ff",
            "tank": "#4fa3ff",
            "aircraft": "#ffd36f",
            "helicopter": "#ffb347",
            "missile": "#d6a0ff",
        }
        shade = base.get(kind, "#9ad69a")
        if side == "p2":
            return "#ff7b7b" if kind in ("infantry", "missile") else "#ff9a7b"
        return shade

    def _refresh_store(self) -> None:
        self.store_text.configure(state="normal")
        self.store_text.delete("1.0", "end")
        self.store_text.insert("1.0", self.describe_store())
        self.store_text.configure(state="disabled")

    def describe_store(self) -> str:
        lines = ["Store:", " id | cost | name", "-" * 30]
        for factory_id, factory in sorted(self.factories.factories.items()):
            lines.append(f"  {factory_id:^2} | {factory.cost:^4} | {factory.name}")
            lines.append(f"      -> {factory.description}")
        return "\n".join(lines)

    def update_status(self) -> None:
        self.frontline_pct.set(self.frontline_ratio())
        self.frontline_label.set(f"{self.frontline_ratio():.1f}%")
        self.pressure_p1.set(self.state.frontline.pressure_toward_p2)
        self.pressure_p2.set(self.state.frontline.pressure_toward_p1)
        self.pressure_label.set(
            f"P1->P2 {self.state.frontline.pressure_toward_p2:.1f}/{self.config.pressure_threshold} | "
            f"P2->P1 {self.state.frontline.pressure_toward_p1:.1f}/{self.config.pressure_threshold}"
        )
        self.logi_penalty_label.set(
            f"Missile logistics penalty: P1 {self.state.player1.logistics_penalty:.1f} | "
            f"P2 {self.state.player2.logistics_penalty:.1f}"
        )

        self._update_player_panel(self.p1_panel, self.state.player1)
        self._update_player_panel(self.p2_panel, self.state.player2)

        active_sorties = len(self.state.sorties)
        if active_sorties:
            self.sortie_label.set(f"Active sorties: {active_sorties} aircraft groups away from the front.")
        else:
            self.sortie_label.set("")

        self._render_structures()
        self._update_canvas()

        self.history_text.configure(state="normal")
        self.history_text.delete("1.0", "end")
        self.history_text.insert("1.0", self.render_history(limit=12))
        self.history_text.configure(state="disabled")

    def _update_canvas(self) -> None:
        if self.frontline_line_id is None:
            return
        width = int(self.canvas.cget("width"))
        height = int(self.canvas.cget("height"))
        self.canvas.coords(
            self.frontline_line_id,
            self._frontline_x(width),
            10,
            self._frontline_x(width),
            height - 40,
        )

    def _update_player_panel(self, panel: Dict[str, tk.Variable], player: PlayerState) -> None:
        panel["credits"].set(
            f"{player.name}: {player.economy.credits} credits (Income: {income_this_tick(player, self.config)})"
        )
        panel["logi_bar"].set(player.logistics_health)
        panel["logi_text"].set(f"Logistics {player.logistics_health:.1f} (factor {logistics_factor(player):.2f})")
        panel["production"].set(
            f"Output -> Veh {player.production.vehicles:.1f} | Arms {player.production.arms:.1f} | "
            f"Air {player.production.aircraft:.1f} | Def {player.production.defense:.1f} | "
            f"Total {total_production(player):.1f}"
        )
        panel["units"].set(
            "Ground: INF {inf:.1f} | IFV {veh:.1f} | TANK {tank:.1f}\n"
            "Air: AC {air:.1f} | HELI {heli:.1f} | MISS {miss:.1f}\n"
            "Def: AR {defa:.1f} | VEH {defv:.1f} | AIR {defair:.1f}".format(
                inf=player.units.arms,
                veh=player.units.vehicles,
                tank=player.units.tanks,
                air=player.units.aircraft,
                heli=player.units.helicopters,
                miss=player.units.missiles,
                defa=player.units.def_arms,
                defv=player.units.def_vehicle,
                defair=player.units.def_air,
            )
        )
        queue_details = (
            ", ".join(
                f"{self.factories.get(order.factory_id).name} ({order.remaining}t)"
                for order in player.economy.build_queue
            )
            or "empty"
        )
        panel["build"].set(
            f"Slots {build_capacity(player)} | Queue {len(player.economy.build_queue)}/{self.config.build_queue_max} -> {queue_details}"
        )
        panel["purchases"].set(
            ", ".join(
                f"{self.factories.get(factory_id).name} x{count}"
                for factory_id, count in sorted(player.purchases.items())
                if count > 0
            )
            or "No structures yet"
        )

    def handle_single_tick(self) -> None:
        self.handle_multiple_ticks(1)

    def handle_multiple_ticks(self, count: int) -> None:
        try:
            for _ in range(count):
                frame = self.engine.tick(1)
                self.record_events(frame.events)
                if self.state.winner:
                    break
            self.update_status()
        except ValueError as exc:
            messagebox.showerror("Tick error", str(exc))

    def _selected_factory_id(self) -> int:
        selected = self.factory_var.get()
        if ":" not in selected:
            return 0
        return int(selected.split(":")[0])

    def handle_buy(self) -> None:
        factory_id = self._selected_factory_id()
        try:
            quantity = int(self.quantity_var.get())
        except ValueError:
            quantity = 1
        player_key = "p1" if self.buy_player.get().lower().startswith("p1") else "p2"
        try:
            events: List[SimEvent] = []
            queue_factory_purchase(
                self.state,
                player_key,
                factory_id,
                quantity,
                self.factories,
                self.config,
                events,
            )
            self.record_events(events)
            self.update_status()
        except ValueError as exc:
            messagebox.showerror("Purchase failed", str(exc))

    def handle_sortie(self) -> None:
        player_key = "p1" if self.sortie_player.get().lower().startswith("p1") else "p2"
        try:
            events: List[SimEvent] = []
            launch_sortie(
                self.state,
                player_key,
                self.sortie_size.get(),
                self.sortie_target.get(),
                self.config,
                events,
            )
            self.record_events(events)
            self.update_status()
        except ValueError as exc:
            messagebox.showerror("Sortie failed", str(exc))

    def record_events(self, events: List[SimEvent]) -> None:
        for event in events:
            if event.kind == EventKind.TICK:
                continue
            if event.kind == EventKind.FACTORY_QUEUED:
                factory = self.factories.get(event.payload["factory_id"])
                self.history.append(
                    f'{event.payload["player"]} queued {event.payload["quantity"]}x {factory.name}.'
                )
            elif event.kind == EventKind.FACTORY_COMPLETED:
                factory = self.factories.get(event.payload["factory_id"])
                self.history.append(f'{event.payload["player"]} completed {factory.name}.')
            elif event.kind == EventKind.SORTIE_LAUNCHED:
                self.history.append(
                    f'{event.payload["player"]} launched sortie ({event.payload["committed"]:.1f}) vs {event.payload["target"]}.'
                )
            elif event.kind == EventKind.SORTIE_RESOLVED:
                self.history.append(
                    f'{event.payload["attacker"]} hit {event.payload["defender"]} {event.payload["target"]} '
                    f'for {event.payload["damage"]:.1f} (loss {event.payload["losses"]:.1f}).'
                )
            elif event.kind == EventKind.MISSILE_PRESSURE:
                self.history.append(
                    f'Missile pressure on {event.payload["player"]}: {event.payload["penalty"]:.1f} logi.'
                )
            elif event.kind == EventKind.SUPPLY_BONUS:
                self.history.append(
                    f'{event.payload["player"]} gained {event.payload["bonus"]} credits from supply zones.'
                )
            elif event.kind == EventKind.COMBAT_RESOLVED:
                self.history.append("Combat losses updated.")
            elif event.kind == EventKind.FRONTLINE_MOVED:
                ratio = self.frontline_ratio()
                self.history.append(f"Frontline moved to {ratio:.1f}%.")
            elif event.kind == EventKind.VICTORY:
                self.history.append(f'{event.payload["winner"]} wins.')
        if len(self.history) > 40:
            self.history = self.history[-40:]

    def render_history(self, limit: int = 10) -> str:
        if not self.history:
            return "No history yet."
        recent = self.history[-limit:]
        return "Recent events:\n" + "\n".join(f" - {item}" for item in recent)

    def frontline_ratio(self) -> float:
        span = self.config.frontline_max - self.config.frontline_min
        if span <= 0:
            return 0.0
        return round(((self.state.frontline.position - self.config.frontline_min) / span) * 100.0, 2)

    def run(self) -> None:
        self.root.mainloop()

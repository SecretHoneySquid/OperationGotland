from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Tuple


@dataclass
class EntityInstance:
    entity_id: str
    asset_id: str
    position: Tuple[float, float, float]
    heading: float
    scale: float
    animation: str
    tags: List[str] = field(default_factory=list)


@dataclass
class EffectInstance:
    effect_id: str
    position: Tuple[float, float, float]
    intensity: float
    duration: float
    tags: List[str] = field(default_factory=list)


@dataclass
class CameraState:
    position: Tuple[float, float, float]
    look_at: Tuple[float, float, float]
    fov: float = 60.0


@dataclass
class SceneState:
    entities: List[EntityInstance] = field(default_factory=list)
    effects: List[EffectInstance] = field(default_factory=list)
    camera: CameraState | None = None
    metadata: Dict[str, float] = field(default_factory=dict)

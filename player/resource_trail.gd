extends Line2D

@export var bead_scene: PackedScene
@export var initial_bead_capacity: int = 20
@export var top_slack_segments: int = 3
@export var segment_length: float = 16.0
@export var gravity: Vector2 = Vector2(0.0, 980.0)
@export var constraint_iterations: int = 4
@export var bead_slide_speed: float = 240.0
@export var bead_face_tangent: bool = false

const EPS: float = 0.0001

var wpos: PackedVector2Array
var wprev: PackedVector2Array

class BeadRec:
	var node: Node2D
	var current_d: float
	var target_d: float

var beads: Array[BeadRec] = []
var last_resources_count: int = -1

func _ready() -> void:
	_build_rope_world()
	_refresh_line2d_points()
	_sync_beads(true)

func _physics_process(delta: float) -> void:
	_simulate_rope(delta)
	_refresh_line2d_points()
	_update_bead_inventory()
	_update_bead_animation(delta)

func _build_rope_world() -> void:
	var anchor: Vector2 = global_position
	var down: Vector2 = Vector2(0.0, 1.0).rotated(global_rotation)
	var total_segments: int = max(1, initial_bead_capacity + top_slack_segments)
	wpos = PackedVector2Array()
	wprev = PackedVector2Array()
	wpos.resize(total_segments + 1)
	wprev.resize(total_segments + 1)
	for i: int in range(total_segments + 1):
		var p: Vector2 = anchor + down * float(i) * segment_length
		wpos[i] = p
		wprev[i] = p

func _simulate_rope(delta: float) -> void:
	if wpos.size() <= 1:
		return
	for i: int in range(1, wpos.size()):
		var v: Vector2 = wpos[i] - wprev[i]
		wprev[i] = wpos[i]
		wpos[i] = wpos[i] + v + gravity * (delta * delta)
	wpos[0] = global_position
	wprev[0] = global_position
	for _iter: int in range(constraint_iterations):
		wpos[0] = global_position
		for j: int in range(1, wpos.size()):
			var d: Vector2 = wpos[j] - wpos[j - 1]
			var dist: float = d.length()
			if dist <= EPS:
				continue
			var diff: float = (dist - segment_length) / dist
			var off: Vector2 = d * diff
			if j == 1:
				wpos[j] -= off
			else:
				wpos[j - 1] += off * 0.5
				wpos[j] -= off * 0.5
		wpos[0] = global_position

func _refresh_line2d_points() -> void:
	if wpos.size() == 0:
		return
	if get_point_count() != wpos.size():
		clear_points()
		for _i: int in range(wpos.size()):
			add_point(Vector2.ZERO)
	for i: int in range(wpos.size()):
		set_point_position(i, to_local(wpos[i]))

func _update_bead_inventory() -> void:
	var resources: Array[int] = _get_resources()
	if resources.size() != last_resources_count:
		_sync_beads()
		last_resources_count = resources.size()
	var limit: int = min(beads.size(), resources.size())
	for i: int in range(limit):
		_set_bead_frame(beads[i].node, resources[i])

func _sync_beads(force: bool = false) -> void:
	var resources: Array[int] = _get_resources()
	_ensure_capacity(resources.size())
	var target_count: int = clampi(resources.size(), 0, _total_segments() - top_slack_segments)
	var current_count: int = beads.size()
	if force or target_count < current_count:
		for idx: int in range(current_count - 1, target_count - 1, -1):
			var rec_to_remove: BeadRec = beads[idx]
			if rec_to_remove and is_instance_valid(rec_to_remove.node):
				rec_to_remove.node.queue_free()
		beads.resize(target_count)
	if target_count > beads.size() and bead_scene:
		for _i: int in range(beads.size(), target_count):
			var bead_node: Node = bead_scene.instantiate()
			var bead_node2d: Node2D = bead_node as Node2D
			if bead_node2d == null:
				continue
			add_child(bead_node2d)
			var start_d: float = min(segment_length * 0.25, segment_length * float(_total_segments()))
			var rec: BeadRec = BeadRec.new()
			rec.node = bead_node2d
			rec.current_d = start_d
			rec.target_d = 0.0
			beads.append(rec)
	for i: int in range(beads.size()):
		if i < resources.size():
			_set_bead_frame(beads[i].node, resources[i])
		beads[i].target_d = _top_fill_slot_distance_for_index(i)

func _ensure_capacity(required_beads: int) -> void:
	var need_segments: int = max(required_beads + top_slack_segments, 1)
	var have_segments: int = _total_segments()
	if have_segments >= need_segments:
		return
	var to_add: int = need_segments - have_segments
	for _k: int in range(to_add):
		var last_idx: int = wpos.size() - 1
		var last: Vector2 = wpos[last_idx]
		var prev: Vector2 = wpos[last_idx - 1] if last_idx > 0 else last - Vector2(0.0, segment_length)
		var dir: Vector2 = (last - prev)
		var nlen: float = max(dir.length(), EPS)
		dir = dir / nlen
		if nlen <= EPS:
			dir = Vector2(0.0, 1.0).rotated(global_rotation)
		var new_p: Vector2 = last + dir * segment_length
		wpos.resize(wpos.size() + 1)
		wprev.resize(wprev.size() + 1)
		wpos[wpos.size() - 1] = new_p
		wprev[wprev.size() - 1] = new_p

func _get_resources() -> Array[int]:
	var out: Array[int] = []
	var any_val := GameManager.new_arcade_resources
	if any_val is Array:
		var arr: Array = any_val
		out.resize(arr.size())
		for i: int in range(arr.size()):
			out[i] = int(arr[i])
	return out

func _set_bead_frame(bead: Node2D, frame_val: int) -> void:
	if bead is Sprite2D:
		var s2d: Sprite2D = bead as Sprite2D
		s2d.frame = frame_val
		return
	var child: Node = bead.get_node_or_null("Sprite2D")
	if child and child is Sprite2D:
		var s2d_child: Sprite2D = child as Sprite2D
		s2d_child.frame = frame_val

func _top_fill_slot_distance_for_index(i: int) -> float:
	var total_segments: int = _total_segments()
	var slot_pt: int = max(top_slack_segments + 1, total_segments - i)
	return float(slot_pt) * segment_length

func _update_bead_animation(delta: float) -> void:
	if beads.size() == 0 or wpos.size() <= 1:
		return
	for i: int in range(beads.size()):
		var rec: BeadRec = beads[i]
		rec.current_d = move_toward(rec.current_d, rec.target_d, bead_slide_speed * delta)
		var world_at_d: Vector2 = _rope_world_pos_at_distance(rec.current_d)
		rec.node.global_position = world_at_d
		if bead_face_tangent:
			var tangent: Vector2 = _rope_world_tangent_at_distance(rec.current_d)
			rec.node.global_rotation = tangent.angle()

func _rope_world_pos_at_distance(d: float) -> Vector2:
	var total_len: float = float(_total_segments()) * segment_length
	var dd: float = clampf(d, 0.0, total_len)
	var seg_idx: int = int(floor(dd / segment_length))
	if seg_idx >= _total_segments():
		return wpos[_total_segments()]
	var base: float = float(seg_idx) * segment_length
	var seg_t: float = (dd - base) / max(segment_length, EPS)
	return wpos[seg_idx].lerp(wpos[seg_idx + 1], seg_t)

func _rope_world_tangent_at_distance(d: float) -> Vector2:
	var total_len: float = float(_total_segments()) * segment_length
	var dd: float = clampf(d, 0.0, total_len)
	var seg_idx: int = int(floor(dd / segment_length))
	if seg_idx >= _total_segments():
		seg_idx = _total_segments() - 1
	var tangent: Vector2 = wpos[seg_idx + 1] - wpos[seg_idx]
	var nlen: float = max(tangent.length(), EPS)
	return tangent / nlen

func _total_segments() -> int:
	return max(wpos.size() - 1, 0)

extends Line2D

@export var bead_scene: PackedScene
@export var gravity_hz: float = 0.5
@export var damping: float = 0.1
@export var inertia: float = 1.5
@export var vel_bias_gain: float = -0.005
@export var accel_drive_gain: float = 0.05
@export var distribution_power: float = 0.5

@onready var knot: Sprite2D = $Knot

const EPS: float = 0.0001
const SEG_LEN: float = 12.0
const INITIAL_BEAD_CAPACITY: int = 5
const TOP_SLACK_SEGMENTS: int = 3
const BEAD_SLIDE_SPEED: float = 110.0
const BEAD_FACE_TANGENT: bool = true

const REMOVE_MAX_RATE: float = 5.0
const REMOVE_START_RATE: float = 1.0
const REMOVE_ACCEL: float = 2.5

const VEL_SMOOTH: float = 0.16
const ACC_SMOOTH: float = 0.16
const SPATIAL_SMOOTH_PASSES: int = 1
const SPATIAL_ALPHA: float = 0.18

var wpos: PackedVector2Array
var wprev: PackedVector2Array
var ang: PackedFloat32Array

var zero_hold_time: float = 0.0
var remove_cooldown: float = 0.0

class BeadRec:
	var node: Node2D
	var current_d: float
	var target_d: float

class RemovingRec:
	var node: Node2D
	var t: float
	var start: Vector2
	var mid: Vector2

var beads: Array[BeadRec] = []
var removing: Array[RemovingRec] = []
var last_resources_count: int = -1

var _prev_anchor: Vector2
var _prev_vel: Vector2 = Vector2.ZERO
var _smooth_vel: Vector2 = Vector2.ZERO
var _smooth_acc: Vector2 = Vector2.ZERO
var _theta: float = 0.0
var _omega: float = 0.0

func _ready() -> void:
	_build_rope_world()
	_prev_anchor = global_position
	_refresh_line2d_points()
	_sync_beads(true)
	_update_knot()

func _physics_process(delta: float) -> void:
	_simulate_pendulum(delta)
	_refresh_line2d_points()
	_update_bead_inventory()
	_update_bead_animation(delta)
	_update_knot()
	_update_zero_hold(delta)
	_animate_removals(delta)

func _build_rope_world() -> void:
	var anchor: Vector2 = global_position
	var down: Vector2 = Vector2(0.0, 1.0).rotated(global_rotation)
	var total_segments: int = max(1, INITIAL_BEAD_CAPACITY + TOP_SLACK_SEGMENTS)
	wpos = PackedVector2Array()
	wprev = PackedVector2Array()
	ang = PackedFloat32Array()
	wpos.resize(total_segments + 1)
	wprev.resize(total_segments + 1)
	ang.resize(total_segments + 1)
	for i: int in range(total_segments + 1):
		var p: Vector2 = anchor + down * float(i) * SEG_LEN
		wpos[i] = p
		wprev[i] = p
		ang[i] = 0.0

func _simulate_pendulum(delta: float) -> void:
	if wpos.size() <= 1:
		return
	var anchor = global_position
	var vel = (anchor - _prev_anchor) / max(delta, 0.0001)
	_prev_anchor = anchor
	var a_v = 1.0 - exp(-delta / max(VEL_SMOOTH, 0.001))
	_smooth_vel = _smooth_vel.lerp(vel, a_v)
	var acc = (vel - _prev_vel) / max(delta, 0.0001)
	_prev_vel = vel
	var a_a = 1.0 - exp(-delta / max(ACC_SMOOTH, 0.001))
	_smooth_acc = _smooth_acc.lerp(acc, a_a)
	var omega = TAU * max(gravity_hz, 0.01)
	var k = omega * omega
	var zeta = clamp(1.0 - inertia, 0.05, 1.2)
	var c = 2.0 * zeta * omega
	var theta_bias = -_smooth_vel.x * vel_bias_gain
	var k_bias = 0.5 * k
	var drive = accel_drive_gain * _smooth_acc.x + k_bias * (theta_bias - _theta)
	_omega += (-k * sin(_theta) - c * _omega + drive) * delta
	_omega *= pow(damping, delta)
	_theta += _omega * delta
	wpos[0] = anchor
	wprev[0] = anchor
	var n = _total_segments()
	var down = Vector2(0, 1).rotated(global_rotation)
	if n >= 2 and SPATIAL_SMOOTH_PASSES > 0:
		for _p in range(SPATIAL_SMOOTH_PASSES):
			for i in range(1, n):
				var f0 = pow(float(i - 1) / float(n), distribution_power)
				var f1 = pow(float(i) / float(n), distribution_power)
				var f2 = pow(float(i + 1) / float(n), distribution_power)
				var a0 = _theta * f0
				var a1 = _theta * f1
				var a2 = _theta * f2
				var avg = 0.5 * (a0 + a2)
				var blended = lerp(a1, avg, SPATIAL_ALPHA)
				ang[i] = blended
	ang[n] = _theta
	var p = anchor
	for i in range(1, n + 1):
		if ang[i] == 0.0:
			ang[i] = _theta * pow(float(i) / float(n), distribution_power)
		var dir = down.rotated(ang[i])
		p = p + dir * SEG_LEN
		wprev[i] = wpos[i]
		wpos[i] = p

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
		if beads[i] != null:
			_set_bead_frame(beads[i].node, resources[i])

func _sync_beads(force: bool = false) -> void:
	var resources: Array[int] = _get_resources()
	_ensure_capacity(resources.size())
	var target_count: int = clampi(resources.size(), 0, _total_segments() - TOP_SLACK_SEGMENTS)
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
			var start_d: float = min(SEG_LEN * 0.25, SEG_LEN * float(_total_segments()))
			var rec: BeadRec = BeadRec.new()
			rec.node = bead_node2d
			rec.current_d = start_d
			rec.target_d = 0.0
			beads.append(rec)
	for i: int in range(beads.size()):
		if beads[i] == null:
			return
		if i < resources.size():
			_set_bead_frame(beads[i].node, resources[i])
		beads[i].target_d = _top_fill_slot_distance_for_index(i)
	_shrink_capacity(_get_resources().size())

func _ensure_capacity(required_beads: int) -> void:
	var need_segments: int = max(required_beads + TOP_SLACK_SEGMENTS, 1)
	var have_segments: int = _total_segments()
	if have_segments >= need_segments:
		return
	var to_add: int = need_segments - have_segments
	for _k: int in range(to_add):
		var last_idx: int = wpos.size() - 1
		var last: Vector2 = wpos[last_idx]
		var prev: Vector2 = wpos[last_idx - 1] if last_idx > 0 else last - Vector2(0.0, SEG_LEN)
		var dir: Vector2 = (last - prev)
		var nlen: float = max(dir.length(), EPS)
		dir = dir / nlen
		if nlen <= EPS:
			dir = Vector2(0.0, 1.0).rotated(global_rotation)
		var new_p: Vector2 = last + dir * SEG_LEN
		wpos.resize(wpos.size() + 1)
		wprev.resize(wprev.size() + 1)
		ang.resize(ang.size() + 1)
		wpos[wpos.size() - 1] = new_p
		wprev[wprev.size() - 1] = new_p
		ang[ang.size() - 1] = 0.0

func _get_resources() -> Array[int]:
	var out: Array[int] = []
	var any_val = GameManager.new_arcade_resources
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
	var slot_pt: int = max(TOP_SLACK_SEGMENTS + 1, total_segments - i)
	return float(slot_pt) * SEG_LEN

func _update_bead_animation(delta: float) -> void:
	if beads.size() == 0 or wpos.size() <= 1:
		return
	for i: int in range(beads.size()):
		if beads[i] != null:
			var rec: BeadRec = beads[i]
			rec.current_d = move_toward(rec.current_d, rec.target_d, BEAD_SLIDE_SPEED * delta)
			var world_at_d: Vector2 = _rope_world_pos_at_distance(rec.current_d)
			rec.node.global_position = world_at_d
			if BEAD_FACE_TANGENT:
				var tangent: Vector2 = _rope_world_tangent_at_distance(rec.current_d)
				rec.node.global_rotation = tangent.angle()

func _update_knot() -> void:
	if not is_instance_valid(knot) or wpos.size() == 0:
		return
	var last_idx: int = _total_segments()
	var wp: Vector2 = wpos[last_idx]
	knot.position = to_local(wp)
	var t: Vector2 = wp - wpos[max(last_idx - 1, 0)]
	if t.length() <= EPS:
		t = Vector2(0.0, 1.0).rotated(global_rotation)
	knot.rotation = t.angle() - PI / 2.0

func _rope_world_pos_at_distance(d: float) -> Vector2:
	var total_len: float = float(_total_segments()) * SEG_LEN
	var dd: float = clampf(d, 0.0, total_len)
	var seg_idx: int = int(floor(dd / SEG_LEN))
	if seg_idx >= _total_segments():
		return wpos[_total_segments()]
	var base: float = float(seg_idx) * SEG_LEN
	var seg_t: float = (dd - base) / max(SEG_LEN, EPS)
	return wpos[seg_idx].lerp(wpos[seg_idx + 1], seg_t)

func _rope_world_tangent_at_distance(d: float) -> Vector2:
	var total_len: float = float(_total_segments()) * SEG_LEN
	var dd: float = clampf(d, 0.0, total_len)
	var seg_idx: int = int(floor(dd / SEG_LEN))
	if seg_idx >= _total_segments():
		seg_idx = _total_segments() - 1
	var tangent: Vector2 = wpos[seg_idx + 1] - wpos[seg_idx]
	var nlen: float = max(tangent.length(), EPS)
	return tangent / nlen

func _update_zero_hold(delta: float) -> void:
	var held = Debug.expell_res
	if held:
		zero_hold_time += delta
		var rate = min(REMOVE_MAX_RATE, REMOVE_START_RATE + REMOVE_ACCEL * zero_hold_time)
		remove_cooldown -= delta
		while remove_cooldown <= 0.0:
			if beads.size() > 0:
				_begin_remove_one()
				remove_cooldown += 1.0 / max(rate, EPS)
			else:
				Debug.res_expelled = true
				remove_cooldown = 0.0
				break
	else:
		zero_hold_time = 0.0

func _begin_remove_one() -> void:
	if beads.is_empty():
		return
	var rec: BeadRec = beads.pop_back()
	if rec and is_instance_valid(rec.node):
		var start = rec.node.global_position
		var parent2d = get_parent() as Node2D
		var player_pos = parent2d.global_position if parent2d else global_position
		var fly_to = player_pos + Vector2(0.0, -50.0)
		var rr = RemovingRec.new()
		rr.node = rec.node
		rr.t = 0.0
		rr.start = start
		rr.mid = fly_to
		removing.append(rr)
	var res = _get_resources()
	if res.size() > 0:
		res.pop_back()
		GameManager.new_arcade_resources = res
	last_resources_count = -1

func _animate_removals(delta: float) -> void:
	if removing.is_empty():
		return
	for i in range(removing.size() - 1, -1, -1):
		var rr = removing[i]
		if not is_instance_valid(rr.node):
			removing.remove_at(i)
			continue
		rr.t += delta * 2.0
		var t = clampf(rr.t, 0.0, 1.0)
		var pos = rr.start.lerp(rr.mid, t)
		rr.node.global_position = pos
		rr.node.modulate.a = 1.0 - t
		if t >= 1.0:
			rr.node.queue_free()
			removing.remove_at(i)

func _shrink_capacity(required_beads: int) -> void:
	var have_segments: int = _total_segments()
	var min_segments: int = max(INITIAL_BEAD_CAPACITY + TOP_SLACK_SEGMENTS, 1)
	var need_segments: int = max(required_beads + TOP_SLACK_SEGMENTS, min_segments)
	if have_segments <= need_segments:
		return
	var to_trim = have_segments - need_segments
	for _i in range(to_trim):
		if wpos.size() > 1:
			wpos.resize(wpos.size() - 1)
			wprev.resize(wprev.size() - 1)
			ang.resize(ang.size() - 1)

func _total_segments() -> int:
	return max(wpos.size() - 1, 0)

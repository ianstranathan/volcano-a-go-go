extends Node

# ------------------------------------------------------------------------------
# AudioManager
# Owns audio playback and routing for:
# - local one-shot sounds
# - music
# - world one-shot sounds
# - tracked world loop sounds
#
# Gameplay code talks to audio through Events. AudioManager listens to those
# events, plays sounds locally, and replicates world audio when needed.
# ------------------------------------------------------------------------------

var local_pool_size: int = 6
var world_pool_size: int = 12

# Local audio
var music_voice: AudioStreamPlayer
var local_voice_state: Array[Dictionary] = []
var play_request_counter: int = 0

# World audio
var world_audio_root: Node2D
var world_voice_state: Array[Dictionary] = []
var world_play_request_counter: int = 0
var world_loops_active: Dictionary = {}


func _ready() -> void:
	if local_pool_size < 1:
		local_pool_size = 1
	
	if world_pool_size < 1:
		world_pool_size = 1
	
	_create_music_voice()
	_create_local_voices()
	_create_world_audio_root()
	_create_world_voices()
	
	Events.play_local_sound.connect(play_local)
	Events.play_music.connect(play_music)
	Events.stop_music.connect(stop_music)
	Events.play_world_sound.connect(play_world_sound)
	Events.start_world_loop.connect(start_world_loop)
	Events.stop_world_loop.connect(stop_world_loop)


func _process(_delta: float) -> void:
	# Active world loops follow their source node here.
	_update_world_loops()


# ------------------------------------------------------------------------------
# Shared voice-pool helpers
# Used by both local one-shot sounds and world one-shot sounds.
# ------------------------------------------------------------------------------
func _build_voice_state_entry(voice: Node, track_sound_id: bool = false) -> Dictionary:
	var state := {
		"voice": voice,
		"started_order": -1,
		"active": false,
	}
	
	if track_sound_id:
		state["sound_id"] = null
	
	return state


func _reset_voice_state(
	voice_state: Array[Dictionary],
	index: int,
	pool_name: String,
	clear_sound_id: bool = false
) -> void:
	if index < 0 or index >= voice_state.size():
		push_warning("AudioManager: Tried to reset invalid %s voice index: %s" % [pool_name, index])
		return
	
	if clear_sound_id:
		voice_state[index]["sound_id"] = null
	
	voice_state[index]["started_order"] = -1
	voice_state[index]["active"] = false


func _is_valid_voice_index(
	voice_state: Array[Dictionary],
	voice_index: int,
	pool_name: String
) -> bool:
	if voice_index < 0 or voice_index >= voice_state.size():
		push_warning("AudioManager: Tried to use invalid %s voice index: %s" % [pool_name, voice_index])
		return false
	
	return true


func _find_idle_voice(voice_state: Array[Dictionary]) -> int:
	for i in range(voice_state.size()):
		var state := voice_state[i]
		
		if not state["active"]:
			return i
	
	return -1


func _find_oldest_voice(voice_state: Array[Dictionary]) -> int:
	var oldest_index := -1
	var oldest_order := -1
	
	for i in range(voice_state.size()):
		var state := voice_state[i]
		
		if not state["active"]:
			continue
		
		var started_order: int = state["started_order"]
		
		if oldest_index == -1 or started_order < oldest_order:
			oldest_index = i
			oldest_order = started_order
	
	return oldest_index


func _find_available_voice(voice_state: Array[Dictionary]) -> int:
	var idle_index := _find_idle_voice(voice_state)
	if idle_index != -1:
		return idle_index
	
	return _find_oldest_voice(voice_state)


func _get_world_property(
	sound_def: Dictionary,
	world_overrides: Dictionary,
	key: String,
	fallback
):
	return world_overrides.get(key, sound_def.get(key, fallback))


func _apply_world_voice_settings(
	voice: AudioStreamPlayer2D,
	sound_def: Dictionary,
	world_position: Vector2,
	volume_db_offset: float,
	pitch_scale_mult: float,
	world_overrides: Dictionary
) -> void:
	voice.stream = sound_def.get("stream", null)
	voice.global_position = world_position
	voice.bus = sound_def.get("bus", &"Effects")
	voice.volume_db = sound_def.get("default_volume_db", 0.0) + volume_db_offset
	voice.pitch_scale = sound_def.get("default_pitch_scale", 1.0) * pitch_scale_mult
	voice.max_distance = _get_world_property(sound_def, world_overrides, "max_distance", 1200.0)
	voice.attenuation = _get_world_property(sound_def, world_overrides, "attenuation", 1.0)
	voice.panning_strength = _get_world_property(sound_def, world_overrides, "panning_strength", 1.0)


# ------------------------------------------------------------------------------
# Local sound playback
# ------------------------------------------------------------------------------
func _create_music_voice() -> void:
	music_voice = AudioStreamPlayer.new()
	music_voice.name = "MusicVoice"
	add_child(music_voice)


func _create_local_voices() -> void:
	local_voice_state.clear()
	
	for i in range(local_pool_size):
		var voice := AudioStreamPlayer.new()
		voice.name = "LocalVoice_%d" % i
		voice.finished.connect(_on_local_voice_finished.bind(i))
		
		add_child(voice)
		local_voice_state.append(_build_voice_state_entry(voice, true))


func _on_local_voice_finished(index: int) -> void:
	_reset_voice_state(local_voice_state, index, "local", true)


func _find_voice_playing_sound(sound_id: int) -> int:
	for i in range(local_voice_state.size()):
		var state := local_voice_state[i]
		
		if state["active"] and state["sound_id"] == sound_id:
			return i
	
	return -1


func _select_voice_for_local_sound(sound_id: int, playback_mode: int) -> int:
	var matching_index := _find_voice_playing_sound(sound_id)
	
	match playback_mode:
		AudioDb.PlaybackMode.RESTART:
			if matching_index != -1:
				return matching_index
			
			return _find_available_voice(local_voice_state)
		
		AudioDb.PlaybackMode.OVERLAP:
			return _find_available_voice(local_voice_state)
		
		AudioDb.PlaybackMode.IGNORE_IF_PLAYING:
			if matching_index != -1:
				return -1
			
			return _find_available_voice(local_voice_state)
		
		_:
			push_warning("AudioManager: Unknown playback mode: %s" % playback_mode)
			return -1


func _play_local_sound_on_voice(
	voice_index: int,
	sound_id: int,
	sound_def: Dictionary,
	volume_db_offset: float,
	pitch_scale_mult: float
) -> void:
	if not _is_valid_voice_index(local_voice_state, voice_index, "local"):
		return
	
	var stream = sound_def.get("stream", null)
	if stream == null:
		push_warning("AudioManager: Local sound is missing a stream for sound id: %s" % sound_id)
		return
	
	var voice: AudioStreamPlayer = local_voice_state[voice_index]["voice"]
	var bus: StringName = sound_def.get("bus", &"Master")
	var default_volume_db: float = sound_def.get("default_volume_db", 0.0)
	var default_pitch_scale: float = sound_def.get("default_pitch_scale", 1.0)
	
	if local_voice_state[voice_index]["active"]:
		voice.stop()
	
	voice.stream = stream
	voice.bus = bus
	voice.volume_db = default_volume_db + volume_db_offset
	voice.pitch_scale = default_pitch_scale * pitch_scale_mult
	
	play_request_counter += 1
	
	local_voice_state[voice_index]["sound_id"] = sound_id
	local_voice_state[voice_index]["started_order"] = play_request_counter
	local_voice_state[voice_index]["active"] = true
	voice.play()


func play_local(sound_id: int, volume_db_offset: float = 0.0, pitch_scale_mult: float = 1.0) -> void:
	var sound_def: Dictionary = AudioDb.local_sounds.get(sound_id, {})
	
	if sound_def.is_empty():
		push_warning("AudioManager: Unknown local sound id: %s" % sound_id)
		return
	
	var playback_mode: int = sound_def.get("playback_mode", AudioDb.PlaybackMode.RESTART)
	var voice_index := _select_voice_for_local_sound(sound_id, playback_mode)
	
	if voice_index == -1:
		return
	
	_play_local_sound_on_voice(
		voice_index,
		sound_id,
		sound_def,
		volume_db_offset,
		pitch_scale_mult
	)


# ------------------------------------------------------------------------------
# Music playback
# ------------------------------------------------------------------------------
func play_music(track_id: int, volume_db_offset: float = 0.0, pitch_scale_mult: float = 1.0) -> void:
	var track_def: Dictionary = AudioDb.music_tracks.get(track_id, {})
	
	if track_def.is_empty():
		push_warning("AudioManager: Unknown music track id: %s" % track_id)
		return
	
	var stream = track_def.get("stream", null)
	if stream == null:
		push_warning("AudioManager: Music track is missing a stream for track id: %s" % track_id)
		return
	
	var bus: StringName = track_def.get("bus", &"Music")
	var default_volume_db: float = track_def.get("default_volume_db", 0.0)
	var default_pitch_scale: float = track_def.get("default_pitch_scale", 1.0)
	
	music_voice.stop()
	music_voice.stream = stream
	music_voice.bus = bus
	music_voice.volume_db = default_volume_db + volume_db_offset
	music_voice.pitch_scale = default_pitch_scale * pitch_scale_mult
	music_voice.play()


func stop_music() -> void:
	if music_voice == null:
		return
	
	music_voice.stop()


# ------------------------------------------------------------------------------
# Replicated world one-shot playback
# ------------------------------------------------------------------------------
func _create_world_audio_root() -> void:
	world_audio_root = Node2D.new()
	world_audio_root.name = "WorldAudioRoot"
	add_child(world_audio_root)


func _create_world_voices() -> void:
	world_voice_state.clear()
	
	for i in range(world_pool_size):
		var voice := AudioStreamPlayer2D.new()
		voice.name = "WorldVoice_%d" % i
		voice.finished.connect(_on_world_voice_finished.bind(i))
		
		world_audio_root.add_child(voice)
		world_voice_state.append(_build_voice_state_entry(voice))


func _on_world_voice_finished(index: int) -> void:
	_reset_voice_state(world_voice_state, index, "world")


func _select_voice_for_world_sound() -> int:
	return _find_available_voice(world_voice_state)


func _play_world_sound_on_voice(
	voice_index: int,
	sound_id: int,
	world_position: Vector2,
	sound_def: Dictionary,
	volume_db_offset: float,
	pitch_scale_mult: float,
	world_overrides: Dictionary
) -> void:
	if not _is_valid_voice_index(world_voice_state, voice_index, "world"):
		return
	
	var stream = sound_def.get("stream", null)
	if stream == null:
		push_warning("AudioManager: World sound is missing a stream for sound id: %s" % sound_id)
		return
	
	var voice: AudioStreamPlayer2D = world_voice_state[voice_index]["voice"]
	
	if world_voice_state[voice_index]["active"]:
		voice.stop()
	
	_apply_world_voice_settings(
		voice,
		sound_def,
		world_position,
		volume_db_offset,
		pitch_scale_mult,
		world_overrides
	)
	
	world_play_request_counter += 1
	
	world_voice_state[voice_index]["started_order"] = world_play_request_counter
	world_voice_state[voice_index]["active"] = true
	voice.play()


func play_world_sound_local(
	sound_id: int,
	world_position: Vector2,
	volume_db_offset: float = 0.0,
	pitch_scale_mult: float = 1.0,
	world_overrides: Dictionary = {}
) -> void:
	var sound_def: Dictionary = AudioDb.world_sounds.get(sound_id, {})
	
	if sound_def.is_empty():
		push_warning("AudioManager: Unknown world sound id: %s" % sound_id)
		return
	
	var voice_index := _select_voice_for_world_sound()
	
	if voice_index == -1:
		return
	
	_play_world_sound_on_voice(
		voice_index,
		sound_id,
		world_position,
		sound_def,
		volume_db_offset,
		pitch_scale_mult,
		world_overrides
	)


func play_world_sound(
	sound_id: int,
	world_position: Vector2,
	volume_db_offset: float = 0.0,
	pitch_scale_mult: float = 1.0,
	world_overrides: Dictionary = {}
) -> void:
	# Play immediately on the local peer, then notify the other peers.
	play_world_sound_local(
		sound_id,
		world_position,
		volume_db_offset,
		pitch_scale_mult,
		world_overrides
	)
	
	if multiplayer.multiplayer_peer == null:
		return
	
	play_world_sound_remote.rpc(
		sound_id,
		world_position,
		volume_db_offset,
		pitch_scale_mult,
		world_overrides
	)


@rpc("any_peer", "call_remote", "unreliable")
func play_world_sound_remote(
	sound_id: int,
	world_position: Vector2,
	volume_db_offset: float = 0.0,
	pitch_scale_mult: float = 1.0,
	world_overrides: Dictionary = {}
) -> void:
	play_world_sound_local(
		sound_id,
		world_position,
		volume_db_offset,
		pitch_scale_mult,
		world_overrides
	)


# ------------------------------------------------------------------------------
# Tracked world loop playback
# ------------------------------------------------------------------------------
func _update_world_loops() -> void:
	# Loops follow their source node locally instead of receiving per-frame
	# position updates over the event bus or network.
	
	# NOTE: Loop replication currently resolves the source by NodePath. If matching
	# paths ever stop being stable across peers, this will need a stronger network id.
	for loop_key in world_loops_active.keys():
		var loop_state: Dictionary = world_loops_active[loop_key]
		var source: Node2D = loop_state.get("source", null)
		var voice: AudioStreamPlayer2D = loop_state.get("voice", null)
		
		if voice == null:
			continue
		
		if source == null:
			continue
		
		if not is_instance_valid(source):
			_stop_world_loop_local(loop_key)
			continue
		
		voice.global_position = source.global_position


func _build_world_loop_voice(loop_key: StringName) -> AudioStreamPlayer2D:
	var voice := AudioStreamPlayer2D.new()
	voice.name = "WorldLoop_%s" % loop_key
	world_audio_root.add_child(voice)
	return voice


func _start_world_loop_local(
	loop_key: StringName,
	loop_id: int,
	source: Node2D,
	start_position: Vector2,
	volume_db_offset: float = 0.0,
	pitch_scale_mult: float = 1.0,
	world_overrides: Dictionary = {}
) -> void:
	var loop_def: Dictionary = AudioDb.world_loops.get(loop_id, {})
	
	if loop_def.is_empty():
		push_warning("AudioManager: Unknown world loop id: %s" % loop_id)
		return
	
	var existing_loop: Dictionary = world_loops_active.get(loop_key, {})
	if not existing_loop.is_empty():
		var existing_voice: AudioStreamPlayer2D = existing_loop.get("voice", null)
		if existing_voice != null:
			existing_voice.stop()
			existing_voice.queue_free()
	
	var stream = loop_def.get("stream", null)
	if stream == null:
		push_warning("AudioManager: World loop is missing a stream for loop id: %s" % loop_id)
		return
	
	var voice := _build_world_loop_voice(loop_key)
	
	_apply_world_voice_settings(
		voice,
		loop_def,
		start_position,
		volume_db_offset,
		pitch_scale_mult,
		world_overrides
	)
	
	world_loops_active[loop_key] = {
		"voice": voice,
		"source": source,
		"loop_id": loop_id,
	}
	
	voice.play()


func _stop_world_loop_local(loop_key: StringName) -> void:
	var loop_state: Dictionary = world_loops_active.get(loop_key, {})
	if loop_state.is_empty():
		return
	
	var voice: AudioStreamPlayer2D = loop_state.get("voice", null)
	if voice != null:
		voice.stop()
		voice.queue_free()
	
	world_loops_active.erase(loop_key)


func start_world_loop(
	loop_key: StringName,
	loop_id: int,
	source: Node2D,
	volume_db_offset: float = 0.0,
	pitch_scale_mult: float = 1.0,
	world_overrides: Dictionary = {}
) -> void:
	# Start the loop locally, then notify the other peers.
	if source == null or not is_instance_valid(source):
		push_warning("AudioManager: Cannot start world loop without a valid source.")
		return
	
	_start_world_loop_local(
		loop_key,
		loop_id,
		source,
		source.global_position,
		volume_db_offset,
		pitch_scale_mult,
		world_overrides
	)
	
	if multiplayer.multiplayer_peer == null:
		return
	
	start_world_loop_remote.rpc(
		loop_key,
		loop_id,
		source.get_path(),
		source.global_position,
		volume_db_offset,
		pitch_scale_mult,
		world_overrides
	)


@rpc("any_peer", "call_remote", "reliable")
func start_world_loop_remote(
	loop_key: StringName,
	loop_id: int,
	source_path: NodePath,
	start_position: Vector2,
	volume_db_offset: float = 0.0,
	pitch_scale_mult: float = 1.0,
	world_overrides: Dictionary = {}
) -> void:
	var source := get_node_or_null(source_path) as Node2D
	
	_start_world_loop_local(
		loop_key,
		loop_id,
		source,
		start_position,
		volume_db_offset,
		pitch_scale_mult,
		world_overrides
	)


func stop_world_loop(loop_key: StringName) -> void:
	_stop_world_loop_local(loop_key)
	
	if multiplayer.multiplayer_peer == null:
		return
	
	stop_world_loop_remote.rpc(loop_key)


@rpc("any_peer", "call_remote", "reliable")
func stop_world_loop_remote(loop_key: StringName) -> void:
	_stop_world_loop_local(loop_key)

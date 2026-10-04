extends Node2D

# Puzzle Heroes - Level 1
# Step 2: the Match-3 board now controls an adventure path.
# Matching tiles damages the next obstacle; destroying it moves the hero forward.

const COLS := 7
const ROWS := 6
const CELL := 91.0
const BOARD_X := 40.0
const BOARD_Y := 690.0
const COLORS := [Color("45c95a"), Color("ef4545"), Color("ffc43d"), Color("4d8ff2"), Color("a957e8")]
const TILE_SYMBOLS := ["●", "■", "♛", "◆", "✦"]

const PATH_POINTS := [
    Vector2(105, 390),
    Vector2(225, 350),
    Vector2(350, 375),
    Vector2(475, 330),
    Vector2(610, 380)
]
const OBSTACLE_MAX_HP := [2, 2, 3, 2]

var board: Array = []
var score := 0
var moves := 25
var level_number := 1
var unlocked_level := 1
var stars := 0
var coins := 0
var level_coins := 0
var combo := 0
var best_score := 0
var campaign_complete := false
var screen_mode := "map"
var story_step := 0
var story_level := 0
var story_choice := 0
var unlocked_levels: Array = [1]
var level_stars: Array = [0,0,0,0,0,0,0,0,0,0,0]
var ability_hammer := 2
var ability_blast := 1
var ability_extra_moves := 1
var chests_opened := 0
var level_modifier := "NORMAL"
var boss_kind := "none"
var boss_max_hp := 0
var chest_reward := 0
var claimed_star_chests: Array = []
var daily_day := ""
var daily_kind := "matches"
var daily_target := 20
var daily_progress := 0
var daily_claimed := false
var hazards: Array = []
var boss_turn := 0
var boss_enraged := false
var world_flash := 0.0
var screen_transition := 0.0
var map_pulse := 0.0
var boss_intro := 0.0
var result_timer := 0.0
var star_reveal := 0.0
var reward_pop := 0.0
var unlock_flash := 0.0

var dragging := false
var drag_start := Vector2.ZERO
var drag_cell := Vector2i(-1, -1)
var drag_visual_pos := Vector2.ZERO
var active_touch_index := -1
var busy := false

var message := "Aligne 3 tuiles pour casser le rocher !"
var level_won := false
var level_lost := false

# Adventure state.
var obstacle_hp: Array[int] = []
var obstacle_index := 0
var hero_progress := 0
var hero_x := PATH_POINTS[0].x
var hero_y := PATH_POINTS[0].y
var hero_bounce := 0.0
var snake_x := PATH_POINTS[-1].x
var snake_alert := 0.0
var obstacle_flash := 0.0
var last_match_count := 0
var attack_flash := 0.0
var rescue_open := false
var combat_active := false
var snake_hp := 5
var snake_hit_flash := 0.0
var snake_recoil := 0.0
var snake_shake := 0.0
var hero_strike := 0.0
var rock_impact := 0.0
var rescue_celebration := 0.0
var rescue_confetti: Array = []
var effects: Array = []
var refill_anim := 1.0
var hero_attack := 0.0
var screen_shake := 0.0
var camera_zoom := 1.0
var camera_focus := Vector2(360, 640)
var camera_kick := Vector2.ZERO
var hero_anim_phase := 0.0
var snake_boss_phase := 0.0
var boss_pulse := 0.0
var cascade := 0
var combo_flash := 0.0
var fever := 0.0
var fever_flash := 0.0
var streak_best := 0
var near_miss_flash := 0.0

# Commercial tile animation state.
var tile_offset: Array = []
var tile_scale: Array = []
var tile_alpha: Array = []
var swap_animating := false
var swap_a := Vector2i(-1, -1)
var swap_b := Vector2i(-1, -1)
var swap_anim_t := 1.0
var swap_rejected := false
var collapse_animating := false
var booster_paths: Array = []
var vfx_rings: Array = []
var tile_trails: Array = []
var goal_kind := "rocks"
var goal_target := 4
var goal_progress := 0
var goal_color := 0
const SPECIAL_H := 5
const SPECIAL_V := 6
const SPECIAL_BOMB := 7
const SPECIAL_COLOR := 8

const HERO_TEX := preload("res://assets/art/hero.svg")
const SNAKE_TEX := preload("res://assets/art/snake.svg")
const ROCK_TEX := preload("res://assets/art/rock.svg")
const CAPTIVE_TEX := preload("res://assets/art/captive.svg")
const SCENE_TEX := preload("res://assets/art/scene.svg")
const GEMS_TEX := preload("res://assets/art/gems.svg")
const HERO_PRO_TEX := preload("res://assets/pack/hero_pro.svg")
const SNAKE_PRO_TEX := preload("res://assets/pack/boss_snake_pro.svg")
const GUARDIAN_PRO_TEX := preload("res://assets/pack/boss_guardian_pro.svg")
const BEAST_PRO_TEX := preload("res://assets/pack/boss_beast_pro.svg")
const DRAGON_PRO_TEX := preload("res://assets/pack/boss_dragon_pro.svg")
const CAPTIVE_PRO_TEX := preload("res://assets/pack/captive_pro.svg")
const RUINS_ENV_TEX := preload("res://assets/pack/ruins.svg")
const PARTICLE_TEX := preload("res://assets/pack/particle_glow.svg")

# Premium Content 7: authored 2D animation state.
var art_idle_phase := 0.0
var art_attack_phase := 0.0
var art_hit_flash := 0.0
var art_defeat_phase := 0.0

# Premium Content 8: layered VFX / cinematic attack state.
var impact_bursts: Array = []
var slash_effects: Array = []
var boss_projectiles: Array = []
var defeat_burst := 0.0
var transition_phase := 0.0
var juice_pulse := 0.0
var boss_phase := "idle"
var boss_phase_t := 0.0
var boss_attack_id := 0
var boss_attack_cooldown := 0.0
var guardian_shield := false
var guardian_shield_break := 0.0
var beast_rage_sequence := 0.0
var snake_poison_sequence := 0.0
var dragon_breath_sequence := 0.0
var dragon_breath_variant := 0
var boss_damage_window := false
# Premium Content 10: real sprite/particle combat layer.
var hero_sprite: AnimatedSprite2D
var boss_sprite: AnimatedSprite2D
var combat_particles: GPUParticles2D
var boss_particles: GPUParticles2D
var combat_layer: Node2D
var sprite_anim_state := "idle"
var boss_ai_timer := 0.0
var boss_ai_pattern := 0
var combat_boss_kind := ""

# Premium Content 11: procedural audio system (SFX + adaptive music).
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var music_playback: AudioStreamGeneratorPlayback
var audio_ready := false
var audio_time := 0.0
var music_bar := 0
var sfx_cursor := 0

func _ready() -> void:
    randomize()
    _setup_combat_nodes()
    _setup_audio_system()
    _load_progress()
    _refresh_daily_quest()
    screen_mode = "map"
    queue_redraw()

func _process(delta: float) -> void:
    audio_time += delta
    _update_music_audio()
    hero_bounce += delta * 5.0
    art_idle_phase += delta * 4.0
    art_attack_phase = maxf(0.0, art_attack_phase - delta * 3.8)
    art_hit_flash = maxf(0.0, art_hit_flash - delta * 5.5)
    art_defeat_phase = maxf(0.0, art_defeat_phase - delta * 1.8)
    defeat_burst = maxf(0.0, defeat_burst - delta * 1.4)
    transition_phase += delta * 6.0
    juice_pulse = maxf(0.0, juice_pulse - delta * 4.0)
    _update_boss_combat(delta)
    _update_combat_sprite_layer(delta)
    _update_impact_bursts(delta)
    _update_slash_effects(delta)
    _update_boss_projectiles(delta)
    hero_anim_phase += delta * 7.0
    snake_boss_phase += delta * (2.2 if combat_active else 1.1)
    boss_pulse = maxf(0.0, boss_pulse - delta * 2.2)
    snake_alert = maxf(0.0, snake_alert - delta * 2.5)
    obstacle_flash = maxf(0.0, obstacle_flash - delta * 3.5)
    attack_flash = maxf(0.0, attack_flash - delta * 4.0)
    snake_hit_flash = maxf(0.0, snake_hit_flash - delta * 5.0)
    snake_recoil = maxf(0.0, snake_recoil - delta * 4.5)
    snake_shake = maxf(0.0, snake_shake - delta * 5.5)
    hero_strike = maxf(0.0, hero_strike - delta * 5.0)
    rock_impact = maxf(0.0, rock_impact - delta * 4.5)
    rescue_celebration = maxf(0.0, rescue_celebration - delta * 1.6)
    _update_rescue_confetti(delta)
    refill_anim = minf(1.0, refill_anim + delta * 3.8)
    hero_attack = maxf(0.0, hero_attack - delta * 3.8)
    screen_shake = maxf(0.0, screen_shake - delta * 4.0)
    camera_zoom = lerpf(camera_zoom, 1.0, minf(1.0, delta * 7.0))
    camera_kick = camera_kick.lerp(Vector2.ZERO, minf(1.0, delta * 9.0))
    combo_flash = maxf(0.0, combo_flash - delta * 2.8)
    fever = maxf(0.0, fever - delta)
    world_flash = maxf(0.0, world_flash - delta * 2.5)
    screen_transition = maxf(0.0, screen_transition - delta * 2.8)
    map_pulse += delta * 2.0
    boss_intro = maxf(0.0, boss_intro - delta)
    result_timer += delta
    if level_won or level_lost:
        star_reveal = minf(3.0, star_reveal + delta * 2.7)
        reward_pop = minf(1.0, reward_pop + delta * 3.5)
    unlock_flash = maxf(0.0, unlock_flash - delta * 3.0)
    fever_flash = maxf(0.0, fever_flash - delta * 3.0)
    near_miss_flash = maxf(0.0, near_miss_flash - delta * 3.5)
    _update_tile_animations(delta)
    _update_booster_paths(delta)
    _update_vfx_rings(delta)
    _update_tile_trails(delta)
    _update_effects(delta)
    queue_redraw()

func _setup_audio_system() -> void:
    if audio_ready:
        return
    for i in range(6):
        var p := AudioStreamPlayer.new()
        p.name = "SFX_%d" % i
        p.volume_db = -5.0
        add_child(p)
        sfx_players.append(p)
    music_player = AudioStreamPlayer.new()
    music_player.name = "AdaptiveMusic"
    music_player.volume_db = -18.0
    add_child(music_player)
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = 44100.0
    stream.buffer_length = 0.45
    music_player.stream = stream
    music_player.play()
    music_playback = music_player.get_stream_playback() as AudioStreamGeneratorPlayback
    audio_ready = music_playback != null

func _make_tone_stream(frequency: float, duration: float, volume: float = 0.22, noise: float = 0.0) -> AudioStreamGenerator:
    var stream := AudioStreamGenerator.new()
    stream.mix_rate = 44100.0
    stream.buffer_length = maxf(0.08, duration + 0.03)
    return stream

func _play_sfx(kind: String, intensity: float = 1.0) -> void:
    if not audio_ready or sfx_players.is_empty():
        return
    var player := sfx_players[sfx_cursor]
    sfx_cursor = (sfx_cursor + 1) % sfx_players.size()
    var stream := _make_tone_stream(440.0, 0.12)
    player.stream = stream
    player.volume_db = -5.0 if kind != "boss" else -3.0
    player.play()
    var pb := player.get_stream_playback() as AudioStreamGeneratorPlayback
    if pb == null:
        return
    var sr := 44100.0
    var duration := 0.12
    var base := 440.0
    match kind:
        "swap":
            base = 330.0
            duration = 0.07
        "match":
            base = 520.0 + 55.0 * clampf(intensity, 0.0, 5.0)
            duration = 0.10
        "combo":
            base = 660.0 + 90.0 * clampf(intensity, 0.0, 5.0)
            duration = 0.16
        "booster":
            base = 740.0
            duration = 0.20
        "boss":
            base = 150.0
            duration = 0.28
        "hit":
            base = 210.0
            duration = 0.12
        "win":
            base = 660.0
            duration = 0.45
        "lose":
            base = 180.0
            duration = 0.40
        "rescue":
            base = 880.0
            duration = 0.35
    var frames := int(sr * duration)
    for i in range(mini(frames, pb.get_frames_available())):
        var t := float(i) / sr
        var env := minf(1.0, t * 55.0) * maxf(0.0, 1.0 - t / duration)
        var freq := base * (1.0 + 0.035 * sin(t * 31.0))
        if kind == "win":
            freq = base * (1.0 + 0.5 * sin(t * TAU * 2.0))
        elif kind == "combo":
            freq = base * (1.0 + 0.12 * sin(t * 18.0))
        var sample := sin(TAU * freq * t) * env * 0.24
        sample += sin(TAU * freq * 2.01 * t) * env * 0.08
        if noise > 0.0:
            sample += randf_range(-noise, noise) * env
        pb.push_frame(Vector2(sample, sample))

func _update_music_audio() -> void:
    if not audio_ready or music_playback == null:
        return
    var available := music_playback.get_frames_available()
    if available <= 0:
        return
    var sr := 44100.0
    var tempo := 104.0 if not combat_active else 124.0
    var beat := 60.0 / tempo
    var notes := [261.63, 329.63, 392.0, 523.25, 392.0, 329.63, 293.66, 440.0]
    for i in range(available):
        var t := audio_time - float(available - i) / sr
        var step := int(floor(t / (beat * 0.5))) % notes.size()
        var local := fmod(t, beat * 0.5)
        var freq := notes[step]
        if combat_active:
            freq *= 0.5
        var env := 0.035 * maxf(0.0, 1.0 - local / (beat * 0.5))
        var sample := sin(TAU * freq * t) * env
        sample += sin(TAU * freq * 2.0 * t) * env * 0.22
        if fever > 0.0:
            sample += sin(TAU * freq * 4.0 * t) * 0.018
        music_playback.push_frame(Vector2(sample, sample))

func _setup_combat_nodes() -> void:
    combat_layer = Node2D.new()
    combat_layer.name = "CombatAnimationLayer"
    add_child(combat_layer)

    hero_sprite = AnimatedSprite2D.new()
    hero_sprite.name = "HeroCombatSprite"
    hero_sprite.sprite_frames = _make_sprite_frames(HERO_PRO_TEX)
    hero_sprite.animation = &"idle"
    hero_sprite.centered = true
    hero_sprite.position = Vector2(hero_x, hero_y)
    hero_sprite.scale = Vector2(0.72, 0.72)
    combat_layer.add_child(hero_sprite)

    boss_sprite = AnimatedSprite2D.new()
    boss_sprite.name = "BossCombatSprite"
    boss_sprite.sprite_frames = _make_sprite_frames(SNAKE_PRO_TEX)
    boss_sprite.animation = &"idle"
    boss_sprite.centered = true
    boss_sprite.position = Vector2(575, 330)
    boss_sprite.scale = Vector2(0.82, 0.82)
    combat_layer.add_child(boss_sprite)

    combat_particles = _make_particles("HeroCombatParticles", Color("ffe17a"))
    combat_layer.add_child(combat_particles)
    boss_particles = _make_particles("BossCombatParticles", Color("ff704f"))
    combat_layer.add_child(boss_particles)

func _make_sprite_frames(texture: Texture2D) -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.remove_animation(&"default")
    for anim in [&"idle", &"attack", &"hit", &"defeat"]:
        frames.add_animation(anim)
        frames.set_animation_speed(anim, 8.0 if anim == &"idle" else 12.0)
        frames.set_animation_loop(anim, anim == &"idle")
        for i in range(4 if anim == &"idle" else 3):
            var frame := AtlasTexture.new()
            frame.atlas = texture
            frames.add_frame(anim, frame)
    return frames

func _make_particles(node_name: String, tint: Color) -> GPUParticles2D:
    var p := GPUParticles2D.new()
    p.name = node_name
    p.amount = 28
    p.lifetime = 0.65
    p.one_shot = false
    p.emitting = false
    p.texture = PARTICLE_TEX
    p.modulate = tint
    var material := ParticleProcessMaterial.new()
    material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    material.emission_sphere_radius = 18.0
    material.direction = Vector3(0, -1, 0)
    material.spread = 180.0
    material.initial_velocity_min = 45.0
    material.initial_velocity_max = 130.0
    material.gravity = Vector3(0, 170.0, 0)
    material.scale_min = 0.25
    material.scale_max = 0.65
    material.color = tint
    p.process_material = material
    return p

func _set_combat_animation(state: String) -> void:
    sprite_anim_state = state
    if hero_sprite and hero_sprite.sprite_frames.has_animation(state):
        hero_sprite.play(state)
    if boss_sprite and boss_sprite.sprite_frames.has_animation(state):
        boss_sprite.play(state)

func _emit_combat_particles(hero: bool, amount: int = 18) -> void:
    var p := combat_particles if hero else boss_particles
    if not p:
        return
    p.amount = amount
    p.restart()
    p.emitting = true

func _update_combat_sprite_layer(delta: float) -> void:
    if not hero_sprite or not boss_sprite:
        return
    hero_sprite.position = Vector2(hero_x, hero_y - 18.0)
    boss_sprite.position = Vector2(snake_x if boss_kind == "snake" else 575.0, 330.0)
    if screen_mode != "level":
        hero_sprite.visible = false
        boss_sprite.visible = false
        combat_particles.emitting = false
        boss_particles.emitting = false
        return
    hero_sprite.visible = true
    boss_sprite.visible = combat_active and not level_won
    if boss_kind != combat_boss_kind:
        if boss_kind == "guardian":
            boss_sprite.sprite_frames = _make_sprite_frames(GUARDIAN_PRO_TEX)
        elif boss_kind == "beast":
            boss_sprite.sprite_frames = _make_sprite_frames(BEAST_PRO_TEX)
        elif boss_kind == "dragon":
            boss_sprite.sprite_frames = _make_sprite_frames(DRAGON_PRO_TEX)
        else:
            boss_sprite.sprite_frames = _make_sprite_frames(SNAKE_PRO_TEX)
        combat_boss_kind = boss_kind
    if boss_phase == "windup":
        boss_sprite.scale = Vector2.ONE * (0.82 + sin(boss_phase_t * 14.0) * 0.045)
    elif boss_phase == "impact":
        boss_sprite.scale = Vector2.ONE * 0.90
        boss_sprite.rotation = sin(boss_phase_t * 38.0) * 0.045
    else:
        boss_sprite.scale = Vector2.ONE * (0.82 + sin(art_idle_phase) * 0.018)
        boss_sprite.rotation = 0.0
    hero_sprite.scale = Vector2.ONE * (0.72 + sin(art_idle_phase * 0.8) * 0.012)
    if boss_phase == "recovery":
        hero_sprite.play(&"hit" if boss_damage_window else &"idle")
    elif boss_phase == "windup":
        boss_sprite.play(&"attack")
    elif boss_phase == "impact":
        boss_sprite.play(&"attack")
    elif level_won:
        boss_sprite.play(&"defeat")
    else:
        boss_sprite.play(&"idle")

func _update_boss_combat(delta: float) -> void:
    if not combat_active or level_won:
        boss_phase = "idle"
        boss_phase_t = 0.0
        return
    boss_phase_t += delta
    boss_attack_cooldown = maxf(0.0, boss_attack_cooldown - delta)
    if boss_phase == "idle":
        if boss_attack_cooldown <= 0.0 and boss_intro <= 0.0:
            _start_boss_attack()
    elif boss_phase == "windup":
        if boss_phase_t >= 0.46:
            boss_phase = "impact"
            boss_phase_t = 0.0
            _execute_boss_attack()
    elif boss_phase == "impact":
        if boss_phase_t >= 0.18:
            boss_phase = "recovery"
            boss_phase_t = 0.0
    elif boss_phase == "recovery":
        if boss_phase_t >= 0.42:
            boss_phase = "idle"
            boss_phase_t = 0.0
            boss_attack_cooldown = 0.55

func _start_boss_attack() -> void:
    boss_phase = "windup"
    boss_phase_t = 0.0
    boss_attack_id = boss_turn % 3
    boss_turn += 1
    _play_sfx("boss", 0.8)

func _execute_boss_attack() -> void:
    _play_sfx("hit", 1.0)
    _emit_combat_particles(false, 28)
    _spawn_attack_effects(3 + boss_attack_id * 2)
    screen_shake = maxf(screen_shake, 0.20)
    match boss_kind:
        "snake":
            snake_poison_sequence = 0.75
        "guardian":
            guardian_shield = boss_attack_id == 0
        "beast":
            beast_rage_sequence = 0.75
        "dragon":
            dragon_breath_sequence = 0.95
            dragon_breath_variant = boss_attack_id

func _new_level() -> void:
    board.clear()
    tile_offset.clear()
    tile_scale.clear()
    tile_alpha.clear()
    for y in ROWS:
        tile_offset.append([])
        tile_scale.append([])
        tile_alpha.append([])
    for y in ROWS:
        var row: Array = []
        for x in COLS:
            var value := randi() % COLORS.size()
            while x >= 2 and row[x - 1] == value and row[x - 2] == value:
                value = randi() % COLORS.size()
            while y >= 2 and board[y - 1][x] == value and board[y - 2][x] == value:
                value = randi() % COLORS.size()
            row.append(value)
            tile_offset[y].append(Vector2.ZERO)
            tile_scale[y].append(1.0)
            tile_alpha[y].append(1.0)
        board.append(row)

    score = 0
    moves = 24 + level_number * 2
    level_modifier = "NORMAL"
    boss_kind = boss_for_level(level_number)
    boss_max_hp = 0
    match level_number:
        2:
            moves = 22
            level_modifier = "سباق جمع"
        3:
            moves = 26
            level_modifier = "زعيم الأفعى"
        4:
            moves = 20
            level_modifier = "بوستر أولاً"
        5:
            moves = 18
            level_modifier = "جليد • لا يذوب إلا بالضرب"
        6:
            moves = 27
            level_modifier = "زعيم الحارس • درع + أقفاص"
        7:
            moves = 21
            level_modifier = "سلسلة خاصة"
        8:
            moves = 19
            level_modifier = "جليد • جمع سريع"
        9:
            moves = 28
            level_modifier = "زعيم الوحش • غضب + أقفاص"
        10:
            moves = 32
            level_modifier = "التنين • لعنة + فوضى"
    match world_id(level_number):
        2:
            moves = max(18, moves - 1)
            level_modifier += " • صقيع"
        3:
            moves = max(18, moves - 1)
            level_modifier += " • كروم"
        4:
            level_modifier += " • قلعة"
    if boss_kind != "none":
        boss_max_hp = 5 + int(level_number / 3) * 2
        snake_hp = boss_max_hp
    level_coins = 0
    combo = 0
    cascade = 0
    fever = 0.0
    fever_flash = 0.0
    streak_best = 0
    near_miss_flash = 0.0
    combo_flash = 0.0
    star_reveal = 0.0
    reward_pop = 0.0
    boss_intro = 0.0
    result_timer = 0.0
    obstacle_hp.clear()
    for hp in OBSTACLE_MAX_HP:
        obstacle_hp.append(hp)

    obstacle_index = 0
    hero_progress = 0
    hero_x = PATH_POINTS[0].x
    hero_y = PATH_POINTS[0].y
    snake_x = PATH_POINTS[-1].x
    snake_alert = 0.0
    obstacle_flash = 0.0
    last_match_count = 0
    attack_flash = 0.0
    rescue_open = false
    combat_active = false
    snake_hp = 5
    snake_hit_flash = 0.0
    snake_recoil = 0.0
    snake_shake = 0.0
    hero_strike = 0.0
    rock_impact = 0.0
    rescue_celebration = 0.0
    rescue_confetti.clear()
    effects.clear()
    refill_anim = 1.0
    hero_attack = 0.0
    art_attack_phase = 0.0
    art_hit_flash = 0.0
    art_defeat_phase = 0.0
    screen_shake = 0.0
    swap_animating = false
    collapse_animating = false
    booster_paths.clear()
    vfx_rings.clear()
    tile_trails.clear()
    impact_bursts.clear()
    slash_effects.clear()
    boss_projectiles.clear()
    defeat_burst = 0.0
    juice_pulse = 0.0
    hazards.clear()
    for y in ROWS:
        hazards.append([])
        for x in COLS:
            hazards[y].append(0)
    boss_turn = 0
    boss_enraged = false
    boss_phase = "idle"
    boss_phase_t = 0.0
    combat_boss_kind = ""
    boss_attack_id = 0
    boss_attack_cooldown = 0.0
    guardian_shield = false
    guardian_shield_break = 0.0
    beast_rage_sequence = 0.0
    snake_poison_sequence = 0.0
    dragon_breath_sequence = 0.0
    dragon_breath_variant = 0
    boss_damage_window = false
    world_flash = 0.0
    _configure_level_hazards()

    _configure_level_goal()
    message = _level_objective() + " • " + level_modifier
    level_won = false
    level_lost = false
    busy = false

func _draw() -> void:
    draw_rect(Rect2(0, 0, 720, 1280), Color("17120f"))
    if screen_mode == "map":
        _draw_campaign_map()
        return
    if screen_mode == "story":
        _draw_story_screen()
        return
    var impact := sin((1.0 - screen_shake) * PI) if screen_shake > 0.0 else 0.0
    camera_kick = Vector2(sin(hero_anim_phase * 17.0), cos(hero_anim_phase * 13.0)) * screen_shake * 7.0
    draw_set_transform(camera_kick, 0.0, Vector2.ONE * camera_zoom)
    _draw_top_hud()
    _draw_rescue_scene()
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    _draw_board()
    _draw_tile_trails()
    _draw_vfx_rings()
    _draw_effects()
    _draw_impact_bursts()
    _draw_slash_effects()
    _draw_boss_projectiles()
    _draw_rescue_confetti()
    _draw_rescue_badge()
    if level_won or level_lost:
        _draw_end_panel()
    if screen_transition > 0.0:
        draw_rect(Rect2(0, 0, 720, 1280), Color(0.03, 0.02, 0.02, screen_transition))
    if boss_intro > 0.0 and combat_active:
        _draw_boss_cinematic()

func _configure_level_hazards() -> void:
    match world_id(level_number):
        2:
            for cell in [Vector2i(0, 0), Vector2i(6, 0), Vector2i(0, 5), Vector2i(6, 5)]:
                hazards[cell.y][cell.x] = 1
        3:
            for cell in [Vector2i(0, 2), Vector2i(6, 2), Vector2i(1, 5), Vector2i(5, 5)]:
                hazards[cell.y][cell.x] = 2
        4:
            for cell in [Vector2i(1, 1), Vector2i(5, 1), Vector2i(3, 3)]:
                hazards[cell.y][cell.x] = 3
    match level_number:
        5:
            for cell in [Vector2i(1, 1), Vector2i(3, 1), Vector2i(5, 1), Vector2i(2, 4), Vector2i(4, 4)]:
                hazards[cell.y][cell.x] = 1
        6:
            for cell in [Vector2i(0, 2), Vector2i(6, 2), Vector2i(1, 4), Vector2i(5, 4)]:
                hazards[cell.y][cell.x] = 2
        8:
            for cell in [Vector2i(1, 0), Vector2i(5, 0), Vector2i(0, 5), Vector2i(6, 5), Vector2i(3, 3)]:
                hazards[cell.y][cell.x] = 1
        9:
            for cell in [Vector2i(0, 1), Vector2i(6, 1), Vector2i(0, 4), Vector2i(6, 4)]:
                hazards[cell.y][cell.x] = 2
        10:
            for cell in [Vector2i(1, 1), Vector2i(5, 1), Vector2i(1, 4), Vector2i(5, 4), Vector2i(3, 2)]:
                hazards[cell.y][cell.x] = 3

func _configure_level_goal() -> void:
    goal_progress = 0
    goal_color = (level_number - 1) % COLORS.size()
    match level_number:
        2, 8:
            goal_kind = "collect"
            goal_target = 12 + level_number
        5:
            goal_kind = "collect"
            goal_target = 18
        4, 7:
            goal_kind = "special"
            goal_target = 2
        _:
            goal_kind = "rocks"
            goal_target = obstacle_hp.size()

func world_id(value: int) -> int:
    if value <= 3:
        return 1
    if value <= 6:
        return 2
    if value <= 9:
        return 3
    return 4

func world_name(value: int) -> String:
    match world_id(value):
        1:
            return "وادي الأطلال"
        2:
            return "قمم الجليد"
        3:
            return "غابة الأنياب"
        4:
            return "قلعة التنين"
        _:
            return "المملكة"

func world_rule(value: int) -> String:
    match world_id(value):
        1:
            return "حجارة • سلاسل"
        2:
            return "جليد • سقوط متجمد"
        3:
            return "كروم • أقفاص"
        4:
            return "لعنة • فوضى"
        _:
            return ""

func world_between_event(value: int) -> String:
    match value:
        3:
            return "حدث قصير: خرج الأبطال من الوادي. الجبال المتجمدة أمامهم."
        6:
            return "حدث قصير: ذاب الجدار الجليدي. آثار الوحش تقود إلى الغابة."
        9:
            return "حدث قصير: انفتحت بوابة التنين. هذه آخر رحلة في الحملة."
        _:
            return ""

func _level_objective() -> String:
    match goal_kind:
        "collect":
            return "COLLECTE %d %s" % [goal_target, TILE_SYMBOLS[goal_color]]
        "special":
            return "CRÉE %d BOOSTERS" % goal_target
        _:
            return "DÉTRUIS LES OBSTACLES"

func _start_level(selected_level: int) -> void:
    if not _is_level_unlocked(selected_level):
        return
    level_number = selected_level
    if selected_level in [3, 6, 9, 10]:
        story_level = selected_level
        story_step = 0
        story_choice = 0
        screen_mode = "story"
        queue_redraw()
        return
    screen_mode = "level"
    screen_transition = 1.0
    result_timer = 0.0
    _new_level()

func _start_story_level() -> void:
    screen_mode = "level"
    _new_level()
    queue_redraw()

func _handle_story_tap(pos: Vector2) -> void:
    if story_step == 0:
        if pos.y >= 860 and pos.y <= 970:
            story_choice = 1
            story_step = 1
            queue_redraw()
        elif pos.y >= 990 and pos.y <= 1100:
            story_choice = 2
            story_step = 1
            queue_redraw()
    else:
        if pos.y >= 1000 and pos.y <= 1160:
            _start_story_level()

func _story_character_name() -> String:
    match story_level:
        3:
            return "البطل • الأفعى"
        6:
            return "البطل • الحارس"
        9:
            return "البطل • الوحش"
        10:
            return "البطل • التنين"
        _:
            return "الأبطال"

func _story_title() -> String:
    match story_level:
        3:
            return "بوابة وادي الأطلال"
        6:
            return "حارس قمم الجليد"
        9:
            return "قلب غابة الأنياب"
        10:
            return "المواجهة الأخيرة"
        _:
            return world_name(story_level)

func _story_body() -> String:
    match story_level:
        3:
            return "وصل الأبطال إلى قلب الأطلال. الأفعى تحرس الطريق، لكن خلفها بوابة إلى قمم الجليد."
        6:
            return "الحارس أغلق الممر الجليدي. لا يمكن العبور إلا بكسر درعه وإثبات قوة الأبطال."
        9:
            return "في أعماق الغابة ينتظر الوحش. القرار الآن: اندفع بسرعة، أو حضّر أقوى Boosters قبل المواجهة."
        10:
            return "وصل الأبطال إلى قلعة التنين. هذه المعركة ستحدد مصير المملكة."
        _:
            return ""

func _story_choice_text() -> String:
    if story_choice == 1:
        return "سنهاجم الآن!"
    if story_choice == 2:
        return "سنجهز أنفسنا أولاً."
    return "اختر قرارك"

func _draw_story_screen() -> void:
    var wid := world_id(story_level)
    var bg := Color("24180f")
    var accent := Color("e9b62f")
    match wid:
        2:
            bg = Color("132b38")
            accent = Color("72d8ff")
        3:
            bg = Color("142b1a")
            accent = Color("7bdc68")
        4:
            bg = Color("2c1232")
            accent = Color("c77cff")
    draw_rect(Rect2(0, 0, 720, 1280), bg)
    draw_rect(Rect2(24, 24, 672, 1232), accent, false, 5)
    draw_string(ThemeDB.fallback_font, Vector2(48, 82), world_name(story_level), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, accent)
    draw_string(ThemeDB.fallback_font, Vector2(48, 145), _story_title(), HORIZONTAL_ALIGNMENT_LEFT, 620, 34, Color("fff0bd"))
    # Distinct boss presentation per world.
    draw_texture_rect(HERO_PRO_TEX, Rect2(55, 220, 250, 320), false)
    _draw_boss_character(Vector2(500, 335), true)
    draw_rect(Rect2(55, 565, 610, 260), Color(0.04,0.03,0.025,0.94))
    draw_string(ThemeDB.fallback_font, Vector2(80, 615), _story_character_name(), HORIZONTAL_ALIGNMENT_LEFT, 550, 22, Color("ffe17a"))
    draw_string(ThemeDB.fallback_font, Vector2(80, 670), _story_body(), HORIZONTAL_ALIGNMENT_LEFT, 550, 19, Color("f3ead8"))
    if story_step == 0:
        draw_rect(Rect2(55, 860, 610, 92), Color("8e5424"))
        draw_string(ThemeDB.fallback_font, Vector2(110, 918), "⚔  نهاجم الآن", HORIZONTAL_ALIGNMENT_LEFT, 500, 23, Color.WHITE)
        draw_rect(Rect2(55, 990, 610, 92), Color("3f5e42"))
        draw_string(ThemeDB.fallback_font, Vector2(110, 1048), "◆  نحضّر الـBoosters", HORIZONTAL_ALIGNMENT_LEFT, 500, 23, Color.WHITE)
    else:
        draw_string(ThemeDB.fallback_font, Vector2(85, 890), _story_choice_text(), HORIZONTAL_ALIGNMENT_LEFT, 540, 25, accent)
        draw_string(ThemeDB.fallback_font, Vector2(85, 950), "القرار اتخذ. المعركة تبدأ الآن.", HORIZONTAL_ALIGNMENT_LEFT, 540, 20, Color("e8dcc8"))
        draw_rect(Rect2(90, 1010, 540, 100), accent)
        draw_string(ThemeDB.fallback_font, Vector2(235, 1073), "ابدأ المعركة", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("21150f"))
    draw_string(ThemeDB.fallback_font, Vector2(48, 1215), "قرارك يغيّر العرض والرسالة — وليس صعوبة المستوى.", HORIZONTAL_ALIGNMENT_LEFT, 620, 15, Color("cbbda8"))

func _is_level_unlocked(value: int) -> bool:
    return value in unlocked_levels

func _unlock_after_level(value: int) -> void:
    var targets: Array = []
    match value:
        3:
            targets = [4, 5]
        4, 5:
            targets = [6]
        6:
            targets = [7, 8]
        7, 8:
            targets = [9]
        9:
            targets = [10]
        _:
            if value < 10:
                targets = [value + 1]
    for target in targets:
        if target not in unlocked_levels:
            unlocked_levels.append(target)
    unlocked_levels.sort()

func boss_for_level(value: int) -> String:
    match value:
        3:
            return "snake"
        6:
            return "guardian"
        9:
            return "beast"
        10:
            return "dragon"
        _:
            return "none"

func _draw_campaign_map() -> void:
    draw_rect(Rect2(0, 0, 720, 1280), Color("17120f"))
    draw_rect(Rect2(0, 0, 720, 120), Color("2a211b"))
    draw_string(ThemeDB.fallback_font, Vector2(42, 52), "خريطة المغامرة", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("fff0bd"))
    draw_string(ThemeDB.fallback_font, Vector2(42, 86), "اختر طريقك • افتح الصناديق • اهزم الزعماء", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("d8c39d"))
    draw_string(ThemeDB.fallback_font, Vector2(525, 48), "★ %d" % stars, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ffd45b"))
    draw_string(ThemeDB.fallback_font, Vector2(525, 80), "◆ %d" % coins, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffe5a1"))
    draw_string(ThemeDB.fallback_font, Vector2(42, 104), _daily_quest_text(), HORIZONTAL_ALIGNMENT_LEFT, 620, 15, Color("9fe8c0") if not daily_claimed else Color("ffe17a"))
    var nodes := [Vector2(110,190),Vector2(250,250),Vector2(390,190),Vector2(285,390),Vector2(470,390),Vector2(360,540),Vector2(235,680),Vector2(485,680),Vector2(360,830),Vector2(360,990)]
    # World gates make the campaign read as four connected adventures.
    draw_rect(Rect2(35, 145, 650, 75), Color(0.18,0.12,0.08,0.88))
    draw_string(ThemeDB.fallback_font, Vector2(55, 172), "WORLD 1 • وادي الأطلال", HORIZONTAL_ALIGNMENT_LEFT, 250, 17, Color("e8b84b"))
    draw_string(ThemeDB.fallback_font, Vector2(390, 172), "WORLD 2 • قمم الجليد", HORIZONTAL_ALIGNMENT_LEFT, 250, 17, Color("72d8ff"))
    draw_rect(Rect2(35, 445, 650, 75), Color(0.08,0.16,0.10,0.88))
    draw_string(ThemeDB.fallback_font, Vector2(55, 472), "WORLD 3 • غابة الأنياب", HORIZONTAL_ALIGNMENT_LEFT, 280, 17, Color("7bdc68"))
    draw_string(ThemeDB.fallback_font, Vector2(390, 472), "WORLD 4 • قلعة التنين", HORIZONTAL_ALIGNMENT_LEFT, 250, 17, Color("c77cff"))
    var links := [[0,1],[1,2],[2,3],[2,4],[3,5],[4,5],[5,6],[5,7],[6,8],[7,8],[8,9]]
    for link in links:
        var a: Vector2 = nodes[link[0]]
        var b: Vector2 = nodes[link[1]]
        draw_line(a,b,Color("5d4934"),18)
        draw_line(a,b,Color("c89a43"),5)
    for i in range(nodes.size()):
        var p: Vector2 = nodes[i]
        var unlocked := _is_level_unlocked(i + 1)
        var completed: int = level_stars[i + 1]
        var node_scale := 1.0 + (0.06 * sin(map_pulse * 2.0 + float(i)) if unlocked and i + 1 == unlocked_level else 0.0)
        draw_circle(p,44 * node_scale,Color("30271f"))
        draw_circle(p,39,Color("d1a04a") if unlocked else Color("4b443d"))
        draw_circle(p,31,Color("4d3925") if unlocked else Color("272421"))
        draw_string(ThemeDB.fallback_font,p+Vector2(-10,9),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color.WHITE if unlocked else Color("8c857b"))
        if completed > 0:
            draw_string(ThemeDB.fallback_font,p+Vector2(-28,62),"★".repeat(completed),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("ffd45b"))
        if boss_for_level(i + 1) != "none":
            draw_circle(p+Vector2(29,-29),13,Color("9d3026"))
            draw_string(ThemeDB.fallback_font,p+Vector2(22,-23),"B",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
        if i + 1 in [3,6,9]:
            draw_rect(Rect2(p+Vector2(-13,-63),Vector2(26,20)),Color("8d5a25"))
            draw_rect(Rect2(p+Vector2(-10,-60),Vector2(20,14)),Color("ffd45b"),false,2)
    draw_rect(Rect2(50,1100,620,110),Color("241c17"))
    draw_rect(Rect2(65,1115,590,80),Color("3b2b20"),false,3)
    draw_string(ThemeDB.fallback_font,Vector2(85,1145),"القدرات",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("ffe7aa"))
    draw_string(ThemeDB.fallback_font,Vector2(85,1177),"مطرقة %d   انفجار %d   +5 حركات %d" % [ability_hammer,ability_blast,ability_extra_moves],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
    draw_string(ThemeDB.fallback_font,Vector2(410,1145),"المراحل المفتوحة: %d/10" % unlocked_levels.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("d7c29a"))
    draw_string(ThemeDB.fallback_font,Vector2(410,1177),"اختر مرحلة للبدء",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("fff0bd"))
    draw_string(ThemeDB.fallback_font,Vector2(85,1210),"مسار النجوم: %d/25  •  صناديق النجوم: %d" % [stars, claimed_star_chests.size()],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("ffd45b"))

func _handle_map_tap(pos: Vector2) -> void:
    var nodes := [Vector2(110,190),Vector2(250,250),Vector2(390,190),Vector2(285,390),Vector2(470,390),Vector2(360,540),Vector2(235,680),Vector2(485,680),Vector2(360,830),Vector2(360,990)]
    for i in range(nodes.size()):
        if pos.distance_to(nodes[i]) <= 58.0:
            _start_level(i + 1)
            return

func _draw_boss_cinematic() -> void:
    var t := clampf(boss_intro / 2.2, 0.0, 1.0)
    var pulse := sin((1.0 - t) * PI)
    draw_rect(Rect2(0, 0, 720, 660), Color(0.04, 0.015, 0.02, 0.76))
    draw_rect(Rect2(30, 170, 660, 300), Color(0.10, 0.035, 0.03, 0.96))
    draw_rect(Rect2(38, 178, 644, 284), Color("8b2d22"), false, 5)
    draw_string(ThemeDB.fallback_font, Vector2(210, 235), "⚠  BOSS  ⚠", HORIZONTAL_ALIGNMENT_LEFT, -1, 34 + pulse * 7.0, Color("ffcf5a"))
    draw_string(ThemeDB.fallback_font, Vector2(170, 285), _boss_name(), HORIZONTAL_ALIGNMENT_LEFT, 380, 48, Color("fff1d0"))
    draw_string(ThemeDB.fallback_font, Vector2(145, 335), "استعد للمواجهة الأخيرة لهذا المستوى", HORIZONTAL_ALIGNMENT_LEFT, 430, 19, Color("e8cbb0"))
    draw_string(ThemeDB.fallback_font, Vector2(170, 385), "PV  %d / %d" % [snake_hp, boss_max_hp], HORIZONTAL_ALIGNMENT_LEFT, 380, 22, Color("ff927b"))
    draw_rect(Rect2(155, 410, 410, 18), Color("301b19"))
    draw_rect(Rect2(155, 410, 410.0 * float(snake_hp) / maxf(1.0, float(boss_max_hp)), 18), Color("e34a3f"))
    if boss_intro < 0.65:
        draw_string(ThemeDB.fallback_font, Vector2(245, 515), "ابدأ الهجوم!", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("ffe17a"))

func _draw_end_panel() -> void:
    draw_rect(Rect2(35, 285, 650, 520), Color(0.025, 0.018, 0.015, 0.92))
    draw_rect(Rect2(45, 295, 630, 500), Color("8f682b"), false, 6)
    if level_won:
        var earned := 3 if moves >= 12 else (2 if moves >= 6 else 1)
        var pop := 1.0 + sin(reward_pop * PI) * 0.04
        draw_string(ThemeDB.fallback_font, Vector2(190, 365), "LEVEL COMPLETE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("ffe17a"))
        draw_string(ThemeDB.fallback_font, Vector2(180, 408), "أحسنت! الطريق التالي أصبح مفتوحاً", HORIZONTAL_ALIGNMENT_LEFT, 380, 18, Color("e8dcc8"))
        for i in range(3):
            var shown := star_reveal >= float(i + 1)
            var p := Vector2(260 + i * 100, 495)
            var s := 38.0 * (pop if shown and i == earned - 1 else 1.0)
            draw_circle(p, s + 5, Color(0.18,0.12,0.04,0.9))
            draw_string(ThemeDB.fallback_font, p + Vector2(-20, 14), "★" if shown and i < earned else "☆", HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color("ffd34d") if shown and i < earned else Color("766d61"))
        draw_string(ThemeDB.fallback_font, Vector2(205, 555), "%d points" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(205, 592), "+%d ◆" % (level_coins + earned * 5 + chest_reward), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffe17a"))
        if chest_reward > 0:
            draw_string(ThemeDB.fallback_font, Vector2(145, 630), "صندوق كنز!  +%d ◆  +قدرات" % chest_reward, HORIZONTAL_ALIGNMENT_LEFT, 430, 18, Color("ffd45b"))
        if level_number in [3, 6, 9, 10]:
            var epilogue := "العالم مكتمل! بوابة العالم التالي مفتوحة."
            if level_number == 10:
                epilogue = "النهاية: سقط التنين وعادت المملكة إلى الأبطال."
            draw_string(ThemeDB.fallback_font, Vector2(100, 665), epilogue, HORIZONTAL_ALIGNMENT_LEFT, 520, 16, Color("bfe7ff"))
        draw_rect(Rect2(125, 710, 210, 65), Color("b98220"))
        draw_string(ThemeDB.fallback_font, Vector2(173, 752), "الخريطة", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)
        draw_rect(Rect2(385, 710, 210, 65), Color("d09a31"))
        draw_string(ThemeDB.fallback_font, Vector2(430, 752), "المستوى التالي", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("2a1a0d"))
    else:
        draw_string(ThemeDB.fallback_font, Vector2(205, 395), "TRY AGAIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("ff927b"))
        draw_string(ThemeDB.fallback_font, Vector2(205, 445), "نفدت الحركات", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("f0d8c0"))
        draw_string(ThemeDB.fallback_font, Vector2(205, 505), "Score : %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(205, 550), "لا تزال أمامك فرصة لإعادة المحاولة.", HORIZONTAL_ALIGNMENT_LEFT, 340, 17, Color("cbbda8"))
        draw_rect(Rect2(165, 650, 390, 75), Color("8e392d"))
        draw_string(ThemeDB.fallback_font, Vector2(270, 698), "إعادة المحاولة", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)

func _handle_end_tap(pos: Vector2) -> void:
    if pos.y < 620 or pos.y > 800:
        return
    if level_lost:
        screen_transition = 0.7
        _new_level()
        return
    if level_won:
        if pos.x >= 385 and level_number < 10:
            var next_level := level_number + 1
            if _is_level_unlocked(next_level):
                screen_mode = "level"
                screen_transition = 1.0
                result_timer = 0.0
                _new_level()
                return
        screen_mode = "map"
        unlock_flash = 1.0
        screen_transition = 0.8
        queue_redraw()

func _refresh_daily_quest() -> void:
    var today := Time.get_date_string_from_system()
    if daily_day == today:
        return
    daily_day = today
    var day_number := int(today.replace("-", ""))
    var variants := ["matches", "combo", "special"]
    daily_kind = variants[day_number % variants.size()]
    daily_target = 20 if daily_kind == "matches" else (4 if daily_kind == "combo" else 3)
    daily_progress = 0
    daily_claimed = false
    _save_progress()

func _daily_quest_text() -> String:
    _refresh_daily_quest()
    if daily_claimed:
        return "مهمة اليوم ✓ مكتملة • مكافأة +50 ◆"
    var label := "طابق القطع" if daily_kind == "matches" else ("حقق COMBO x4" if daily_kind == "combo" else "أنشئ Boosters")
    return "مهمة اليوم: %s  %d/%d  •  المكافأة 50 ◆" % [label, daily_progress, daily_target]

func _update_daily_quest(kind: String, amount: int = 1) -> void:
    _refresh_daily_quest()
    if daily_claimed or kind != daily_kind:
        return
    daily_progress = mini(daily_target, daily_progress + amount)
    if daily_progress >= daily_target:
        daily_claimed = true
        coins += 50
        message = "مهمة اليوم مكتملة! +50 ◆"
        _save_progress()

func _check_star_chest_rewards() -> void:
    var milestones := [5, 10, 15, 20, 25]
    for milestone in milestones:
        if stars >= milestone and milestone not in claimed_star_chests:
            claimed_star_chests.append(milestone)
            coins += 50 + milestone * 5
            ability_hammer += 1
            if milestone >= 10:
                ability_extra_moves += 1
            message = "صندوق النجوم %d! +◆ وقدرة" % milestone

func _save_progress() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("campaign", "unlocked_level", unlocked_level)
    cfg.set_value("campaign", "unlocked_levels", unlocked_levels)
    cfg.set_value("campaign", "level_stars", level_stars)
    cfg.set_value("campaign", "stars", stars)
    cfg.set_value("campaign", "coins", coins)
    cfg.set_value("campaign", "best_score", best_score)
    cfg.set_value("abilities", "hammer", ability_hammer)
    cfg.set_value("abilities", "blast", ability_blast)
    cfg.set_value("abilities", "extra_moves", ability_extra_moves)
    cfg.set_value("rewards", "chests_opened", chests_opened)
    cfg.set_value("rewards", "claimed_star_chests", claimed_star_chests)
    cfg.set_value("daily", "day", daily_day)
    cfg.set_value("daily", "kind", daily_kind)
    cfg.set_value("daily", "target", daily_target)
    cfg.set_value("daily", "progress", daily_progress)
    cfg.set_value("daily", "claimed", daily_claimed)
    cfg.save("user://puzzle_heroes.cfg")

func _load_progress() -> void:
    var cfg := ConfigFile.new()
    if cfg.load("user://puzzle_heroes.cfg") == OK:
        unlocked_level = int(cfg.get_value("campaign", "unlocked_level", 1))
        unlocked_levels = cfg.get_value("campaign", "unlocked_levels", [1])
        level_stars = cfg.get_value("campaign", "level_stars", [0,0,0,0,0,0,0,0,0,0,0])
        stars = int(cfg.get_value("campaign", "stars", 0))
        coins = int(cfg.get_value("campaign", "coins", 0))
        best_score = int(cfg.get_value("campaign", "best_score", 0))
        ability_hammer = int(cfg.get_value("abilities", "hammer", 2))
        ability_blast = int(cfg.get_value("abilities", "blast", 1))
        ability_extra_moves = int(cfg.get_value("abilities", "extra_moves", 1))
        chests_opened = int(cfg.get_value("rewards", "chests_opened", 0))
        claimed_star_chests = cfg.get_value("rewards", "claimed_star_chests", [])
        daily_day = str(cfg.get_value("daily", "day", ""))
        daily_kind = str(cfg.get_value("daily", "kind", "matches"))
        daily_target = int(cfg.get_value("daily", "target", 20))
        daily_progress = int(cfg.get_value("daily", "progress", 0))
        daily_claimed = bool(cfg.get_value("daily", "claimed", false))
    if unlocked_levels.is_empty():
        unlocked_levels = [1]
    if level_stars.size() < 11:
        level_stars.resize(11)

func _draw_top_hud() -> void:
    var wid := world_id(level_number)
    var panel := Color("2a211b")
    var accent := Color("e9b62f")
    match wid:
        2:
            panel = Color("172b3a")
            accent = Color("72d8ff")
        3:
            panel = Color("1b3023")
            accent = Color("7bdc68")
        4:
            panel = Color("321c35")
            accent = Color("c77cff")
    draw_rect(Rect2(0, 0, 720, 92), panel)
    draw_rect(Rect2(0, 88, 720, 7), accent)
    draw_string(ThemeDB.fallback_font, Vector2(30, 35), world_name(level_number), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fff4d0"))
    draw_string(ThemeDB.fallback_font, Vector2(30, 67), "NIVEAU %d • %s" % [level_number, level_modifier], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d7c29a"))
    draw_string(ThemeDB.fallback_font, Vector2(505, 20), world_rule(level_number), HORIZONTAL_ALIGNMENT_LEFT, 180, 13, accent)
    draw_rect(Rect2(0, 0, 720, 92), Color("2a211b"))
    draw_rect(Rect2(0, 88, 720, 7), Color("e9b62f"))
    draw_string(ThemeDB.fallback_font, Vector2(30, 38), "PUZZLE HEROES", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("fff4d0"))
    draw_string(ThemeDB.fallback_font, Vector2(30, 68), "NIVEAU %d • %s" % [level_number, level_modifier], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("d7c29a"))
    draw_circle(Vector2(552, 43), 18, Color("e9b62f"))
    draw_string(ThemeDB.fallback_font, Vector2(544, 51), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("5a3b10"))
    draw_string(ThemeDB.fallback_font, Vector2(580, 51), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(450, 78), "◆ %d" % coins, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe17a"))
    draw_rect(Rect2(625, 23, 65, 42), Color("49372a"))
    draw_string(ThemeDB.fallback_font, Vector2(637, 51), str(moves), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff1bd"))
    draw_rect(Rect2(245, 14, 115, 65), Color("49372a"))
    draw_string(ThemeDB.fallback_font, Vector2(255, 37), "مطرقة %d" % ability_hammer, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffe7aa"))
    draw_string(ThemeDB.fallback_font, Vector2(255, 58), "انفجار %d" % ability_blast, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffe7aa"))
    draw_string(ThemeDB.fallback_font, Vector2(375, 48), "+5 حركات %d" % ability_extra_moves, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffe7aa"))

func _draw_rescue_scene() -> void:
    var wid := world_id(level_number)
    var arena := Color("3b2d20")
    var accent := Color("d7a52b")
    match wid:
        2:
            arena = Color("24485a")
            accent = Color("72d8ff")
        3:
            arena = Color("23442b")
            accent = Color("7bdc68")
        4:
            arena = Color("4a214d")
            accent = Color("c77cff")
    draw_rect(Rect2(12, 102, 696, 558), arena)
    draw_rect(Rect2(16, 106, 688, 550), accent, false, 5)
    draw_string(ThemeDB.fallback_font, Vector2(34, 132), world_name(level_number), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff0bd"))
    # Premium illustrated rescue chamber asset.
    # Premium illustrated rescue chamber asset.
    draw_texture_rect(SCENE_TEX, Rect2(18, 108, 684, 548), false)
    if wid == 1:
        draw_texture_rect(RUINS_ENV_TEX, Rect2(18, 108, 684, 548), false, Color(1, 1, 1, 0.72))
    # Wall bands and floor.
    for y in range(125, 470, 52):
        for x in range(34, 690, 82):
            var off := 41 if int(y / 52) % 2 == 1 else 0
            draw_rect(Rect2(x + off, y, 74, 46), Color("4b3b2c"), true)
            draw_rect(Rect2(x + off, y, 74, 46), Color("6d5238"), false, 2)
    draw_rect(Rect2(28, 470, 664, 176), Color("8b6a42"))
    for x in range(35, 690, 54):
        draw_rect(Rect2(x, 480, 48, 72), Color("6b4e32"))
        draw_rect(Rect2(x, 480, 48, 72), Color("b08a54"), false, 2)
    # Golden pipe around the serpent.
    draw_line(Vector2(80, 190), Vector2(80, 430), Color("c48b18"), 28)
    draw_line(Vector2(80, 190), Vector2(590, 190), Color("d7a52b"), 28)
    draw_line(Vector2(590, 190), Vector2(590, 390), Color("c48b18"), 28)
    draw_line(Vector2(80, 190), Vector2(590, 190), Color("ffe17a"), 9)
    draw_line(Vector2(80, 190), Vector2(80, 430), Color("ffe17a"), 8)
    draw_line(Vector2(590, 190), Vector2(590, 390), Color("ffe17a"), 8)

    # World-specific environment dressing.
    _draw_world_environment(wid)
    # Boss has a distinct silhouette and palette per world.
    var boss_center := Vector2(420, 285 + sin(hero_bounce * 0.7) * 3.0)
    _draw_boss_character(boss_center)

    # Rescue chamber and captive.
    draw_rect(Rect2(438, 405, 205, 168), Color("241c16"))
    draw_rect(Rect2(447, 414, 187, 150), Color("4b3828"))
    draw_line(Vector2(447, 505), Vector2(634, 505), Color("d1a44a"), 8)
    if level_won:
        draw_texture_rect(CAPTIVE_PRO_TEX, Rect2(492, 420, 112, 142), false)
    else:
        _draw_hero(Vector2(520, 490))

    # Destructible stone wall.
    if obstacle_index < obstacle_hp.size():
        draw_rect(Rect2(45, 505, 245, 120), Color("756b61"))
        for yy in range(512, 622, 25):
            for xx in range(52, 285, 35):
                var jitter := float((xx + yy) % 9)
                draw_circle(Vector2(xx + jitter, yy), 13, Color("a8a09a"))
                draw_circle(Vector2(xx + jitter - 3, yy - 3), 5, Color(1, 1, 1, 0.22))
        draw_string(ThemeDB.fallback_font, Vector2(65, 535), "BLOQUÉ", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff1d0"))
        for h in range(obstacle_hp[obstacle_index]):
            draw_rect(Rect2(65 + h * 25, 548, 20, 8), Color("e94b42"))

    # Objective badge.
    draw_rect(Rect2(250, 120, 220, 42), Color(0.05, 0.04, 0.03, 0.86))
    var objective := "COMBAT !" if combat_active else ("SAUVETAGE !" if level_won else "%s  %d/%d" % [_level_objective(), goal_progress, goal_target])
    draw_string(ThemeDB.fallback_font, Vector2(280, 148), objective, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("ffe6a1"))

func _draw_hero(pos: Vector2) -> void:
    var bob := sin(art_idle_phase) * 3.0 + sin(hero_anim_phase * 1.7) * 2.0
    var attack := sin((1.0 - art_attack_phase) * PI) if art_attack_phase > 0.0 else 0.0
    var strike := sin((1.0 - hero_strike) * PI) if hero_strike > 0.0 else 0.0
    var recoil := hero_attack * -18.0 + strike * 28.0
    var scale := 1.0 + attack * 0.04
    var p := pos + Vector2(recoil, bob)
    draw_texture_rect(HERO_PRO_TEX, Rect2(p - Vector2(63,80) * scale, Vector2(126,160) * scale), false)
    if art_hit_flash > 0.0:
        draw_circle(p, 70.0, Color(1.0, 0.9, 0.35, art_hit_flash * 0.16))
    if attack > 0.0 or strike > 0.0:
        var reach := 42.0 + maxf(attack, strike) * 58.0
        draw_line(p + Vector2(38,-8), p + Vector2(reach,-8), Color(1.0,0.84,0.25,0.8), 7.0)
        draw_circle(p + Vector2(reach,-8), 8.0 + maxf(attack,strike)*8.0, Color(1.0,0.94,0.55,0.8))

func _draw_world_environment(wid: int) -> void:
    match wid:
        1:
            draw_circle(Vector2(105, 155), 70, Color(0.82, 0.55, 0.22, 0.16))
            draw_circle(Vector2(620, 165), 95, Color(0.95, 0.72, 0.28, 0.12))
            for x in range(70, 680, 95):
                draw_rect(Rect2(x, 420, 55, 70), Color("6b4b2f"))
                draw_polygon(PackedVector2Array([Vector2(x,420),Vector2(x+28,385),Vector2(x+55,420)]), PackedColorArray([Color("8b663f")]))
        2:
            draw_circle(Vector2(120, 190), 105, Color(0.40, 0.82, 1.0, 0.12))
            draw_circle(Vector2(610, 220), 120, Color(0.55, 0.90, 1.0, 0.10))
            for x in range(45, 700, 110):
                draw_polygon(PackedVector2Array([Vector2(x,450),Vector2(x+48,340),Vector2(x+96,450)]), PackedColorArray([Color("9ed9e8",0.38)]))
                draw_line(Vector2(x+20,430),Vector2(x+48,370),Color("d9f7ff",0.5),5)
        3:
            draw_circle(Vector2(105, 175), 115, Color(0.22, 0.72, 0.30, 0.13))
            draw_circle(Vector2(625, 185), 100, Color(0.38, 0.86, 0.30, 0.12))
            for x in range(35, 700, 85):
                draw_line(Vector2(x,450),Vector2(x+35,335),Color("3d7d3f",0.55),13)
                draw_circle(Vector2(x+35,335),18,Color("66a94e",0.55))
        4:
            draw_circle(Vector2(115, 165), 100, Color(0.62, 0.30, 0.90, 0.14))
            draw_circle(Vector2(620, 175), 120, Color(0.95, 0.35, 0.75, 0.10))
            for x in range(60, 680, 120):
                draw_rect(Rect2(x, 330, 18, 125), Color("5d2b75",0.75))
                draw_circle(Vector2(x+9,330),28,Color("a45dd1",0.55))

func _boss_art_texture() -> Texture2D:
    match boss_kind:
        "snake": return SNAKE_PRO_TEX
        "guardian": return GUARDIAN_PRO_TEX
        "beast": return BEAST_PRO_TEX
        "dragon": return DRAGON_PRO_TEX
        _: return SNAKE_PRO_TEX

func _draw_boss_character(pos: Vector2, story: bool = false) -> void:
    var idle := sin(art_idle_phase) * (4.0 if story else 2.5)
    var attack := sin((1.0 - art_attack_phase) * PI) if art_attack_phase > 0.0 else 0.0
    var hit := sin((1.0 - art_hit_flash) * PI) if art_hit_flash > 0.0 else 0.0
    var defeat := clampf(1.0 - art_defeat_phase, 0.0, 1.0) if level_won else 1.0
    var scale := 1.0 if story else 0.82
    if boss_kind == "snake":
        scale = 0.86 if story else 0.72
    var size := Vector2(300, 300) * scale
    if boss_kind == "snake":
        size = Vector2(360, 270) * scale
    var p := pos + Vector2(attack * 24.0 + sin(art_idle_phase * 1.7) * 3.0, idle - (1.0 - defeat) * 55.0)
    var alpha := defeat
    if boss_kind == "dragon":
        size *= 1.05
    draw_texture_rect(_boss_art_texture(), Rect2(p - size * 0.5, size), false, Color(1, 1, 1, alpha))
    if hit > 0.0:
        draw_circle(p, 105.0 * scale + hit * 18.0, Color(1.0, 0.88, 0.35, hit * 0.20))
        draw_arc(p, 120.0 * scale + hit * 16.0, 0.0, TAU, 32, Color(1.0, 0.42, 0.18, hit * 0.8), 7.0)
    if attack > 0.0:
        var reach := 110.0 + attack * 75.0
        var attack_color := Color("ffcf5a")
        if boss_kind == "guardian": attack_color = Color("9ceaff")
        elif boss_kind == "beast": attack_color = Color("ff704f")
        elif boss_kind == "dragon": attack_color = Color("d67cff")
        draw_line(p + Vector2(0, 55), p + Vector2(0, 55 + reach), Color(attack_color, 0.18), 22.0)
        draw_line(p + Vector2(0, 55), p + Vector2(0, 55 + reach), Color(attack_color, 0.75), 6.0)
    draw_string(ThemeDB.fallback_font, p + Vector2(-115 * scale, -145 * scale), "BOSS • " + _boss_name(), HORIZONTAL_ALIGNMENT_LEFT, 240 * scale, 18, Color("fff0c4"))

func _draw_board() -> void:
    var wid := world_id(level_number)
    var frame := Color("b98628")
    var inner := Color("e8d4a7")
    match wid:
        2:
            frame = Color("4e9fc0")
            inner = Color("d8edf4")
        3:
            frame = Color("4f9b50")
            inner = Color("dcebd3")
        4:
            frame = Color("8750a8")
            inner = Color("ead8ee")
    draw_rect(Rect2(24, 666, 672, 580), frame)
    draw_rect(Rect2(32, 674, 656, 564), inner)
    draw_string(ThemeDB.fallback_font, Vector2(48, 698), "MATCH 3 • " + world_name(level_number), HORIZONTAL_ALIGNMENT_LEFT, 500, 17, Color("68451d"))

    for y in ROWS:
        for x in COLS:
            var rect := Rect2(BOARD_X + x * CELL, BOARD_Y + y * CELL, CELL - 5, CELL - 5)
            draw_style_box(_cell_box(), rect)

    for y in ROWS:
        for x in COLS:
            var value: int = board[y][x]
            if value < 0:
                continue
            var center := Vector2(BOARD_X + x * CELL + (CELL - 5) * 0.5, BOARD_Y + y * CELL + (CELL - 5) * 0.5)
            center += tile_offset[y][x]
            _draw_gem_animated(center, value, tile_scale[y][x], tile_alpha[y][x])
            if hazards[y][x] == 1:
                draw_arc(center, 31, 0, TAU, 20, Color(0.55, 0.86, 1.0, 0.9), 6.0)
                draw_line(center + Vector2(-20, 18), center + Vector2(20, -18), Color(0.75, 0.95, 1.0, 0.8), 4.0)
            elif hazards[y][x] == 2:
                draw_rect(Rect2(center - Vector2(31,31), Vector2(62,62)), Color(0.95,0.72,0.24,0.28), true)
                draw_arc(center, 29, 0, TAU, 18, Color("e9b62f"), 5.0)
            elif hazards[y][x] == 3:
                draw_circle(center, 35, Color(0.28,0.12,0.38,0.65))
                draw_arc(center, 30, 0, TAU, 20, Color("b957e8"), 5.0)

    if swap_animating and _inside(swap_a) and _inside(swap_b):
        var va: int = board[swap_a.y][swap_a.x]
        var vb: int = board[swap_b.y][swap_b.x]
        var ca := Vector2(BOARD_X + swap_a.x * CELL + (CELL - 5) * 0.5, BOARD_Y + swap_a.y * CELL + (CELL - 5) * 0.5)
        var cb := Vector2(BOARD_X + swap_b.x * CELL + (CELL - 5) * 0.5, BOARD_Y + swap_b.y * CELL + (CELL - 5) * 0.5)
        var t := clampf(swap_anim_t, 0.0, 1.0)
        var pa := ca.lerp(cb, t)
        var pb := cb.lerp(ca, t)
        var bounce := sin(t * PI) * (7.0 if swap_rejected else 3.0)
        _draw_gem_animated(pa + Vector2(0, bounce), va, 1.04, 1.0)
        _draw_gem_animated(pb - Vector2(0, bounce), vb, 1.04, 1.0)

    if dragging and _inside(drag_cell):
        var drag_value: int = board[drag_cell.y][drag_cell.x]
        if drag_value >= 0:
            var cell_center := Vector2(BOARD_X + drag_cell.x * CELL + (CELL - 5) * 0.5, BOARD_Y + drag_cell.y * CELL + (CELL - 5) * 0.5)
            var delta := drag_visual_pos - drag_start
            var limited := delta.limit_length(CELL * 0.78)
            _draw_gem_animated(cell_center + limited, drag_value, 1.08, 1.0)

    for path in booster_paths:
        _draw_booster_path(path)

    draw_rect(Rect2(32, 1248, 656, 32), Color("241c17"))
    draw_string(ThemeDB.fallback_font, Vector2(50, 1271), message, HORIZONTAL_ALIGNMENT_LEFT, 620, 16, Color.WHITE)
    if combo > 1:
        draw_string(ThemeDB.fallback_font, Vector2(500, 720), "COMBO x%d" % combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffdf62"))

func _draw_gem_animated(center: Vector2, value: int, scale: float, alpha: float) -> void:
    var old_modulate := modulate
    modulate = Color(1, 1, 1, clampf(alpha, 0.0, 1.0))
    _draw_gem(center, value)
    modulate = old_modulate


func _draw_gem(center: Vector2, value: int) -> void:
    if value >= 0 and value < COLORS.size():
        var src := Rect2(value * 150, 0, 150, 150)
        draw_texture_rect_region(GEMS_TEX, Rect2(center - Vector2(36, 36), Vector2(72, 72)), src)
        return
    if value == SPECIAL_H or value == SPECIAL_V:
        draw_circle(center, 34, Color("f6c443"))
        draw_circle(center, 28, COLORS[goal_color])
        if value == SPECIAL_H:
            draw_rect(Rect2(center.x - 24, center.y - 4, 48, 8), Color.WHITE)
        else:
            draw_rect(Rect2(center.x - 4, center.y - 24, 8, 48), Color.WHITE)
        draw_circle(center, 7, Color("fff4b0"))
        return
    draw_circle(center, 33, Color("30283b"))
    draw_circle(center, 27, Color("ef4f5f"))
    draw_circle(center, 8, Color("ffe66d"))
    draw_line(center + Vector2(14, -20), center + Vector2(27, -32), Color("fff0a6"), 5)

func _cell_box() -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color("f8f0dd")
    box.border_color = Color("c9af7b")
    box.set_border_width_all(2)
    box.set_corner_radius_all(9)
    return box

func _input(event: InputEvent) -> void:
    if screen_mode == "story":
        if event is InputEventScreenTouch and event.pressed:
            _handle_story_tap(_input_to_design(event.position))
        elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _handle_story_tap(event.position)
        return
    if screen_mode == "map":
        if event is InputEventScreenTouch and event.pressed:
            _handle_map_tap(_input_to_design(event.position))
        elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _handle_map_tap(event.position)
        return
    if level_won or level_lost:
        if event is InputEventScreenTouch and event.pressed:
            _handle_end_tap(_input_to_design(event.position))
        elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _handle_end_tap(event.position)
        return
    if busy:
        return
    if boss_intro > 0.0:
        return

    if event is InputEventScreenTouch and event.pressed:
        if _handle_ability_tap(_input_to_design(event.position)):
            return
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        if _handle_ability_tap(event.position):
            return

    # Android / iOS touch. Normalize to the 720x1280 design space.
    if event is InputEventScreenTouch:
        if event.pressed and active_touch_index == -1:
            active_touch_index = event.index
            drag_start = _input_to_design(event.position)
            drag_cell = _screen_to_cell(drag_start)
            drag_visual_pos = drag_start
            dragging = drag_cell.x >= 0
        elif not event.pressed and event.index == active_touch_index:
            if dragging:
                _finish_drag(_input_to_design(event.position))
            dragging = false
            active_touch_index = -1

    elif event is InputEventScreenDrag and dragging and event.index == active_touch_index:
        var current_pos: Vector2 = _input_to_design(event.position)
        drag_visual_pos = current_pos
        var delta: Vector2 = current_pos - drag_start
        if delta.length() >= 28.0:
            _finish_drag(current_pos)

    # Mouse input is useful for desktop testing.
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            drag_start = event.position
            drag_visual_pos = event.position
            drag_cell = _screen_to_cell(event.position)
            dragging = drag_cell.x >= 0
        elif dragging:
            _finish_drag(event.position)

    elif event is InputEventMouseMotion and dragging:
        drag_visual_pos = event.position
        var mouse_delta: Vector2 = event.position - drag_start
        if mouse_delta.length() >= 34.0:
            _finish_drag(event.position)

func _handle_ability_tap(pos: Vector2) -> bool:
    if pos.y < 12.0 or pos.y > 82.0:
        return false
    if pos.x >= 245.0 and pos.x <= 360.0 and pos.y < 48.0 and ability_hammer > 0 and obstacle_index < obstacle_hp.size():
        ability_hammer -= 1
        obstacle_hp[obstacle_index] = max(0, obstacle_hp[obstacle_index] - 2)
        score += 30
        message = "مطرقة البطل! ضربة قوية."
        obstacle_flash = 1.0
        rock_impact = 1.0
        screen_shake = 0.45
        if obstacle_hp[obstacle_index] == 0:
            obstacle_index += 1
            hero_progress += 1
            if hero_progress >= PATH_POINTS.size() - 1:
                _begin_boss_or_finish()
        _save_progress()
        return true
    if pos.x >= 245.0 and pos.x <= 360.0 and pos.y >= 48.0 and ability_blast > 0:
        ability_blast -= 1
        for y in ROWS:
            for x in COLS:
                if board[y][x] == goal_color:
                    board[y][x] = -1
        _collapse()
        score += 60
        message = "انفجار اللون! الساحة تنهار."
        screen_shake = 0.55
        _save_progress()
        return true
    if pos.x >= 365.0 and pos.x <= 500.0 and pos.y >= 12.0 and ability_extra_moves > 0:
        ability_extra_moves -= 1
        moves += 5
        message = "+5 حركات! أكمل السلسلة."
        _save_progress()
        return true
    return false

func _finish_drag(pos: Vector2) -> void:
    dragging = false

    if level_won or level_lost:
        return

    var end_cell := _screen_to_cell(pos)
    if end_cell.x < 0 or end_cell == drag_cell:
        return

    var d := end_cell - drag_cell
    if abs(d.x) + abs(d.y) != 1:
        if abs(d.x) >= abs(d.y):
            end_cell = drag_cell + Vector2i(sign(d.x), 0)
        else:
            end_cell = drag_cell + Vector2i(0, sign(d.y))
    if _inside(end_cell):
        _try_swap(drag_cell, end_cell)

func _input_to_design(pos: Vector2) -> Vector2:
    var viewport_size := get_viewport().get_visible_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return pos
    return Vector2(pos.x * 720.0 / viewport_size.x, pos.y * 1280.0 / viewport_size.y)

func _screen_to_cell(pos: Vector2) -> Vector2i:
    var x := int(floor((pos.x - BOARD_X) / CELL))
    var y := int(floor((pos.y - BOARD_Y) / CELL))
    var cell := Vector2i(x, y)
    return cell if _inside(cell) else Vector2i(-1, -1)

func _inside(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS

func _try_swap(a: Vector2i, b: Vector2i) -> void:
    _play_sfx("swap")
    busy = true
    _swap(a, b)
    await _play_swap_animation(a, b, false)

    var has_special := _is_special(board[a.y][a.x]) or _is_special(board[b.y][b.x])
    var matches := _activate_special_swap(a, b) if has_special else _find_matches()

    if matches.is_empty():
        await _play_swap_animation(a, b, true)
        _swap(a, b)
        swap_animating = false
        combo = 0
        cascade = 0
        message = "Pas de combinaison : essaie un autre mouvement."
        _play_sfx("hit", 0.6)
        busy = false
        queue_redraw()
        return

    moves -= 1
    cascade = 0
    combo = 0
    await _resolve_cascade(matches)
    if moves <= 0 and not level_won:
        level_lost = true
        _play_sfx("lose")
        message = "Niveau échoué • touche pour réessayer"
    busy = false
    queue_redraw()

func _play_swap_animation(a: Vector2i, b: Vector2i, rejected: bool) -> void:
    swap_a = a
    swap_b = b
    swap_rejected = rejected
    if rejected:
        near_miss_flash = 0.45
    swap_animating = true
    swap_anim_t = 1.0 if rejected else 0.0
    _spawn_tile_trail(a, b)
    var tween := create_tween()
    if rejected:
        tween.tween_property(self, "swap_anim_t", 0.0, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    else:
        tween.tween_property(self, "swap_anim_t", 1.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    await tween.finished
    if not rejected:
        swap_animating = false

func _resolve_cascade(initial_matches: Array[Vector2i]) -> void:
    var matches := initial_matches
    while not matches.is_empty() and cascade < 12:
        cascade += 1
        combo += 1
        combo_flash = 1.0
        _play_sfx("combo" if combo >= 2 else "match", combo)
        last_match_count = matches.size()
        var multiplier := 1 + mini(combo - 1, 4)
        if fever > 0.0:
            multiplier *= 2
        var points := matches.size() * 12 * multiplier
        streak_best = maxi(streak_best, combo)
        if combo >= 4 and fever <= 0.0:
            fever = 8.0
            fever_flash = 1.0
            screen_shake = maxf(screen_shake, 0.35)
            camera_zoom = 1.035
        score += points
        _update_daily_quest("matches", matches.size())
        if combo >= 4:
            _update_daily_quest("combo", 1)
        level_coins += maxi(1, matches.size() / 3)

        if goal_kind == "collect":
            for cell in matches:
                if board[cell.y][cell.x] == goal_color:
                    goal_progress = mini(goal_target, goal_progress + 1)

        var special_cell := matches[mini(matches.size() / 2, matches.size() - 1)]
        var special_value := -1
        if matches.size() >= 5:
            special_value = SPECIAL_COLOR
        elif matches.size() == 4:
            special_value = SPECIAL_H if not _vertical_match_at(matches, special_cell) else SPECIAL_V
        if special_value >= 0:
            _play_sfx("booster", 1.0)
        if special_value >= 0 and goal_kind == "special":
            goal_progress = mini(goal_target, goal_progress + 1)
            _update_daily_quest("special", 1)

        message = ("FEVER!  " if fever > 0.0 else "") + "COMBO x%d  +%d" % [combo, points]
        _prime_match_animation(matches)
        await get_tree().create_timer(0.11).timeout
        _spawn_match_bursts(matches)
        _clear_matches(matches, special_cell, special_value)
        _damage_hazards(matches)
        _apply_adventure_damage(matches.size())
        if combat_active:
            _apply_snake_damage(matches.size())
        _spawn_attack_effects(matches.size())
    _set_combat_animation("attack")
    _emit_combat_particles(true, mini(40, 14 + matches.size() * 4))
        _collapse()
        refill_anim = 0.0
        hero_attack = 1.0
        screen_shake = minf(1.0, 0.18 + cascade * 0.06)
        await get_tree().create_timer(0.10).timeout
        matches = _find_matches()
        if matches.size() == 0 and combo >= 2:
            near_miss_flash = 1.0
            message = "SÉRIE TERMINÉE ! Prépare le prochain COMBO."

    if world_id(level_number) == 2 and moves % 4 == 0:
        var ice_cell := Vector2i(randi() % COLS, randi() % ROWS)
        hazards[ice_cell.y][ice_cell.x] = 1
        message = "الصقيع يتسع! اكسر الجليد."
    elif world_id(level_number) == 3 and moves % 3 == 0:
        var vine_cell := Vector2i(randi() % COLS, randi() % ROWS)
        hazards[vine_cell.y][vine_cell.x] = 2
        message = "الكروم تزحف إلى اللوحة!"
    _check_goal()
func _damage_hazards(matches: Array[Vector2i]) -> void:
    for cell in matches:
        if not _inside(cell):
            continue
        if hazards[cell.y][cell.x] == 1:
            hazards[cell.y][cell.x] = 0
            _spawn_vfx_ring(_cell_center(cell), 18.0, 70.0, Color(0.45, 0.85, 1.0, 0.9), 0.28)
        elif hazards[cell.y][cell.x] == 2:
            hazards[cell.y][cell.x] = 0
            _spawn_vfx_ring(_cell_center(cell), 18.0, 82.0, Color(0.95, 0.75, 0.28, 0.9), 0.30)
        elif hazards[cell.y][cell.x] == 3:
            hazards[cell.y][cell.x] = 2

func _boss_mechanic() -> void:
    if not combat_active:
        return
    match boss_kind:
        "snake":
            if boss_turn % 2 == 0:
                var c := Vector2i(randi() % COLS, randi() % ROWS)
                hazards[c.y][c.x] = 3
                message = "☠ الأفعى نشرت السم! اكسر اللعنة!"
        "guardian":
            if boss_turn % 2 == 0:
                guardian_shield = true
                message = "🛡 الحارس رفع الدرع! اضرب بـ5+ قطع."
        "beast":
            if snake_hp <= int(boss_max_hp * 0.5):
                boss_enraged = true
                moves = max(1, moves - 1)
                var c := Vector2i(randi() % COLS, randi() % ROWS)
                hazards[c.y][c.x] = 2
                message = "الوحش في حالة غضب! -1 حركة."
        "dragon":
            if boss_turn % 2 == 0:
                for y in ROWS:
                    for x in COLS:
                        if board[y][x] >= 0 and randi() % 5 == 0:
                            board[y][x] = randi() % COLORS.size()
                screen_shake = maxf(screen_shake, 0.35)
                message = "التنين يبعثر الساحة!"

func _apply_adventure_damage(match_count: int) -> void:
    if level_won or obstacle_index >= obstacle_hp.size():
        return

    # A normal 3-match deals 1 damage. Larger combinations hit harder.
    var damage := 1
    if match_count >= 5:
        damage = 2
    if match_count >= 7:
        damage = 3

    obstacle_hp[obstacle_index] = max(0, obstacle_hp[obstacle_index] - damage)
    obstacle_flash = 1.0
    rock_impact = 1.0
    attack_flash = 1.0
    snake_alert = 1.0
    hero_strike = 1.0
    screen_shake = maxf(screen_shake, 0.42)
    camera_zoom = 1.025
    _spawn_rock_impact(obstacle_index)

    if obstacle_hp[obstacle_index] > 0:
        message = "COUP ! Rocher %d/%d • encore %d" % [
            obstacle_index + 1,
            obstacle_hp.size(),
            obstacle_hp[obstacle_index]
        ]
        return

    # Obstacle destroyed: unlock the next path node.
    obstacle_index += 1
    hero_progress += 1

    if hero_progress >= PATH_POINTS.size() - 1:
        _begin_boss_or_finish()
        return

    var target: Vector2 = PATH_POINTS[hero_progress]
    var hero_tween := create_tween()
    hero_tween.set_parallel(true)
    hero_tween.tween_property(self, "hero_x", target.x, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    hero_tween.tween_property(self, "hero_y", target.y, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    message = "ROCHER DÉTRUIT ! Le héros avance."

func _begin_boss_or_finish() -> void:
    if boss_kind == "none":
        _complete_level()
        return
    combat_active = true
    boss_intro = 2.2
    screen_shake = maxf(screen_shake, 0.18)
    camera_zoom = 1.035
    snake_hp = boss_max_hp
    message = "BOSS: %s • اهزم الزعيم!" % _boss_name()
    var combat_tween := create_tween()
    combat_tween.set_parallel(true)
    combat_tween.tween_property(self, "hero_x", PATH_POINTS[-1].x - 48.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    combat_tween.tween_property(self, "hero_y", PATH_POINTS[-1].y, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _boss_name() -> String:
    match boss_kind:
        "snake":
            return "الأفعى"
        "guardian":
            return "الحارس"
        "beast":
            return "الوحش"
        "dragon":
            return "التنين"
        _:
            return "الزعيم"

func _apply_snake_damage(match_count: int) -> void:
    if not combat_active or level_won:
        return
    var damage := 1
    if match_count >= 5:
        damage = 2
    if match_count >= 7:
        damage = 3
    if boss_kind == "guardian" and guardian_shield:
        if match_count < 5:
            damage = 0
            message = "🛡 الدرع صد الضربة! اصنع 5+."
        else:
            guardian_shield = false
            guardian_shield_break = 1.0
            _spawn_impact_burst(Vector2(575, 330), 155.0, Color("9feeff"), 0.55)
            _spawn_boss_defeat_vfx()
    snake_hp = max(0, snake_hp - damage)
    snake_recoil = 1.0
    snake_shake = 1.0
    hero_strike = 1.0
    art_attack_phase = 1.0
    art_hit_flash = 1.0
    juice_pulse = 1.0
    _spawn_boss_attack_sequence(damage)
    screen_shake = maxf(screen_shake, 0.62)
    camera_zoom = 1.045
    boss_pulse = 1.0
    snake_hit_flash = 1.0
    snake_alert = 1.0
    score += damage * 25
    _spawn_attack_effects(match_count)
    _spawn_snake_hit_vfx(damage)
    _boss_mechanic()

    if snake_hp > 0:
        message = "TOUCHE ! Le serpent perd %d PV." % damage
        return

    var earned_stars := 1
    if moves >= 12:
        earned_stars = 3
    elif moves >= 6:
        earned_stars = 2
    _complete_level()
    var rescue_tween := create_tween()
    rescue_tween.set_parallel(true)
    rescue_tween.tween_property(self, "hero_x", 560.0, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    rescue_tween.tween_property(self, "hero_y", 375.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _spawn_rock_impact(index: int) -> void:
    var p := Vector2(165, 560)
    _spawn_vfx_ring(p, 12.0, 105.0, Color(0.92, 0.78, 0.52, 0.9), 0.34)
    for i in range(12):
        var angle := TAU * float(i) / 12.0
        effects.append({
            "p": p,
            "v": Vector2(cos(angle), sin(angle)) * (70.0 + randi() % 120),
            "t": 0.0,
            "life": 0.42,
            "target": p,
            "kind": 2
        })

func _spawn_snake_hit_vfx(damage: int) -> void:
    var p := Vector2(575, 330)
    _spawn_vfx_ring(p, 20.0, 125.0 + damage * 12.0, Color(1.0, 0.36, 0.18, 0.95), 0.38)
    for i in range(8 + damage * 2):
        var angle := TAU * float(i) / float(8 + damage * 2)
        effects.append({
            "p": p,
            "v": Vector2(cos(angle), sin(angle)) * (100.0 + randi() % 100),
            "t": 0.0,
            "life": 0.36 + float(randi() % 15) / 100.0,
            "target": p,
            "kind": 3
        })

func _spawn_impact_burst(p: Vector2, radius: float, color: Color, life: float = 0.34) -> void:
    impact_bursts.append({"p": p, "r": radius, "t": 0.0, "life": life, "color": color})

func _spawn_boss_attack_sequence(damage: int) -> void:
    var origin := Vector2(hero_x + 30.0, hero_y - 8.0)
    var target := Vector2(575, 330)
    var color := Color("ffcf5a")
    match boss_kind:
        "guardian": color = Color("8fe8ff")
        "beast": color = Color("ff694f")
        "dragon": color = Color("c97aff")
        "snake": color = Color("ffb34d")
    _spawn_impact_burst(origin, 55.0 + damage * 8.0, color, 0.24)
    slash_effects.append({"a": origin, "b": target, "t": 0.0, "life": 0.28, "color": color})
    boss_projectiles.append({"p": origin, "target": target, "t": 0.0, "life": 0.34, "color": color})
    if damage >= 2:
        boss_projectiles.append({"p": origin + Vector2(0, 18), "target": target + Vector2(0, -18), "t": 0.04, "life": 0.30, "color": Color("fff1a8")})

func _spawn_boss_defeat_vfx() -> void:
    _set_combat_animation("defeat")
    _emit_combat_particles(false, 60)
    var p := Vector2(575, 330)
    _spawn_impact_burst(p, 190.0, Color("ffe17a"), 0.72)
    _spawn_impact_burst(p, 105.0, Color("ff704f"), 0.46)
    for i in range(22):
        var a := TAU * float(i) / 22.0
        boss_projectiles.append({"p": p, "target": p + Vector2(cos(a), sin(a)) * (90.0 + randi() % 120), "t": 0.0, "life": 0.65, "color": Color("ffe38a")})

func _update_impact_bursts(delta: float) -> void:
    for i in range(impact_bursts.size() - 1, -1, -1):
        var e: Dictionary = impact_bursts[i]
        e["t"] = float(e["t"]) + delta
        impact_bursts[i] = e
        if float(e["t"]) >= float(e["life"]): impact_bursts.remove_at(i)

func _update_slash_effects(delta: float) -> void:
    for i in range(slash_effects.size() - 1, -1, -1):
        var e: Dictionary = slash_effects[i]
        e["t"] = float(e["t"]) + delta
        slash_effects[i] = e
        if float(e["t"]) >= float(e["life"]): slash_effects.remove_at(i)

func _update_boss_projectiles(delta: float) -> void:
    for i in range(boss_projectiles.size() - 1, -1, -1):
        var e: Dictionary = boss_projectiles[i]
        e["t"] = float(e["t"]) + delta
        boss_projectiles[i] = e
        if float(e["t"]) >= float(e["life"]): boss_projectiles.remove_at(i)

func _draw_impact_bursts() -> void:
    for e in impact_bursts:
        var life := clampf(1.0 - float(e["t"]) / float(e["life"]), 0.0, 1.0)
        var t := 1.0 - life
        var p: Vector2 = e["p"]
        var r := float(e["r"]) * (0.25 + t * 0.75)
        var c: Color = e["color"]
        c.a = life * 0.55
        draw_circle(p, r, Color(c.r,c.g,c.b,c.a * 0.10))
        draw_arc(p, r, 0, TAU, 36, c, 7.0)
        draw_arc(p, r * 0.62, 0, TAU, 28, Color(1,0.94,0.7,life*0.7), 4.0)

func _draw_slash_effects() -> void:
    for e in slash_effects:
        var life := clampf(1.0 - float(e["t"]) / float(e["life"]), 0.0, 1.0)
        var p: Vector2 = e["a"].lerp(e["b"], 1.0 - life)
        var d: Vector2 = (e["b"] - e["a"]).normalized()
        var side := Vector2(-d.y, d.x) * 22.0 * life
        var c: Color = e["color"]
        draw_line(p - side - d * 28.0, p + side + d * 28.0, Color(c.r,c.g,c.b,life*0.28), 18.0)
        draw_line(p - side, p + side, Color(1,1,0.88,life*0.95), 6.0)

func _draw_boss_projectiles() -> void:
    for e in boss_projectiles:
        var t := clampf(float(e["t"]) / float(e["life"]), 0.0, 1.0)
        var p: Vector2 = e["p"].lerp(e["target"], t)
        var life := 1.0 - t
        var c: Color = e["color"]
        draw_texture_rect(PARTICLE_TEX, Rect2(p - Vector2.ONE * (18.0 + 14.0 * life), Vector2.ONE * (36.0 + 28.0 * life)), false, Color(c.r,c.g,c.b,life*0.9))
        draw_circle(p, 5.0 + 5.0 * life, Color(1,1,1,life))

func _spawn_rescue_celebration() -> void:
    rescue_confetti.clear()
    for i in range(34):
        rescue_confetti.append({
            "p": Vector2(540, 430),
            "v": Vector2(-90.0 + randi() % 181, -220.0 - randi() % 130),
            "t": 0.0,
            "life": 1.4 + float(randi() % 80) / 100.0,
            "rot": float(randi() % 6)
        })
    _spawn_vfx_ring(Vector2(540, 430), 20.0, 180.0, Color(1.0, 0.84, 0.28, 1.0), 0.65)

func _update_rescue_confetti(delta: float) -> void:
    for i in range(rescue_confetti.size() - 1, -1, -1):
        var item: Dictionary = rescue_confetti[i]
        item["t"] = float(item["t"]) + delta
        item["p"] = Vector2(item["p"]) + Vector2(item["v"]) * delta
        item["v"] = Vector2(item["v"]) + Vector2(0, 260.0) * delta
        rescue_confetti[i] = item
        if float(item["t"]) >= float(item["life"]):
            rescue_confetti.remove_at(i)

func _draw_rescue_confetti() -> void:
    for item in rescue_confetti:
        var life := clampf(1.0 - float(item["t"]) / float(item["life"]), 0.0, 1.0)
        var p := Vector2(item["p"])
        var s := 5.0 + 3.0 * life
        draw_rect(Rect2(p - Vector2(s, s * 0.5), Vector2(s * 2.0, s)), Color(1.0, 0.82, 0.25, life), true)

func _spawn_match_bursts(matches: Array[Vector2i]) -> void:
    for cell in matches:
        var p := Vector2(BOARD_X + cell.x * CELL + (CELL - 5) * 0.5, BOARD_Y + cell.y * CELL + (CELL - 5) * 0.5)
        _spawn_vfx_ring(p, 16.0, 72.0, Color(1.0, 0.78, 0.22, 0.9), 0.30)
        for i in range(10):
            var angle := TAU * float(i) / 10.0
            effects.append({
                "p": p,
                "v": Vector2(cos(angle), sin(angle)) * (75.0 + randi() % 80),
                "t": 0.0,
                "life": 0.42 + float(randi() % 20) / 100.0,
                "target": p,
                "kind": 1
            })

func _cell_center(cell: Vector2i) -> Vector2:
    return Vector2(BOARD_X + cell.x * CELL + (CELL - 5) * 0.5, BOARD_Y + cell.y * CELL + (CELL - 5) * 0.5)

func _spawn_vfx_ring(p: Vector2, start_radius: float, end_radius: float, color: Color, life: float) -> void:
    vfx_rings.append({"p": p, "r0": start_radius, "r1": end_radius, "t": 0.0, "life": life, "color": color})

func _spawn_tile_trail(a: Vector2i, b: Vector2i) -> void:
    tile_trails.append({"from": _cell_center(a), "to": _cell_center(b), "t": 0.0, "life": 0.20})

func _update_vfx_rings(delta: float) -> void:
    for i in range(vfx_rings.size() - 1, -1, -1):
        var ring: Dictionary = vfx_rings[i]
        ring["t"] = float(ring["t"]) + delta
        vfx_rings[i] = ring
        if float(ring["t"]) >= float(ring["life"]):
            vfx_rings.remove_at(i)

func _update_tile_trails(delta: float) -> void:
    for i in range(tile_trails.size() - 1, -1, -1):
        var trail: Dictionary = tile_trails[i]
        trail["t"] = float(trail["t"]) + delta
        tile_trails[i] = trail
        if float(trail["t"]) >= float(trail["life"]):
            tile_trails.remove_at(i)

func _draw_vfx_rings() -> void:
    for ring in vfx_rings:
        var life := clampf(1.0 - float(ring["t"]) / float(ring["life"]), 0.0, 1.0)
        var t := 1.0 - life
        var radius := lerpf(float(ring["r0"]), float(ring["r1"]), t)
        var c: Color = ring["color"]
        c.a *= life
        draw_arc(Vector2(ring["p"]), radius, 0.0, TAU, 32, c, 5.0)

func _draw_tile_trails() -> void:
    for trail in tile_trails:
        var life := clampf(1.0 - float(trail["t"]) / float(trail["life"]), 0.0, 1.0)
        draw_line(Vector2(trail["from"]), Vector2(trail["to"]), Color(1, 1, 1, life * 0.18), 20.0)
        draw_line(Vector2(trail["from"]), Vector2(trail["to"]), Color(1, 0.88, 0.4, life * 0.45), 7.0)

func _spawn_attack_effects(match_count: int) -> void:
    var origin := Vector2(hero_x + 28, hero_y - 8)
    var target: Vector2 = (PATH_POINTS[obstacle_index] + PATH_POINTS[obstacle_index + 1]) * 0.5 if obstacle_index < PATH_POINTS.size() - 1 else origin
    for i in range(mini(14, 5 + match_count * 2)):
        var angle := TAU * float(i) / float(maxi(1, 5 + match_count * 2))
        effects.append({
            "p": origin,
            "v": Vector2(cos(angle), sin(angle)) * (90.0 + randi() % 100),
            "t": 0.0,
            "life": 0.45 + float(randi() % 30) / 100.0,
            "target": target,
            "kind": 0
        })

func _update_effects(delta: float) -> void:
    for i in range(effects.size() - 1, -1, -1):
        var e: Dictionary = effects[i]
        e["t"] = float(e["t"]) + delta
        e["p"] = Vector2(e["p"]) + Vector2(e["v"]) * delta
        e["v"] = Vector2(e["v"]) * 0.91
        effects[i] = e
        if float(e["t"]) >= float(e["life"]):
            effects.remove_at(i)

func _draw_effects() -> void:
    for e in effects:
        var life := maxf(0.0, 1.0 - float(e["t"]) / float(e["life"]))
        var p := Vector2(e["p"])
        var kind := int(e.get("kind", 0))
        if kind == 1:
            var particle_size := 18.0 + 24.0 * life
            draw_texture_rect(PARTICLE_TEX, Rect2(p - Vector2.ONE * particle_size * 0.5, Vector2.ONE * particle_size), false, Color(1, 0.88, 0.35, life * 0.9))
            draw_line(p, p - Vector2(e["v"]) * 0.08, Color(1.0, 0.55, 0.12, life), 3.0)
        elif kind == 2:
            draw_circle(p, 6.0 + 7.0 * life, Color(0.72, 0.64, 0.55, life))
            draw_line(p, p - Vector2(e["v"]) * 0.06, Color(0.96, 0.88, 0.72, life), 4.0)
        elif kind == 3:
            draw_circle(p, 5.0 + 7.0 * life, Color(1.0, 0.34, 0.12, life))
            draw_line(p, p - Vector2(e["v"]) * 0.08, Color(1.0, 0.86, 0.36, life), 4.0)
        else:
            draw_circle(p, 5.0 + 6.0 * life, Color(1.0, 0.78, 0.2, life))
            draw_circle(p, 2.5, Color(1, 1, 1, life))

func _draw_rescue_badge() -> void:
    if not rescue_open:
        return
    draw_circle(Vector2(590, 225), 34, Color(0.12, 0.55, 0.28, 0.9))
    draw_string(ThemeDB.fallback_font, Vector2(567, 233), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)

func _swap(a: Vector2i, b: Vector2i) -> void:
    var tmp = board[a.y][a.x]
    board[a.y][a.x] = board[b.y][b.x]
    board[b.y][b.x] = tmp

func _find_matches() -> Array[Vector2i]:
    var found := {}
    for y in ROWS:
        var run := 1
        for x in range(1, COLS + 1):
            if x < COLS and board[y][x] == board[y][x - 1]:
                run += 1
            else:
                if run >= 3:
                    for k in run:
                        found[Vector2i(x - 1 - k, y)] = true
                run = 1

    for x in COLS:
        var run := 1
        for y in range(1, ROWS + 1):
            if y < ROWS and board[y][x] == board[y - 1][x]:
                run += 1
            else:
                if run >= 3:
                    for k in run:
                        found[Vector2i(x, y - 1 - k)] = true
                run = 1

    return Array(found.keys())

func _clear_matches(matches: Array[Vector2i], keep_cell: Vector2i = Vector2i(-1, -1), special_value: int = -1) -> void:
    for cell in matches:
        if cell == keep_cell and special_value >= 0:
            board[cell.y][cell.x] = special_value
        else:
            board[cell.y][cell.x] = -1

func _is_special(value: int) -> bool:
    return value == SPECIAL_H or value == SPECIAL_V or value == SPECIAL_BOMB or value == SPECIAL_COLOR

func _vertical_match_at(matches: Array[Vector2i], cell: Vector2i) -> bool:
    var count := 0
    for m in matches:
        if m.x == cell.x:
            count += 1
    return count >= 4

func _activate_special_swap(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
    var av := board[a.y][a.x]
    var bv := board[b.y][b.x]
    var cells := {}
    if av == SPECIAL_COLOR or bv == SPECIAL_COLOR:
        var color_other := bv if av == SPECIAL_COLOR else av
        if color_other == SPECIAL_COLOR:
            for y in ROWS:
                for x in COLS:
                    cells[Vector2i(x, y)] = true
        else:
            for y in ROWS:
                for x in COLS:
                    if board[y][x] == color_other or _is_special(board[y][x]):
                        cells[Vector2i(x, y)] = true
    elif av == SPECIAL_BOMB and bv == SPECIAL_BOMB:
        for y in ROWS:
            for x in COLS:
                cells[Vector2i(x, y)] = true
    elif av == SPECIAL_BOMB or bv == SPECIAL_BOMB:
        var other := b if av == SPECIAL_BOMB else a
        var color := board[other.y][other.x]
        for y in ROWS:
            for x in COLS:
                if board[y][x] == color or _is_special(board[y][x]):
                    cells[Vector2i(x, y)] = true
        for y in ROWS:
            for x in COLS:
                if board[y][x] == SPECIAL_H or board[y][x] == SPECIAL_V:
                    for xx in COLS:
                        cells[Vector2i(xx, y)] = true
                    for yy in ROWS:
                        cells[Vector2i(x, yy)] = true
    else:
        var first := a if _is_special(av) else b
        var second := b if first == a else a
        var fv := board[first.y][first.x]
        var sv := board[second.y][second.x]
        if (fv == SPECIAL_H and sv == SPECIAL_V) or (fv == SPECIAL_V and sv == SPECIAL_H):
            for x in COLS:
                cells[Vector2i(x, first.y)] = true
            for y in ROWS:
                cells[Vector2i(first.x, y)] = true
        else:
            for x in COLS:
                cells[Vector2i(x, first.y)] = true
            for y in ROWS:
                cells[Vector2i(first.x, y)] = true
    var result: Array[Vector2i] = Array(cells.keys())
    _spawn_booster_paths(result)
    return result

func _spawn_booster_paths(cells: Array[Vector2i]) -> void:
    var seen := {}
    for cell in cells:
        if not _inside(cell) or seen.has(cell):
            continue
        seen[cell] = true
        var center := Vector2(BOARD_X + cell.x * CELL + (CELL - 5) * 0.5, BOARD_Y + cell.y * CELL + (CELL - 5) * 0.5)
        var value: int = board[cell.y][cell.x]
        if value == SPECIAL_H:
            booster_paths.append({"from": center - Vector2(CELL * 2.8, 0), "to": center + Vector2(CELL * 2.8, 0), "t": 0.0, "life": 0.30})
        elif value == SPECIAL_V:
            booster_paths.append({"from": center - Vector2(0, CELL * 2.3), "to": center + Vector2(0, CELL * 2.3), "t": 0.0, "life": 0.30})
        elif value == SPECIAL_BOMB:
            for dir in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
                booster_paths.append({"from": center, "to": center + dir * CELL * 1.9, "t": 0.0, "life": 0.24})

func _check_goal() -> void:
    if goal_kind == "collect" and goal_progress >= goal_target:
        _complete_level()
    elif goal_kind == "special" and goal_progress >= goal_target:
        _complete_level()

func _complete_level() -> void:
    if level_won:
        return
    level_won = true
    combat_active = false
    _play_sfx("win", 1.2)
    rescue_open = true
    var earned_stars := 1
    if moves >= 12:
        earned_stars = 3
    elif moves >= 6:
        earned_stars = 2
    var previous_stars: int = level_stars[level_number]
    if earned_stars > previous_stars:
        stars += earned_stars - previous_stars
        level_stars[level_number] = earned_stars
    level_coins += earned_stars * 5
    chest_reward = 0
    if level_number in [3, 6, 9]:
        chest_reward = 25 + level_number * 5
        chests_opened += 1
        ability_hammer += 1
        ability_blast += 1
    coins += level_coins + chest_reward
    _check_star_chest_rewards()
    best_score = maxi(best_score, score)
    var before_unlock_count := unlocked_levels.size()
    _unlock_after_level(level_number)
    unlocked_level = maxi(unlocked_level, level_number + 1)
    if unlocked_levels.size() > before_unlock_count:
        unlock_flash = 1.0
    campaign_complete = level_number >= 10
    _save_progress()
    rescue_celebration = 1.0
    art_defeat_phase = 1.0
    defeat_burst = 1.0
    _spawn_boss_defeat_vfx()
    screen_shake = 0.25
    camera_zoom = 1.035
    _spawn_rescue_celebration()
    message = "نجاح! +%d ★  +%d ◆%s" % [earned_stars, level_coins + chest_reward, " • صندوق!" if chest_reward > 0 else ""]


func _collapse() -> void:
    collapse_animating = true
    for x in COLS:
        var old_values: Array = []
        for y in ROWS:
            old_values.append(board[y][x])

        var values: Array = []
        for y in ROWS:
            if board[y][x] >= 0:
                values.append(board[y][x])

        var missing := ROWS - values.size()
        while values.size() < ROWS:
            values.push_front(randi() % COLORS.size())

        for y in ROWS:
            board[y][x] = values[y]
            tile_scale[y][x] = 0.92
            tile_alpha[y][x] = 1.0
            var source_index := -1
            for oy in range(ROWS):
                if old_values[oy] == values[y] and old_values[oy] >= 0:
                    source_index = oy
                    old_values[oy] = -2
                    break
            if source_index >= 0:
                tile_offset[y][x] = Vector2(0, (source_index - y) * CELL)
            else:
                tile_offset[y][x] = Vector2(0, -(missing + 1) * CELL)

func _prime_match_animation(matches: Array[Vector2i]) -> void:
    for cell in matches:
        if _inside(cell):
            tile_scale[cell.y][cell.x] = 1.12
            _spawn_vfx_ring(_cell_center(cell), 18.0, 62.0, Color(1.0, 0.88, 0.34, 0.9), 0.20)

func _update_tile_animations(delta: float) -> void:
    var done := true
    for y in ROWS:
        for x in COLS:
            tile_offset[y][x] = tile_offset[y][x].lerp(Vector2.ZERO, minf(1.0, delta * 10.0))
            tile_scale[y][x] = lerpf(tile_scale[y][x], 1.0, minf(1.0, delta * 12.0))
            if tile_offset[y][x].length() > 0.5 or absf(tile_scale[y][x] - 1.0) > 0.02:
                done = false
    collapse_animating = not done

func _update_booster_paths(delta: float) -> void:
    for i in range(booster_paths.size() - 1, -1, -1):
        var path: Dictionary = booster_paths[i]
        path["t"] = float(path["t"]) + delta
        booster_paths[i] = path
        if float(path["t"]) >= float(path["life"]):
            booster_paths.remove_at(i)

func _draw_booster_path(path: Dictionary) -> void:
    var from: Vector2 = path["from"]
    var to: Vector2 = path["to"]
    var life := clampf(1.0 - float(path["t"]) / float(path["life"]), 0.0, 1.0)
    var p := from.lerp(to, clampf(float(path["t"]) / float(path["life"]), 0.0, 1.0))
    var kind := str(path.get("kind", "horizontal"))
    var glow := Color(1.0, 0.82, 0.25, life * 0.55)
    var core := Color(1.0, 1.0, 0.9, life)
    if kind == "vertical":
        glow = Color(0.35, 0.78, 1.0, life * 0.58)
        core = Color(0.86, 0.96, 1.0, life)
    elif kind == "bomb":
        glow = Color(1.0, 0.32, 0.14, life * 0.62)
        core = Color(1.0, 0.9, 0.68, life)
    draw_line(from, p, glow, 15.0)
    draw_line(from, p, core, 4.0)
    draw_circle(p, 9.0 + 8.0 * life, core)

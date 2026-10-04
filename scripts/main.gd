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

const HERO_TEX := preload("res://assets/art/hero.svg")
const SNAKE_TEX := preload("res://assets/art/snake.svg")
const ROCK_TEX := preload("res://assets/art/rock.svg")
const CAPTIVE_TEX := preload("res://assets/art/captive.svg")
const SCENE_TEX := preload("res://assets/art/scene.svg")
const GEMS_TEX := preload("res://assets/art/gems.svg")

func _ready() -> void:
    randomize()
    _load_progress()
    screen_mode = "map"
    queue_redraw()

func _process(delta: float) -> void:
    hero_bounce += delta * 5.0
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
    fever_flash = maxf(0.0, fever_flash - delta * 3.0)
    near_miss_flash = maxf(0.0, near_miss_flash - delta * 3.5)
    _update_tile_animations(delta)
    _update_booster_paths(delta)
    _update_vfx_rings(delta)
    _update_tile_trails(delta)
    _update_effects(delta)
    queue_redraw()

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
            level_modifier = "ضغط الحركات"
        6:
            moves = 27
            level_modifier = "زعيم الحارس"
        7:
            moves = 21
            level_modifier = "سلسلة خاصة"
        8:
            moves = 19
            level_modifier = "جمع سريع"
        9:
            moves = 28
            level_modifier = "زعيم الوحش"
        10:
            moves = 32
            level_modifier = "المواجهة النهائية"
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
    screen_shake = 0.0
    swap_animating = false
    collapse_animating = false
    booster_paths.clear()
    vfx_rings.clear()
    tile_trails.clear()

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
    _draw_rescue_confetti()
    _draw_rescue_badge()
    if level_won or level_lost:
        _draw_end_panel()

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
            goal_target = 4

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
    screen_mode = "level"
    _new_level()

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
    var nodes := [Vector2(110,190),Vector2(250,250),Vector2(390,190),Vector2(285,390),Vector2(470,390),Vector2(360,540),Vector2(235,680),Vector2(485,680),Vector2(360,830),Vector2(360,990)]
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
        draw_circle(p,44,Color("30271f"))
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

func _handle_map_tap(pos: Vector2) -> void:
    var nodes := [Vector2(110,190),Vector2(250,250),Vector2(390,190),Vector2(285,390),Vector2(470,390),Vector2(360,540),Vector2(235,680),Vector2(485,680),Vector2(360,830),Vector2(360,990)]
    for i in range(nodes.size()):
        if pos.distance_to(nodes[i]) <= 58.0:
            _start_level(i + 1)
            return

func _draw_end_panel() -> void:
    draw_rect(Rect2(55, 350, 610, 430), Color(0.06, 0.04, 0.03, 0.96))
    draw_rect(Rect2(62, 357, 596, 416), Color("6d4a24"), false, 5)
    if level_won:
        draw_string(ThemeDB.fallback_font, Vector2(175, 430), "NIVEAU RÉUSSI !", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("ffe17a"))
        var earned := 3 if moves >= 12 else (2 if moves >= 6 else 1)
        draw_string(ThemeDB.fallback_font, Vector2(220, 490), "★".repeat(earned), HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color("ffd34d"))
        draw_string(ThemeDB.fallback_font, Vector2(190, 545), "%d points" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
        draw_string(ThemeDB.fallback_font, Vector2(190, 585), "+%d ◆" % (level_coins + earned * 5 + chest_reward), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffe17a"))
        if chest_reward > 0:
            draw_string(ThemeDB.fallback_font, Vector2(190, 615), "صندوق كنز: +%d ◆ +قدرات" % chest_reward, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffd45b"))
        draw_rect(Rect2(165, 650, 390, 70), Color("b98220"))
        draw_string(ThemeDB.fallback_font, Vector2(250, 696), "CONTINUER", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)
    else:
        draw_string(ThemeDB.fallback_font, Vector2(210, 450), "NIVEAU ÉCHOUÉ", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("ff927b"))
        draw_string(ThemeDB.fallback_font, Vector2(205, 510), "Score : %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
        draw_rect(Rect2(165, 650, 390, 70), Color("8e392d"))
        draw_string(ThemeDB.fallback_font, Vector2(260, 696), "RÉESSAYER", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color.WHITE)

func _handle_end_tap(pos: Vector2) -> void:
    if pos.x < 110 or pos.x > 610 or pos.y < 620 or pos.y > 745:
        return
    if level_lost:
        _new_level()
        return
    if level_won:
        screen_mode = "map"
        queue_redraw()

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
    if unlocked_levels.is_empty():
        unlocked_levels = [1]
    if level_stars.size() < 11:
        level_stars.resize(11)

func _draw_top_hud() -> void:
    draw_rect(Rect2(0, 0, 720, 92), Color("2a211b"))
    draw_rect(Rect2(0, 88, 720, 7), Color("e9b62f"))
    draw_string(ThemeDB.fallback_font, Vector2(30, 38), "PUZZLE HEROES", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("fff4d0"))
    draw_string(ThemeDB.fallback_font, Vector2(30, 68), "NIVEAU %d" % level_number, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d7c29a"))
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
    # Premium illustrated rescue chamber asset.
    draw_texture_rect(SCENE_TEX, Rect2(18, 108, 684, 548), false)
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

    # Large original serpent.
    var snake_center := Vector2(420, 285 + sin(hero_bounce * 0.7) * 3.0)
    _draw_large_snake(snake_center)

    # Rescue chamber and captive.
    draw_rect(Rect2(438, 405, 205, 168), Color("241c16"))
    draw_rect(Rect2(447, 414, 187, 150), Color("4b3828"))
    draw_line(Vector2(447, 505), Vector2(634, 505), Color("d1a44a"), 8)
    if level_won:
        draw_texture_rect(CAPTIVE_TEX, Rect2(492, 425, 112, 142), false)
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
    var bob := sin(hero_bounce) * 3.0 + sin(hero_anim_phase * 1.7) * 2.0
    if combat_active:
        bob += sin(hero_anim_phase * 2.8) * 3.0
    var strike := sin((1.0 - hero_strike) * PI) if hero_strike > 0.0 else 0.0
    var recoil := hero_attack * -18.0 + strike * 28.0
    var size := Vector2(126, 160) * (1.0 + strike * 0.035)
    var p := pos + Vector2(recoil, bob)
    draw_texture_rect(HERO_TEX, Rect2(p - size * 0.5, size), false)
    if hero_attack > 0.0 or hero_strike > 0.0:
        var reach := 42.0 + strike * 52.0
        draw_line(p + Vector2(42, -10), p + Vector2(reach, -10), Color(1.0, 0.84, 0.25, maxf(hero_attack, strike)), 7.0)
        draw_circle(p + Vector2(reach, -10), 8.0 + strike * 7.0, Color(1.0, 0.94, 0.55, strike * 0.8))

func _draw_large_snake(pos: Vector2) -> void:
    var hit := sin((1.0 - snake_hit_flash) * PI) if snake_hit_flash > 0.0 else 0.0
    var boss_bob := sin(snake_boss_phase) * (5.0 if combat_active else 2.0)
    var boss_pulse_scale := 1.0 + (0.025 + 0.02 * sin(snake_boss_phase * 2.0)) if combat_active else 1.0
    var shake := sin(hero_bounce * 34.0) * snake_shake * 9.0
    var recoil := -snake_recoil * 28.0
    var scale := 0.72 + hit * 0.035
    var size := Vector2(600, 300) * scale
    var p := pos + Vector2(recoil + shake, boss_bob)
    size *= boss_pulse_scale
    draw_texture_rect(SNAKE_TEX, Rect2(p - size * 0.5, size), false)
    if combat_active:
        draw_arc(p + Vector2(145, 35), 188.0 + sin(snake_boss_phase * 2.0) * 8.0, PI * 0.15, PI * 0.85, 28, Color(1.0, 0.32, 0.16, 0.22), 8.0)
        draw_string(ThemeDB.fallback_font, p + Vector2(-155, -120), "BOSS • " + _boss_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1.0, 0.46, 0.28, 0.88))
        draw_string(ThemeDB.fallback_font, p + Vector2(-150, -94), "PV %d/%d" % [snake_hp, boss_max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe0b0"))
    if snake_hit_flash > 0.0:
        draw_circle(p + Vector2(160, 45), 58.0 + hit * 12.0, Color(1, 0.9, 0.2, snake_hit_flash * 0.28))
        draw_arc(p + Vector2(160, 45), 72.0 + hit * 16.0, 0, TAU, 28, Color(1, 0.55, 0.2, snake_hit_flash * 0.75), 8.0)

func _draw_board() -> void:
    draw_rect(Rect2(24, 666, 672, 580), Color("b98628"))
    draw_rect(Rect2(32, 674, 656, 564), Color("e8d4a7"))
    draw_string(ThemeDB.fallback_font, Vector2(48, 698), "MATCH 3", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("68451d"))

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
        busy = false
        queue_redraw()
        return

    moves -= 1
    cascade = 0
    combo = 0
    await _resolve_cascade(matches)
    if moves <= 0 and not level_won:
        level_lost = true
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
        level_coins += maxi(1, matches.size() / 3)

        if goal_kind == "collect":
            for cell in matches:
                if board[cell.y][cell.x] == goal_color:
                    goal_progress = mini(goal_target, goal_progress + 1)

        var special_cell := matches[mini(matches.size() / 2, matches.size() - 1)]
        var special_value := -1
        if matches.size() >= 5:
            special_value = SPECIAL_BOMB
        elif matches.size() == 4:
            special_value = SPECIAL_H if not _vertical_match_at(matches, special_cell) else SPECIAL_V
        if special_value >= 0 and goal_kind == "special":
            goal_progress = mini(goal_target, goal_progress + 1)

        message = ("FEVER!  " if fever > 0.0 else "") + "COMBO x%d  +%d" % [combo, points]
        _prime_match_animation(matches)
        await get_tree().create_timer(0.11).timeout
        _spawn_match_bursts(matches)
        _clear_matches(matches, special_cell, special_value)
        _apply_adventure_damage(matches.size())
        if combat_active:
            _apply_snake_damage(matches.size())
        _spawn_attack_effects(matches.size())
        _collapse()
        refill_anim = 0.0
        hero_attack = 1.0
        screen_shake = minf(1.0, 0.18 + cascade * 0.06)
        await get_tree().create_timer(0.10).timeout
        matches = _find_matches()
        if matches.size() == 0 and combo >= 2:
            near_miss_flash = 1.0
            message = "SÉRIE TERMINÉE ! Prépare le prochain COMBO."

    _check_goal()
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
    snake_hp = max(0, snake_hp - damage)
    snake_recoil = 1.0
    snake_shake = 1.0
    hero_strike = 1.0
    screen_shake = maxf(screen_shake, 0.62)
    camera_zoom = 1.045
    boss_pulse = 1.0
    snake_hit_flash = 1.0
    snake_alert = 1.0
    score += damage * 25
    _spawn_attack_effects(match_count)
    _spawn_snake_hit_vfx(damage)

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
            draw_circle(p, 7.0 + 9.0 * life, Color(1.0, 0.82, 0.22, life))
            draw_circle(p, 3.0, Color(1, 1, 1, life))
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
    return value == SPECIAL_H or value == SPECIAL_V or value == SPECIAL_BOMB

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
    if av == SPECIAL_BOMB and bv == SPECIAL_BOMB:
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
    best_score = maxi(best_score, score)
    _unlock_after_level(level_number)
    unlocked_level = maxi(unlocked_level, level_number + 1)
    campaign_complete = level_number >= 10
    _save_progress()
    rescue_celebration = 1.0
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

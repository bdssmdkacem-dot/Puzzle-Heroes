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

var dragging := false
var drag_start := Vector2.ZERO
var drag_cell := Vector2i(-1, -1)
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
var effects: Array = []
var refill_anim := 1.0
var hero_attack := 0.0

const HERO_TEX := preload("res://assets/art/hero.svg")
const SNAKE_TEX := preload("res://assets/art/snake.svg")
const ROCK_TEX := preload("res://assets/art/rock.svg")
const CAPTIVE_TEX := preload("res://assets/art/captive.svg")
const SCENE_TEX := preload("res://assets/art/scene.svg")
const GEMS_TEX := preload("res://assets/art/gems.svg")

func _ready() -> void:
    randomize()
    _new_level()
    queue_redraw()

func _process(delta: float) -> void:
    hero_bounce += delta * 5.0
    snake_alert = maxf(0.0, snake_alert - delta * 2.5)
    obstacle_flash = maxf(0.0, obstacle_flash - delta * 3.5)
    attack_flash = maxf(0.0, attack_flash - delta * 4.0)
    snake_hit_flash = maxf(0.0, snake_hit_flash - delta * 5.0)
    refill_anim = minf(1.0, refill_anim + delta * 3.8)
    hero_attack = maxf(0.0, hero_attack - delta * 3.8)
    _update_effects(delta)
    queue_redraw()

func _new_level() -> void:
    board.clear()
    for y in ROWS:
        var row: Array = []
        for x in COLS:
            var value := randi() % COLORS.size()
            while x >= 2 and row[x - 1] == value and row[x - 2] == value:
                value = randi() % COLORS.size()
            while y >= 2 and board[y - 1][x] == value and board[y - 2][x] == value:
                value = randi() % COLORS.size()
            row.append(value)
        board.append(row)

    score = 0
    moves = 25
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
    effects.clear()
    refill_anim = 1.0
    hero_attack = 0.0

    message = "Aligne 3 tuiles pour casser le rocher !"
    level_won = false
    level_lost = false
    busy = false

func _draw() -> void:
    # Full-screen portrait adventure layout inspired by premium mobile puzzle games.
    draw_rect(Rect2(0, 0, 720, 1280), Color("17120f"))
    _draw_top_hud()
    _draw_rescue_scene()
    _draw_board()
    _draw_effects()
    _draw_rescue_badge()

func _draw_top_hud() -> void:
    draw_rect(Rect2(0, 0, 720, 92), Color("2a211b"))
    draw_rect(Rect2(0, 88, 720, 7), Color("e9b62f"))
    draw_string(ThemeDB.fallback_font, Vector2(30, 38), "PUZZLE HEROES", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("fff4d0"))
    draw_string(ThemeDB.fallback_font, Vector2(30, 68), "NIVEAU 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("d7c29a"))
    draw_circle(Vector2(552, 43), 18, Color("e9b62f"))
    draw_string(ThemeDB.fallback_font, Vector2(544, 51), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("5a3b10"))
    draw_string(ThemeDB.fallback_font, Vector2(580, 51), str(score), HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color.WHITE)
    draw_rect(Rect2(625, 23, 65, 42), Color("49372a"))
    draw_string(ThemeDB.fallback_font, Vector2(637, 51), str(moves), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("fff1bd"))

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
    var objective := "COMBAT !" if combat_active else ("SAUVETAGE !" if level_won else "CASSE LE MUR")
    draw_string(ThemeDB.fallback_font, Vector2(280, 148), objective, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("ffe6a1"))

func _draw_hero(pos: Vector2) -> void:
    var bob := sin(hero_bounce) * 3.0
    var recoil := hero_attack * -18.0
    var size := Vector2(126, 160)
    var p := pos + Vector2(recoil, bob)
    draw_texture_rect(HERO_TEX, Rect2(p - size * 0.5, size), false)
    if hero_attack > 0.0:
        draw_line(p + Vector2(48, -12), p + Vector2(90, -12), Color(1.0, 0.84, 0.25, hero_attack), 7)

func _draw_large_snake(pos: Vector2) -> void:
    var scale := 0.72 + snake_hit_flash * 0.04
    var size := Vector2(600, 300) * scale
    draw_texture_rect(SNAKE_TEX, Rect2(pos - size * 0.5, size), false)
    if snake_hit_flash > 0.0:
        draw_circle(pos + Vector2(160, 45), 58, Color(1, 0.9, 0.2, snake_hit_flash * 0.28))

func _draw_board() -> void:
    draw_rect(Rect2(24, 666, 672, 580), Color("b98628"))
    draw_rect(Rect2(32, 674, 656, 564), Color("e8d4a7"))
    draw_string(ThemeDB.fallback_font, Vector2(48, 698), "MATCH 3", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("68451d"))
    for y in ROWS:
        for x in COLS:
            var rect := Rect2(BOARD_X + x * CELL, BOARD_Y + y * CELL, CELL - 5, CELL - 5)
            draw_style_box(_cell_box(), rect)
            var value: int = board[y][x]
            var center := rect.get_center()
            if refill_anim < 1.0:
                center.y -= (1.0 - refill_anim) * float((ROWS - y) * 46)
            _draw_gem(center, value)

    draw_rect(Rect2(32, 1248, 656, 32), Color("241c17"))
    draw_string(ThemeDB.fallback_font, Vector2(50, 1271), message, HORIZONTAL_ALIGNMENT_LEFT, 620, 16, Color.WHITE)

func _draw_gem(center: Vector2, value: int) -> void:
    var src := Rect2(value * 150, 0, 150, 150)
    draw_texture_rect_region(GEMS_TEX, Rect2(center - Vector2(36, 36), Vector2(72, 72)), src)

func _cell_box() -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color("f8f0dd")
    box.border_color = Color("c9af7b")
    box.set_border_width_all(2)
    box.set_corner_radius_all(9)
    return box

func _input(event: InputEvent) -> void:
    if busy:
        return

    # Android / iOS touch. Normalize to the 720x1280 design space.
    if event is InputEventScreenTouch:
        if event.pressed and active_touch_index == -1:
            active_touch_index = event.index
            drag_start = _input_to_design(event.position)
            drag_cell = _screen_to_cell(drag_start)
            dragging = drag_cell.x >= 0
        elif not event.pressed and event.index == active_touch_index:
            if dragging:
                _finish_drag(_input_to_design(event.position))
            dragging = false
            active_touch_index = -1

    elif event is InputEventScreenDrag and dragging and event.index == active_touch_index:
        var current_pos: Vector2 = _input_to_design(event.position)
        var delta: Vector2 = current_pos - drag_start
        if delta.length() >= 28.0:
            _finish_drag(current_pos)

    # Mouse input is useful for desktop testing.
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            drag_start = event.position
            drag_cell = _screen_to_cell(event.position)
            dragging = drag_cell.x >= 0
        elif dragging:
            _finish_drag(event.position)

    elif event is InputEventMouseMotion and dragging:
        var mouse_delta: Vector2 = event.position - drag_start
        if mouse_delta.length() >= 34.0:
            _finish_drag(event.position)

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
    _swap(a, b)
    var matches := _find_matches()

    if matches.is_empty():
        _swap(a, b)
        message = "Pas de combinaison : essaie un autre mouvement."
        queue_redraw()
        return

    moves -= 1
    last_match_count = matches.size()
    var points := matches.size() * 10
    score += points

    busy = true
    message = "+%d points • attaque l'obstacle !" % points

    _spawn_match_bursts(matches)
    _clear_matches(matches)
    _collapse()
    refill_anim = 0.0
    hero_attack = 1.0

    _spawn_attack_effects(matches.size())
    if combat_active:
        _apply_snake_damage(matches.size())
    else:
        _apply_adventure_damage(matches.size())

    if moves <= 0 and not level_won:
        level_lost = true
        message = "Fin du niveau • score %d" % score

    busy = false
    queue_redraw()

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
    attack_flash = 1.0
    snake_alert = 1.0

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
        combat_active = true
        message = "LE SERPENT BLOQUE LA SORTIE ! Attaque-le."
        var combat_tween := create_tween()
        combat_tween.set_parallel(true)
        combat_tween.tween_property(self, "hero_x", PATH_POINTS[-1].x - 48.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        combat_tween.tween_property(self, "hero_y", PATH_POINTS[-1].y, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        return

    var target: Vector2 = PATH_POINTS[hero_progress]
    var hero_tween := create_tween()
    hero_tween.set_parallel(true)
    hero_tween.tween_property(self, "hero_x", target.x, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    hero_tween.tween_property(self, "hero_y", target.y, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    message = "ROCHER DÉTRUIT ! Le héros avance."

func _apply_snake_damage(match_count: int) -> void:
    if not combat_active or level_won:
        return
    var damage := 1
    if match_count >= 5:
        damage = 2
    if match_count >= 7:
        damage = 3
    snake_hp = max(0, snake_hp - damage)
    snake_hit_flash = 1.0
    snake_alert = 1.0
    score += damage * 25
    _spawn_attack_effects(match_count)

    if snake_hp > 0:
        message = "TOUCHE ! Le serpent perd %d PV." % damage
        return

    combat_active = false
    rescue_open = true
    level_won = true
    message = "SAUVETAGE RÉUSSI ! Le héros libère son allié."
    var rescue_tween := create_tween()
    rescue_tween.set_parallel(true)
    rescue_tween.tween_property(self, "hero_x", 560.0, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    rescue_tween.tween_property(self, "hero_y", 375.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _spawn_match_bursts(matches: Array[Vector2i]) -> void:
    for cell in matches:
        var p := Vector2(BOARD_X + cell.x * CELL + (CELL - 5) * 0.5, BOARD_Y + cell.y * CELL + (CELL - 5) * 0.5)
        for i in range(8):
            var angle := TAU * float(i) / 8.0
            effects.append({
                "p": p,
                "v": Vector2(cos(angle), sin(angle)) * (75.0 + randi() % 80),
                "t": 0.0,
                "life": 0.42 + float(randi() % 20) / 100.0,
                "target": p,
                "kind": 1
            })

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

func _clear_matches(matches: Array[Vector2i]) -> void:
    for cell in matches:
        board[cell.y][cell.x] = -1

func _collapse() -> void:
    for x in COLS:
        var values: Array = []
        for y in ROWS:
            if board[y][x] >= 0:
                values.append(board[y][x])

        while values.size() < ROWS:
            values.push_front(randi() % COLORS.size())

        for y in ROWS:
            board[y][x] = values[y]

extends Node2D

# Puzzle Heroes - Level 1
# Step 2: the Match-3 board now controls an adventure path.
# Matching tiles damages the next obstacle; destroying it moves the hero forward.

const COLS := 7
const ROWS := 8
const CELL := 78.0
const BOARD_X := 39.0
const BOARD_Y := 515.0
const COLORS := [
    Color("5fcf62"),
    Color("ef5350"),
    Color("ffc94d"),
    Color("5b9cf6"),
    Color("b56cf2")
]

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

const HERO_TEX := preload("res://assets/art/hero.svg")
const SNAKE_TEX := preload("res://assets/art/snake.svg")
const ROCK_TEX := preload("res://assets/art/rock.svg")
const CAPTIVE_TEX := preload("res://assets/art/captive.svg")
const SCENE_TEX := preload("res://assets/art/scene.svg")

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

    message = "Aligne 3 tuiles pour casser le rocher !"
    level_won = false
    level_lost = false
    busy = false

func _draw() -> void:
    # Full portrait background.
    draw_rect(Rect2(0, 0, 720, 1280), Color("efe7d6"))
    draw_rect(Rect2(0, 0, 720, 150), Color("2467b8"))
    draw_rect(Rect2(0, 150, 720, 12), Color("f5c84b"))

    # Header.
    draw_string(ThemeDB.fallback_font, Vector2(36, 62), "PUZZLE HEROES",
        HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(38, 112), "LEVEL 1 • LE CHEMIN",
        HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("dcecff"))
    draw_string(ThemeDB.fallback_font, Vector2(515, 65), "★ %d" % score,
        HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(515, 110), "COUPS %d" % moves,
        HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color.WHITE)

    _draw_adventure_area()

    # Match-3 board.
    draw_rect(Rect2(25, 500, 670, 670), Color("d3a23b"))
    draw_rect(Rect2(32, 507, 656, 656), Color("f7f0df"))

    for y in ROWS:
        for x in COLS:
            var rect := Rect2(
                BOARD_X + x * CELL,
                BOARD_Y + y * CELL,
                CELL - 4,
                CELL - 4
            )
            draw_style_box(_cell_box(), rect)
            var value: int = board[y][x]
            var center := rect.get_center()
            draw_circle(center, 27, COLORS[value])
            draw_circle(center + Vector2(-8, -9), 8, Color(1, 1, 1, 0.22))
            draw_circle(center, 29, Color(0.15, 0.15, 0.15, 0.12), false, 3.0)

    # Bottom status.
    draw_rect(Rect2(32, 1190, 656, 62), Color("3b3026"))
    draw_string(ThemeDB.fallback_font, Vector2(55, 1229), message,
        HORIZONTAL_ALIGNMENT_LEFT, 610, 21, Color.WHITE)

func _draw_adventure_area() -> void:
    # Professional original 2D scene artwork.
    draw_rect(Rect2(32, 190, 656, 292), Color("4b382d"))
    draw_texture_rect(SCENE_TEX, Rect2(42, 200, 636, 272), false)

    # Adventure path is drawn over the scene to keep gameplay readable.
    for i in range(PATH_POINTS.size() - 1):
        draw_line(PATH_POINTS[i], PATH_POINTS[i + 1], Color("d6b77b"), 30.0)
        draw_line(PATH_POINTS[i], PATH_POINTS[i + 1], Color("ead49b"), 22.0)

    # Progress markers.
    for i in PATH_POINTS.size():
        var marker_color := Color("f8e7b0") if i <= hero_progress else Color("6e7547")
        draw_circle(PATH_POINTS[i], 14, marker_color)
        draw_circle(PATH_POINTS[i], 5, Color("6b5437"))

    # Obstacles sit between path points.
    for i in range(OBSTACLE_MAX_HP.size()):
        var pos: Vector2 = (PATH_POINTS[i] + PATH_POINTS[i + 1]) * 0.5
        _draw_obstacle(pos, i)

    # Goal flag.
    var goal := PATH_POINTS[-1] + Vector2(0, -55)
    draw_line(goal, goal + Vector2(0, 58), Color("5a4632"), 5.0)
    draw_colored_polygon(PackedVector2Array([
        goal,
        goal + Vector2(62, 14),
        goal + Vector2(0, 31)
    ]), Color("f04b45"))
    draw_string(ThemeDB.fallback_font, goal + Vector2(-24, 85), "SORTIE",
        HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fff4d0"))

    # Snake enemy on the far side.
    _draw_snake(Vector2(snake_x, 285 + sin(hero_bounce * 0.7) * 4.0))

    # Captive appears at the exit and is rescued after the final obstacle.
    if level_won or rescue_open:
        draw_texture_rect(CAPTIVE_TEX, Rect2(Vector2(610, 325), Vector2(58, 79)), false)

    _draw_effects()

    # Hero follows the unlocked path.
    var hero_offset := Vector2(0, sin(hero_bounce) * 3.0)
    _draw_hero(Vector2(hero_x, hero_y) + hero_offset)

    # Combat HUD.
    if combat_active and not level_won:
        draw_rect(Rect2(455, 266, 192, 45), Color(0.18, 0.08, 0.06, 0.88))
        draw_string(ThemeDB.fallback_font, Vector2(470, 286), "SERPENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe6c0"))
        for h in range(snake_hp):
            draw_rect(Rect2(470 + h * 27, 296, 21, 8), Color("e84d48"))

    # Contextual objective.
    if level_won:
        draw_rect(Rect2(112, 208, 496, 56), Color(0.08, 0.28, 0.14, 0.92))
        draw_string(ThemeDB.fallback_font, Vector2(151, 246),
            "CHEMIN OUVERT ! NIVEAU RÉUSSI",
            HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    elif combat_active:
        draw_rect(Rect2(132, 208, 456, 56), Color(0.42, 0.16, 0.06, 0.94))
        draw_string(ThemeDB.fallback_font, Vector2(177, 246),
            "COMBAT ! ATTAQUE LE SERPENT",
            HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    elif level_lost:
        draw_rect(Rect2(125, 208, 470, 56), Color(0.35, 0.08, 0.07, 0.92))
        draw_string(ThemeDB.fallback_font, Vector2(180, 246),
            "LE HÉROS EST BLOQUÉ",
            HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
    else:
        var hp := obstacle_hp[obstacle_index] if obstacle_index < obstacle_hp.size() else 0
        draw_string(ThemeDB.fallback_font, Vector2(58, 223),
            "OBSTACLE %d/%d • FORCE %d" % [obstacle_index + 1, obstacle_hp.size(), hp],
            HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("30452b"))

func _draw_obstacle(pos: Vector2, index: int) -> void:
    if index >= obstacle_hp.size() or obstacle_hp[index] <= 0:
        draw_circle(pos + Vector2(-12, 5), 9, Color("bca675"))
        draw_circle(pos + Vector2(10, 7), 7, Color("a78e64"))
        draw_line(pos + Vector2(-18, -2), pos + Vector2(18, 7), Color("d8c79e"), 3)
        return

    var hp: int = obstacle_hp[index]
    var shake := sin(obstacle_flash * 28.0 + float(index)) * 5.0 if obstacle_flash > 0.0 else 0.0
    var p := pos + Vector2(shake, 0)
    draw_texture_rect(ROCK_TEX, Rect2(p - Vector2(43, 43), Vector2(86, 86)), false)
    for h in range(hp):
        draw_circle(p + Vector2((h - 1) * 16.0 - 8.0, -53), 6, Color("ef4f48"))

func _draw_hero(pos: Vector2) -> void:
    draw_texture_rect(HERO_TEX, Rect2(pos - Vector2(43, 58), Vector2(86, 108)), false)
    if attack_flash > 0.0:
        draw_line(pos + Vector2(25, -4), pos + Vector2(68, -24), Color(1, 0.88, 0.35, attack_flash), 8)
        draw_line(pos + Vector2(33, 4), pos + Vector2(76, -14), Color(1, 1, 1, attack_flash * 0.8), 3)

func _draw_snake(pos: Vector2) -> void:
    var shake := sin(hero_bounce * 12.0) * snake_alert * 5.0
    var flash_scale := 1.0 + snake_hit_flash * 0.12
    draw_texture_rect(SNAKE_TEX, Rect2(pos + Vector2(-58 * flash_scale + shake, -42 * flash_scale), Vector2(116 * flash_scale, 82 * flash_scale)), false)

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in 32:
        var a := TAU * float(i) / 32.0
        points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
    draw_colored_polygon(points, color)

func _cell_box() -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color("fffaf0")
    box.border_color = Color("d9c9a8")
    box.set_border_width_all(2)
    box.set_corner_radius_all(8)
    return box

func _input(event: InputEvent) -> void:
    if busy:
        return

    # Android / iOS touch.
    if event is InputEventScreenTouch:
        if event.pressed:
            drag_start = event.position
            drag_cell = _screen_to_cell(event.position)
            dragging = drag_cell.x >= 0
        elif dragging:
            _finish_drag(event.position)

    elif event is InputEventScreenDrag and dragging:
        var delta: Vector2 = event.position - drag_start
        if delta.length() >= 34.0:
            _finish_drag(event.position)

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

    _clear_matches(matches)
    _collapse()

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
            "target": target
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

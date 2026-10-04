extends Node2D

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

var board: Array = []
var score := 0
var moves := 25
var dragging := false
var drag_start := Vector2.ZERO
var drag_cell := Vector2i(-1, -1)
var busy := false
var message := "Match 3 pour ouvrir le chemin !"

func _ready() -> void:
    randomize()
    _new_level()
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
    message = "Match 3 pour ouvrir le chemin !"
    busy = false

func _draw() -> void:
    # Background
    draw_rect(Rect2(0, 0, 720, 1280), Color("efe7d6"))
    draw_rect(Rect2(0, 0, 720, 150), Color("2467b8"))
    draw_rect(Rect2(0, 150, 720, 12), Color("f5c84b"))

    # Header
    draw_string(ThemeDB.fallback_font, Vector2(36, 62), "PUZZLE HEROES", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(38, 112), "Level 1", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("dcecff"))
    draw_string(ThemeDB.fallback_font, Vector2(525, 65), "⭐ %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(525, 110), "Coups %d" % moves, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)

    # Adventure area
    draw_rect(Rect2(32, 190, 656, 292), Color("6f5a42"))
    draw_rect(Rect2(42, 200, 636, 272), Color("3e3429"))
    draw_circle(Vector2(360, 282), 76, Color("526b39"))
    draw_circle(Vector2(360, 282), 58, Color("7d9d49"))
    draw_string(ThemeDB.fallback_font, Vector2(92, 235), "🐍", HORIZONTAL_ALIGNMENT_LEFT, -1, 58, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(560, 300), "🧙", HORIZONTAL_ALIGNMENT_LEFT, -1, 58, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(236, 360), "🪨  🪨  🪨", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(190, 425), "MATCH 3  →  OUVRIR LE CHEMIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("ffe8a3"))

    # Board frame
    draw_rect(Rect2(25, 500, 670, 670), Color("d3a23b"))
    draw_rect(Rect2(32, 507, 656, 656), Color("f7f0df"))

    for y in ROWS:
        for x in COLS:
            var rect := Rect2(BOARD_X + x * CELL, BOARD_Y + y * CELL, CELL - 4, CELL - 4)
            draw_style_box(_cell_box(), rect)
            var value: int = board[y][x]
            var center := rect.get_center()
            draw_circle(center, 27, COLORS[value])
            draw_circle(center + Vector2(-8, -9), 8, Color(1,1,1,0.22))
            draw_circle(center, 29, Color(0.15,0.15,0.15,0.12), false, 3.0)

    # Bottom status
    draw_rect(Rect2(32, 1190, 656, 62), Color("3b3026"))
    draw_string(ThemeDB.fallback_font, Vector2(55, 1230), message, HORIZONTAL_ALIGNMENT_LEFT, 610, 22, Color.WHITE)

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
    if event is InputEventScreenTouch:
        if event.pressed:
            drag_start = event.position
            drag_cell = _screen_to_cell(event.position)
            dragging = drag_cell.x >= 0
        elif dragging:
            _finish_drag(event.position)
    elif event is InputEventScreenDrag and dragging:
        var delta := event.position - drag_start
        if delta.length() >= 34.0:
            _finish_drag(event.position)

func _finish_drag(pos: Vector2) -> void:
    dragging = false
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
        message = "Essaie une autre combinaison."
        queue_redraw()
        return
    moves -= 1
    score += matches.size() * 10
    busy = true
    message = "+%d points — le chemin s'ouvre !" % (matches.size() * 10)
    _clear_matches(matches)
    _collapse()
    if moves <= 0:
        message = "Fin du niveau — score %d" % score
    busy = false
    queue_redraw()

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

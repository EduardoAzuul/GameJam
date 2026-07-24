extends Node2D
signal check_finished(success: bool, tipo: String)
signal rebote_alcanzado 

const RIPPLE_SCENE: PackedScene = preload("res://Escenas/UserInterface/Ripple.tscn")
const ESCALA_OBJETIVO := Vector2(0.2, 0.2)

# --- Variables de Configuración ---
@export var rotation_speed_base: float = 300.0
@export var velocidad_rotacion_aro: float = 15.0  # grados por segundo, rotación lenta continua

# --- Variables de Estado ---
var rotation_speed: float = 300.0
var is_active: bool = false
var current_rotation: float = 0.0
var move_direction: int = 1
var zonas: Array = []
var limite_fallo_superior: float = 720.0
var limite_fallo_inferior: float = -10.0
var _uso_doble_oportunidad: bool = false
var _tween_rotacion_aro: Tween

# --- Referencias a los Nodos ---
@onready var aguja_pivot = $RuedaCompleta/AgujaPivot
@onready var zona_exito_nodo = $RuedaCompleta/ZonaExito
@onready var base_rueda = $RuedaCompleta/BaseRueda


func _ready():
	scale = Vector2.ZERO
	modulate.a = 0.0
	hide()
	set_process(false)
	_iniciar_rotacion_aro()


# --- ROTACIÓN CONTINUA DEL ARO EXTERIOR ---

func _iniciar_rotacion_aro() -> void:
	_tween_rotacion_aro = create_tween().set_loops()
	_tween_rotacion_aro.tween_property(
		base_rueda, "rotation_degrees",
		base_rueda.rotation_degrees + 360.0,
		360.0 / velocidad_rotacion_aro
	).as_relative().set_trans(Tween.TRANS_LINEAR)


# --- ENTRADA / SALIDA CON VIDA ---

func start_check():
	is_active = true
	_uso_doble_oportunidad = false
	current_rotation = 0.0
	move_direction = 1
	aguja_pivot.rotation_degrees = 0.0
	zonas.clear()

	limite_fallo_superior = 720.0
	limite_fallo_inferior = -10.0

	var cordura = EstadoManager.obtener_nivel("cordura")
	var factor_dificultad = 1.0 - (cordura / float(EstadoManager.NIVEL_MAXIMO))
	factor_dificultad = clamp(factor_dificultad, 0.0, 0.85)

	rotation_speed = rotation_speed_base + (factor_dificultad * 250.0)

	var normal_start = randf_range(60.0, 230.0)
	var normal_size = lerp(45.0, 25.0, factor_dificultad)
	zonas.append({
		"tipo": "normal",
		"start": normal_start,
		"end": normal_start + normal_size,
		"color": Color(1, 1, 1, 0.6)
	})

	var perfect_size = lerp(12.0, 6.0, factor_dificultad)
	var perfect_start = normal_start + normal_size
	zonas.append({
		"tipo": "perfect",
		"start": perfect_start,
		"end": perfect_start + perfect_size,
		"color": Color(0, 1, 0, 0.8)
	})

	if randf() < 0.3:
		var rebote_size = randf_range(8.0, 25.0)
		var rebote_start = randf_range(15.0, normal_start - rebote_size - 10.0)
		zonas.append({
			"tipo": "rebote",
			"start": rebote_start,
			"end": rebote_start + rebote_size,
			"color": Color(1, 0.8, 0, 0.8)
		})

	zona_exito_nodo.queue_redraw()
	show()

	var tween_entrada = create_tween().set_parallel(true)
	tween_entrada.tween_property(self, "scale", ESCALA_OBJETIVO, 0.3).set_trans(Tween.TRANS_BACK)
	tween_entrada.tween_property(self, "modulate:a", 1.0, 0.25)
	await tween_entrada.finished

	set_process(true)


func _salir_con_fade() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", ESCALA_OBJETIVO * 0.8, 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	hide()


func _process(delta):
	if not is_active: return

	current_rotation += rotation_speed * move_direction * delta
	aguja_pivot.rotation_degrees = current_rotation

	if current_rotation >= limite_fallo_superior or current_rotation <= limite_fallo_inferior:
		fail()


func _input(event):
	if not is_active: return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		check_input()


func check_input():
	var angle = fmod(current_rotation, 360.0)

	if angle < 0:
		angle += 360.0

	var zona_tocada = null

	for i in range(zonas.size() - 1, -1, -1):
		var z = zonas[i]
		if angle >= z["start"] and angle <= z["end"]:
			zona_tocada = z["tipo"]
			if zona_tocada == "rebote":
				zonas.remove_at(i)
				zona_exito_nodo.queue_redraw()
			break

	match zona_tocada:
		"perfect":
			print("¡PERFECTO!")
			_mostrar_ripple(Color(0.3, 1, 0.4), 100.0)
			end_minigame(Color.GREEN)
			check_finished.emit(true, "perfect")
		"normal":
			print("¡ÉXITO NORMAL!")
			_mostrar_ripple(Color.WHITE, 70.0)
			end_minigame(Color.WHITE)
			check_finished.emit(true, "normal")
		"rebote":
			print("¡REBOTE!")
			rebote_alcanzado.emit() 
			move_direction *= -1
			limite_fallo_inferior = current_rotation - 720.0
		_:
			fail()


# --- RIPPLE (aro que se expande) ---

func _mostrar_ripple(color: Color, radio_final: float) -> void:
	var ripple = RIPPLE_SCENE.instantiate()
	add_child(ripple)
	ripple.position = Vector2.ZERO
	ripple.configurar(color, radio_final, 0.5, 5.0)


func fail():
	if RelicManager.tiene("doble_oportunidad") and not _uso_doble_oportunidad:
		_uso_doble_oportunidad = true
		print("¡Doble Oportunidad activada! Intento adicional")
		_reintentar_con_penalizacion()
		return

	print("¡FALLO!")
	_shake_fallo()
	end_minigame(Color.RED)
	check_finished.emit(false, "fallo")


func _shake_fallo() -> void:
	var pos_original = position
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(self, "position", pos_original + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 0.04)
	tween.tween_property(self, "position", pos_original, 0.04)


func _reintentar_con_penalizacion() -> void:
	current_rotation = 0.0
	move_direction = 1
	aguja_pivot.rotation_degrees = 0.0
	rotation_speed *= 0.7
	limite_fallo_superior = 720.0
	limite_fallo_inferior = -10.0

	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = Color.ORANGE
	await get_tree().create_timer(0.3).timeout
	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = Color.WHITE

	set_process(true)


func end_minigame(aguja_color: Color):
	is_active = false
	set_process(false)
	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = aguja_color
	await get_tree().create_timer(0.4).timeout
	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = Color.WHITE
	await _salir_con_fade()


# Prueba con F
func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		if not is_active:
			start_check()

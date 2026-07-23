extends Node2D

signal check_finished(success: bool)

# --- Variables de Configuración ---
@export var rotation_speed: float = 300.0

# --- Variables de Estado ---
var is_active: bool = false
var current_rotation: float = 0.0
var move_direction: int = 1 
var zonas: Array = []
var limite_fallo_superior: float = 720.0 # ¡Aumentado a 2 vueltas completas!
var limite_fallo_inferior: float = -10.0

# --- Referencias a los Nodos ---
@onready var aguja_pivot = $RuedaCompleta/AgujaPivot
@onready var zona_exito_nodo = $RuedaCompleta/ZonaExito

func _ready():
	hide()
	set_process(false)

func start_check():
	is_active = true
	current_rotation = 0.0
	move_direction = 1 
	aguja_pivot.rotation_degrees = 0.0
	zonas.clear()
	
	# Reiniciamos los límites para dar 2 vueltas completas (720 grados)
	limite_fallo_superior = 720.0
	limite_fallo_inferior = -10.0
	
	# 1. Zona NORMAL
	var normal_start = randf_range(60.0, 230.0)
	var normal_size = 45.0
	zonas.append({
		"tipo": "normal",
		"start": normal_start,
		"end": normal_start + normal_size,
		"color": Color(1, 1, 1, 0.6) # Blanco semitransparente
	})
	
	# 2. Zona PERFECTA
	var perfect_size = 12.0
	var perfect_start = normal_start + normal_size 
	zonas.append({
		"tipo": "perfect",
		"start": perfect_start,
		"end": perfect_start + perfect_size,
		"color": Color(0, 1, 0, 0.8) # Verde brillante
	})
	
	# 3. Zona REBOTE (Variado y dinámico)
	if randf() < 0.3:
		# Generamos un tamaño aleatorio entre 8 y 25 grados para la barra de rebote
		var rebote_size = randf_range(8.0, 25.0) 
		# Aseguramos que aparezca antes de la normal y no se encimen
		var rebote_start = randf_range(15.0, normal_start - rebote_size - 10.0) 
		
		zonas.append({
			"tipo": "rebote",
			"start": rebote_start,
			"end": rebote_start + rebote_size,
			"color": Color(1, 0.8, 0, 0.8) # Amarillo
		})
	
	zona_exito_nodo.queue_redraw()
	show()
	set_process(true)

func _process(delta):
	if not is_active: return
	
	current_rotation += rotation_speed * move_direction * delta
	aguja_pivot.rotation_degrees = current_rotation
	
	# Revisamos si llegó a los 720 grados (2 vueltas) o rebasó su límite inferior
	if current_rotation >= limite_fallo_superior or current_rotation <= limite_fallo_inferior:
		fail()

func _input(event):
	if not is_active: return
	
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		check_input()

func check_input():
	# fmod se encarga de convertir 720, 500 o 380 grados siempre a su equivalente de 0 a 360
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
			emit_signal("check_finished", true) 
			end_minigame(Color.GREEN)
		"normal":
			print("¡ÉXITO NORMAL!")
			emit_signal("check_finished", true)
			end_minigame(Color.WHITE)
		"rebote":
			print("¡REBOTE!")
			move_direction *= -1 
			# Le damos también el equivalente a 2 vueltas completas de distancia hacia atrás
			limite_fallo_inferior = current_rotation - 720.0
		_: 
			fail()

func fail():
	print("¡FALLO!")
	emit_signal("check_finished", false)
	end_minigame(Color.RED)

func end_minigame(aguja_color: Color):
	is_active = false
	set_process(false)
	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = aguja_color
	await get_tree().create_timer(0.4).timeout
	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = Color.WHITE
	hide()

# Prueba con F
func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		if not is_active:
			start_check()

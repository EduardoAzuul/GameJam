extends Node2D

# Señales para comunicar el resultado al gestor del combate
signal check_finished(success: bool)

# --- Configuración ---
@export var rotation_speed: float = 300.0 # Grados por segundo
@export var zone_size_degrees: float = 40.0 # Tamaño de la zona de éxito
@export var great_success_multiplier: float = 0.2 # % de la zona que es "Excelente"

# --- Variables de Estado ---
var is_active: bool = false
var target_angle_start: float = 0.0
var target_angle_end: float = 0.0
var current_rotation: float = 0.0

# --- Referencias ---
@onready var aguja_pivot = $RuedaCompleta/AgujaPivot
@onready var zona_exito_nodo = $RuedaCompleta/ZonaExito

func _ready():
	# Por defecto, la escena está oculta y desactivada
	hide()
	set_process(false)

# --- Iniciar el Minijuego ---
func start_check():
	# 1. Resetear variables
	is_active = true
	current_rotation = 0.0
	aguja_pivot.rotation_degrees = 0.0
	
	# 2. Decidir aleatoriamente dónde empieza la zona de éxito
	# Evitamos los primeros 60 grados para dar tiempo a reaccionar
	target_angle_start = randf_range(60.0, 360.0 - zone_size_degrees - 20.0)
	target_angle_end = target_angle_start + zone_size_degrees
	
	# 3. Pedir al nodo de zona que se dibuje (ver punto 3 abajo)
	zona_exito_nodo.queue_redraw() 
	
	# 4. Mostrar y activar actualización
	show()
	set_process(true)
	print("Prueba de habilidad iniciada. Zona: ", target_angle_start, " - ", target_angle_end)

# --- Bucle de Juego (Rotación) ---
func _process(delta):
	if not is_active: return
	
	# Avanzar la aguja
	current_rotation += rotation_speed * delta
	aguja_pivot.rotation_degrees = current_rotation
	
	# Si la aguja da una vuelta completa y el jugador no pulsó -> Fallo
	if current_rotation >= 360.0:
		fail()

# --- Entrada del Jugador ---
func _input(event):
	if not is_active: return
	
	# Si presiona Espacio (o la acción configurada)
	if event.is_action_pressed("ui_accept"): # "ui_accept" suele ser Espacio/Enter
		get_viewport().set_input_as_handled() # Evita que otros sistemas detecten el Espacio
		check_input()

# --- Lógica de Verificación ---
func check_input():
	# Normalizar la rotación actual a 0-360 (por seguridad)
	var final_angle = fmod(current_rotation, 360.0)
	
	# Comprobar si está dentro del rango
	if final_angle >= target_angle_start and final_angle <= target_angle_end:
		success()
	else:
		fail()

# --- Resultados ---
func success():
	is_active = false
	set_process(false)
	print("¡ÉXITO!")
	# Aquí conectarías con VidaManager para curar o bloquear daño
	emit_signal("check_finished", true)
	
	# Pequeña pausa visual antes de desaparecer (opcional)
	await get_tree().create_timer(0.3).timeout
	hide()

func fail():
	is_active = false
	set_process(false)
	print("¡FALLO!")
	# Importante: según tu diseño, esto DEBE quitar vida
	# VidaManager.take_damage(5) # Ejemplo
	emit_signal("check_finished", false)
	
	# Efecto visual de fallo (ej. aguja roja) y pausa
	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = Color.RED
	await get_tree().create_timer(0.5).timeout
	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = Color.WHITE # Reset color
	hide()

func _unhandled_input(event):
	# Detecta si presionas la tecla F directamente (sin configurar el Input Map)
	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		# Solo lo inicia si no está activo ya
		if not is_active:
			start_check()

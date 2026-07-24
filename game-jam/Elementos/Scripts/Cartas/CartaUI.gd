# CartaUI.gd
extends Control

signal carta_jugada(carta_ui: Control)
signal carta_descartada_sin_jugar(carta_ui: Control)
signal seleccion_descarte_cambiada(carta_ui: Control, seleccionada: bool)

@export var datos: Carta
@export var interactiva: bool = true

@onready var label_nombre: Label = $Nombre
@onready var label_costo: Label = $Costo
@onready var label_desc: Label = $Descripcion
@onready var icono: TextureRect = $Icono
@onready var marco_skill_check: Control = get_node_or_null("MarcoSkillCheck")

var _arrastrando: bool = false
var _offset_arrastre: Vector2 = Vector2.ZERO
var _hovering: bool = false
var _elevada: bool = false

var modo_descarte: bool = false
var seleccionada_para_descarte: bool = false

var posicion_mano: Vector2 = Vector2.ZERO
var rotacion_mano: float = 0.0

var _mouse_pos_anterior: Vector2 = Vector2.ZERO
var _tween_marco: Tween

const ESCALA_NORMAL := Vector2.ONE
const ESCALA_HOVER := Vector2(1.15, 1.15)
const ESCALA_ARRASTRE := Vector2(1.25, 1.25)

const ELEVACION_HOVER := -22.0
const INCLINACION_MAX_GRADOS := 14.0
const SUAVIZADO_INCLINACION := 10.0

var _velocidad_suavizada: float = 0.0
const SUAVIZADO_VELOCIDAD := 12.0
const SENSIBILIDAD_INCLINACION := 0.05

func _ready() -> void:
	actualizar_visual()
	pivot_offset = size / 2

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	VidaManager.vida_cambiada.connect(_on_vida_cambiada)
	_on_vida_cambiada(VidaManager.vida_actual, VidaManager.vida_maxima)

	_actualizar_marco_skill_check()


func actualizar_visual() -> void:
	if datos == null:
		return
	label_nombre.text = datos.nombre
	label_costo.text = str(datos.costo_vida)
	label_desc.text = datos.descripcion
	if icono:
		icono.texture = datos.icono
	_actualizar_marco_skill_check()


func _on_vida_cambiada(_vida_actual: int, _vida_maxima: int) -> void:
	if datos == null or modo_descarte:
		return
	modulate = Color.WHITE if VidaManager.puede_pagar_costo(datos.costo_vida) else Color(1, 0.4, 0.4)


func resetear_modo_descarte() -> void:
	modo_descarte = false
	seleccionada_para_descarte = false
	_on_vida_cambiada(VidaManager.vida_actual, VidaManager.vida_maxima)


# --- MARCA DE SKILL CHECK ---

func _actualizar_marco_skill_check() -> void:
	if marco_skill_check == null or datos == null:
		return
	marco_skill_check.visible = datos.requiere_skill_check
	if datos.requiere_skill_check:
		_pulso_marco_skill_check()


func _pulso_marco_skill_check() -> void:
	if _tween_marco:
		_tween_marco.kill()
	marco_skill_check.modulate.a = 0.5
	_tween_marco = create_tween().set_loops()
	_tween_marco.tween_property(marco_skill_check, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	_tween_marco.tween_property(marco_skill_check, "modulate:a", 0.5, 0.7).set_trans(Tween.TRANS_SINE)


# --- POSICIONAMIENTO EN LA MANO (llamado desde ManoUI) ---

func mover_a_posicion_mano(pos: Vector2, rot: float) -> void:
	posicion_mano = pos
	rotacion_mano = rot
	if _arrastrando:
		return

	var destino = pos
	if _elevada:
		destino.y += ELEVACION_HOVER

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", destino, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation", rot, 0.2).set_trans(Tween.TRANS_BACK)


# --- HOVER (con elevación) ---

func _on_mouse_entered() -> void:
	_hovering = true
	if _arrastrando or modo_descarte:
		return
	_elevada = true
	z_index = 5

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", ESCALA_HOVER, 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position", posicion_mano + Vector2(0, ELEVACION_HOVER), 0.15).set_trans(Tween.TRANS_BACK)


func _on_mouse_exited() -> void:
	_hovering = false
	if _arrastrando or modo_descarte:
		return
	_elevada = false
	z_index = 0

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", ESCALA_NORMAL, 0.12)
	tween.tween_property(self, "position", posicion_mano, 0.15).set_trans(Tween.TRANS_BACK)


# --- DRAG & DROP ---

func _gui_input(event: InputEvent) -> void:
	if modo_descarte:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			seleccionada_para_descarte = !seleccionada_para_descarte
			modulate = Color(1, 0.3, 0.3) if seleccionada_para_descarte else Color.WHITE
			seleccion_descarte_cambiada.emit(self, seleccionada_para_descarte)
			get_viewport().set_input_as_handled()
		return
	if not interactiva:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_iniciar_arrastre()
			get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not interactiva:
		return
	if not _arrastrando:
		return

	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - _offset_arrastre

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_soltar_carta()


func _process(delta: float) -> void:
	if not _arrastrando:
		return

	var mouse_actual = get_global_mouse_position()
	var velocidad_x_cruda = (mouse_actual.x - _mouse_pos_anterior.x) / max(delta, 0.001)
	_mouse_pos_anterior = mouse_actual

	# Suavizamos la velocidad en sí, no solo el ángulo final
	_velocidad_suavizada = lerp(_velocidad_suavizada, velocidad_x_cruda, delta * SUAVIZADO_VELOCIDAD)

	var inclinacion_objetivo = clamp(_velocidad_suavizada * SENSIBILIDAD_INCLINACION, -INCLINACION_MAX_GRADOS, INCLINACION_MAX_GRADOS)
	rotation_degrees = lerp(rotation_degrees, inclinacion_objetivo, delta * SUAVIZADO_INCLINACION)


func _iniciar_arrastre() -> void:
	if datos == null or not VidaManager.puede_pagar_costo(datos.costo_vida):
		_shake_rechazo()
		return

	_arrastrando = true
	_elevada = false
	_offset_arrastre = get_global_mouse_position() - global_position
	_mouse_pos_anterior = get_global_mouse_position()

	z_index = 10
	set_process(true)
	create_tween().tween_property(self, "scale", ESCALA_ARRASTRE, 0.1)


func _shake_rechazo() -> void:
	var pos_original = position
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(self, "position", pos_original + Vector2(randf_range(-6, 6), 0), 0.045)
	tween.tween_property(self, "position", pos_original, 0.045)

	var tween_costo = create_tween()
	tween_costo.tween_property(label_costo, "scale", Vector2(1.5, 1.5), 0.08).set_trans(Tween.TRANS_BACK)
	tween_costo.tween_property(label_costo, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)

	var color_original = label_costo.modulate
	label_costo.modulate = Color(1, 0.2, 0.2)
	var tween_color = create_tween()
	tween_color.tween_property(label_costo, "modulate", color_original, 0.3)


func _soltar_carta() -> void:
	if not _arrastrando:
		return
	_arrastrando = false
	set_process(false)
	rotation = 0.0

	var objetivo = _buscar_enemigo_bajo_el_mouse()

	if objetivo != null:
		var exito = await CartaEjecutor.jugar_carta(datos, objetivo)
		if exito:
			carta_jugada.emit(self)
			ManoManager.mover_a_descarte(datos)
			_salida_al_jugarse(objetivo)
			return

	z_index = 0
	_elevada = _hovering
	var destino = posicion_mano + (Vector2(0, ELEVACION_HOVER) if _elevada else Vector2.ZERO)
	var escala_final = ESCALA_HOVER if _hovering else ESCALA_NORMAL

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", escala_final, 0.15)
	tween.tween_property(self, "position", destino, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation", rotacion_mano, 0.2).set_trans(Tween.TRANS_BACK)


func _salida_al_jugarse(objetivo: Node) -> void:
	interactiva = false
	if marco_skill_check:
		marco_skill_check.visible = false

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", objetivo.global_position, 0.18).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.18).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)


func _buscar_enemigo_bajo_el_mouse() -> Node:
	var espacio = get_viewport().world_2d.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = get_global_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var resultados = espacio.intersect_point(query)
	for resultado in resultados:
		if resultado.collider is Enemigo:
			return resultado.collider

	return null

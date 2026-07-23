# CartaUI.gd
extends Control

signal carta_jugada(carta_ui: Control)
signal carta_descartada_sin_jugar(carta_ui: Control)

@export var datos: Carta

@onready var label_nombre: Label = $Nombre
@onready var label_costo: Label = $Costo
@onready var label_desc: Label = $Descripcion
@onready var icono: TextureRect = $Icono

var _arrastrando: bool = false
var _offset_arrastre: Vector2 = Vector2.ZERO
var _hovering: bool = false

var posicion_mano: Vector2 = Vector2.ZERO
var rotacion_mano: float = 0.0

const ESCALA_NORMAL := Vector2.ONE
const ESCALA_HOVER := Vector2(1.15, 1.15)
const ESCALA_ARRASTRE := Vector2(1.25, 1.25)


func _ready() -> void:
	actualizar_visual()
	pivot_offset = size / 2  # para que escale/rote desde el centro, no la esquina

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	VidaManager.vida_cambiada.connect(_on_vida_cambiada)
	_on_vida_cambiada(VidaManager.vida_actual, VidaManager.vida_maxima)


func actualizar_visual() -> void:
	if datos == null:
		return
	label_nombre.text = datos.nombre
	label_costo.text = str(datos.costo_vida)
	label_desc.text = datos.descripcion
	if icono:
		icono.texture = datos.icono


func _on_vida_cambiada(_vida_actual: int, _vida_maxima: int) -> void:
	if datos == null:
		return
	modulate = Color.WHITE if VidaManager.puede_pagar_costo(datos.costo_vida) else Color(1, 0.4, 0.4)


# --- POSICIONAMIENTO EN LA MANO (llamado desde ManoUI) ---

func mover_a_posicion_mano(pos: Vector2, rot: float) -> void:
	posicion_mano = pos
	rotacion_mano = rot
	if _arrastrando:
		return  # no la muevas si el jugador la tiene agarrada

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position", pos, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation", rot, 0.2).set_trans(Tween.TRANS_BACK)


# --- HOVER ---

func _on_mouse_entered() -> void:
	_hovering = true
	if _arrastrando:
		return
	z_index = 5
	create_tween().tween_property(self, "scale", ESCALA_HOVER, 0.1)


func _on_mouse_exited() -> void:
	_hovering = false
	if _arrastrando:
		return
	z_index = 0
	create_tween().tween_property(self, "scale", ESCALA_NORMAL, 0.1)


# --- DRAG & DROP ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_iniciar_arrastre()
			get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not _arrastrando:
		return

	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() - _offset_arrastre

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_soltar_carta()


func _iniciar_arrastre() -> void:
	if datos == null or not VidaManager.puede_pagar_costo(datos.costo_vida):
		return

	_arrastrando = true
	_offset_arrastre = get_global_mouse_position() - global_position

	z_index = 10
	rotation = 0.0  # se endereza mientras se arrastra, más fácil de apuntar
	create_tween().tween_property(self, "scale", ESCALA_ARRASTRE, 0.1)


func _soltar_carta() -> void:
	if not _arrastrando:
		return
	_arrastrando = false

	var objetivo = _buscar_enemigo_bajo_el_mouse()

	if objetivo != null:
		var exito = CartaEjecutor.jugar_carta(datos, objetivo)
		if exito:
			carta_jugada.emit(self)
			ManoManager.mover_a_descarte(datos)
			queue_free()
			return

	# vuelve a su lugar en el abanico
	z_index = 0
	var escala_final = ESCALA_HOVER if _hovering else ESCALA_NORMAL
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", escala_final, 0.15)
	tween.tween_property(self, "position", posicion_mano, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "rotation", rotacion_mano, 0.2).set_trans(Tween.TRANS_BACK)


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

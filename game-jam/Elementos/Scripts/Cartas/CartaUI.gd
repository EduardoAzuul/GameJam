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

var _padre_original: Node = null
var _indice_original: int = 0


func _ready() -> void:
	actualizar_visual()
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


# --- DRAG & DROP ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print("CartaUI _gui_input recibido: ", event.button_index, " pressed=", event.pressed)
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
			print("CartaUI _input: soltando carta")
			_soltar_carta()


func _iniciar_arrastre() -> void:
	print("_iniciar_arrastre llamado. datos=", datos, " puede_pagar=", VidaManager.puede_pagar_costo(datos.costo_vida) if datos else "sin datos")
	if datos == null or not VidaManager.puede_pagar_costo(datos.costo_vida):
		print("_iniciar_arrastre: CANCELADO (sin datos o no se puede pagar)")
		return

	_arrastrando = true
	print("_iniciar_arrastre: arrastre INICIADO correctamente")
	if datos == null or not VidaManager.puede_pagar_costo(datos.costo_vida):
		return

	_arrastrando = true
	_offset_arrastre = get_global_mouse_position() - global_position

	_padre_original = get_parent()
	_indice_original = get_index()

	var arbol = get_tree()
	var pos_guardada = global_position

	_padre_original.remove_child(self)
	arbol.root.add_child(self)
	global_position = pos_guardada

	z_index = 10


func _soltar_carta() -> void:
	if not _arrastrando:
		return
	_arrastrando = false
	z_index = 0

	var objetivo = _buscar_enemigo_bajo_el_mouse()

	if objetivo != null:
		var exito = CartaEjecutor.jugar_carta(datos, objetivo)
		if exito:
			carta_jugada.emit(self)
			ManoManager.mover_a_descarte(datos)
			queue_free()
			return

	_volver_al_contenedor()


func _volver_al_contenedor() -> void:
	if get_parent() != null:
		get_parent().remove_child(self)
	_padre_original.add_child(self)
	_padre_original.move_child(self, _indice_original)


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

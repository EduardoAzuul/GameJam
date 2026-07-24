# ManoUI.gd
extends Control

const CARTA_UI_SCENE: PackedScene = preload("res://Elementos/CartaUI.tscn")

@export var espaciado_horizontal: float = 90.0
@export var angulo_por_carta: float = 6.0    # grados de rotación entre cartas
@export var curva_vertical: float = 12.0     # cuánto "bajan" las cartas alejadas del centro

@onready var contenedor: Control = $ContenedorCartas

var _cartas_visuales: Dictionary = {}
var _cantidad_a_descartar: int = 0
var _seleccionadas: Array[Control] = []


func _ready() -> void:
	ManoManager.mano_actualizada.connect(_on_mano_actualizada)
	ManoManager.solicitar_seleccion_descarte.connect(_entrar_modo_descarte)
	_on_mano_actualizada(ManoManager.mano)


func _on_mano_actualizada(mano: Array[Carta]) -> void:
	# 1. Quitar visuales de cartas que ya no están en la mano
	for carta in _cartas_visuales.keys():
		if carta not in mano:
			var nodo = _cartas_visuales[carta]
			if is_instance_valid(nodo):
				nodo.queue_free()
			_cartas_visuales.erase(carta)

	# 2. Agregar visuales para cartas nuevas que todavía no tienen nodo
	for carta in mano:
		if not _cartas_visuales.has(carta):
			_instanciar_carta(carta)

	# 3. Reacomodar todas en abanico
	_reposicionar_mano(mano)


func _instanciar_carta(carta: Carta) -> void:
	var nueva_carta_ui = CARTA_UI_SCENE.instantiate()
	contenedor.add_child(nueva_carta_ui)
	nueva_carta_ui.datos = carta
	nueva_carta_ui.actualizar_visual()
	_cartas_visuales[carta] = nueva_carta_ui
	nueva_carta_ui.carta_jugada.connect(_on_carta_jugada)


func _on_carta_jugada(carta_ui: Control) -> void:
	for carta in _cartas_visuales.keys():
		if _cartas_visuales[carta] == carta_ui:
			_cartas_visuales.erase(carta)
			break


func _entrar_modo_descarte(cantidad: int) -> void:
	_cantidad_a_descartar = cantidad
	_seleccionadas.clear()
	for carta_ui in _cartas_visuales.values():
		carta_ui.modo_descarte = true
		carta_ui.interactiva = false
		carta_ui.seleccion_descarte_cambiada.connect(_on_seleccion_cambiada)


func _on_seleccion_cambiada(carta_ui: Control, seleccionada: bool) -> void:
	if seleccionada:
		if not _seleccionadas.has(carta_ui):
			_seleccionadas.append(carta_ui)
	else:
		_seleccionadas.erase(carta_ui)
	if _seleccionadas.size() >= _cantidad_a_descartar:
		_confirmar_descarte()


func _confirmar_descarte() -> void:
	var cartas: Array[Carta] = []
	for carta_ui in _seleccionadas:
		if carta_ui.datos != null:
			cartas.append(carta_ui.datos)
	for carta_ui in _cartas_visuales.values():
		if is_instance_valid(carta_ui):
			carta_ui.resetear_modo_descarte()
			if carta_ui.seleccion_descarte_cambiada.is_connected(_on_seleccion_cambiada):
				carta_ui.seleccion_descarte_cambiada.disconnect(_on_seleccion_cambiada)
	_seleccionadas.clear()
	ManoManager.confirmar_descarte_elegido(cartas)


func _reposicionar_mano(mano: Array[Carta]) -> void:
	var n = mano.size()
	if n == 0:
		return

	var centro = (n - 1) / 2.0
	var centro_x = contenedor.size.x / 2.0
	var base_y = contenedor.size.y / 2.0

	for i in range(n):
		var carta = mano[i]
		if not _cartas_visuales.has(carta):
			continue
		var carta_ui = _cartas_visuales[carta]

		var offset = i - centro
		var pos_x = centro_x + offset * espaciado_horizontal
		var pos_y = base_y + abs(offset) * curva_vertical
		var rot_deg = offset * angulo_por_carta

		carta_ui.mover_a_posicion_mano(Vector2(pos_x, pos_y), deg_to_rad(rot_deg))

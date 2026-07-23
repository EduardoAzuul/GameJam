# ManoUI.gd
extends Control

@export var carta_ui_scene: PackedScene  # arrastrá CartaUI.tscn acá en el Inspector

@onready var contenedor: HBoxContainer = $ContenedorCartas

var _cartas_visuales: Dictionary = {}  # Carta (Resource) -> CartaUI (nodo)


func _ready() -> void:
	ManoManager.mano_actualizada.connect(_on_mano_actualizada)
	_on_mano_actualizada(ManoManager.mano)


func _on_mano_actualizada(mano: Array[Carta]) -> void:
	# 1. Quitar visuales de cartas que ya no están en la mano (se jugaron o descartaron)
	for carta in _cartas_visuales.keys():
		if carta not in mano:
			var nodo = _cartas_visuales[carta]
			if is_instance_valid(nodo):
				nodo.queue_free()
			_cartas_visuales.erase(carta)

	# 2. Agregar visuales para cartas nuevas (robadas) que todavía no tienen nodo
	for carta in mano:
		if not _cartas_visuales.has(carta):
			_instanciar_carta(carta)


func _instanciar_carta(carta: Carta) -> void:
	var nueva_carta_ui = carta_ui_scene.instantiate()
	nueva_carta_ui.datos = carta
	contenedor.add_child(nueva_carta_ui)
	_cartas_visuales[carta] = nueva_carta_ui

	# conectamos la señal para saber si esta carta específica se jugó
	nueva_carta_ui.carta_jugada.connect(_on_carta_jugada)


func _on_carta_jugada(carta_ui: Control) -> void:
	# la CartaUI ya se destruye sola (queue_free en su propio script),
	# pero la sacamos del diccionario para no tener referencias colgantes
	for carta in _cartas_visuales.keys():
		if _cartas_visuales[carta] == carta_ui:
			_cartas_visuales.erase(carta)
			break

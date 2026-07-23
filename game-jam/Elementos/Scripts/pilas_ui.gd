# PilasUI.gd
extends Control

@onready var label_robo: Label = $LabelRobo
@onready var label_descarte: Label = $LabelDescarte


func _ready() -> void:
	ManoManager.pila_robo_actualizada.connect(_on_robo_actualizada)
	ManoManager.pila_descarte_actualizada.connect(_on_descarte_actualizada)

	_on_robo_actualizada(ManoManager.pila_robo.size())
	_on_descarte_actualizada(ManoManager.pila_descarte.size())


func _on_robo_actualizada(cantidad: int) -> void:
	label_robo.text = "Mazo: %d" % cantidad


func _on_descarte_actualizada(cantidad: int) -> void:
	label_descarte.text = "Descarte: %d" % cantidad

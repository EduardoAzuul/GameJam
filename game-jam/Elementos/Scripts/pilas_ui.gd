# PilaUI.gd
extends Control

enum TipoPila { ROBO, DESCARTE }

@export var tipo_pila: TipoPila = TipoPila.ROBO

@onready var label_cantidad: Label = $LabelCantidad
@onready var icono: TextureRect = $Icono


func _ready() -> void:
	if tipo_pila == TipoPila.ROBO:
		ManoManager.pila_robo_actualizada.connect(_actualizar)
		_actualizar(ManoManager.pila_robo.size())
	else:
		ManoManager.pila_descarte_actualizada.connect(_actualizar)
		_actualizar(ManoManager.pila_descarte.size())


func _actualizar(cantidad: int) -> void:
	label_cantidad.text = str(cantidad)
	_pulso()


func _pulso() -> void:
	scale = Vector2(1.3, 1.3)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

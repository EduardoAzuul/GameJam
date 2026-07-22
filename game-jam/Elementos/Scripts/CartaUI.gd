# CartaUI.gd
extends Control

@export var datos: Carta

@onready var label_nombre: Label = $Nombre
@onready var label_costo: Label = $Costo
@onready var label_desc: Label = $Descripcion
@onready var icono: TextureRect = $Icono

func _ready() -> void:
	actualizar_visual()
	VidaManager.vida_cambiada.connect(_on_vida_cambiada)
	_on_vida_cambiada(VidaManager.vida_actual, VidaManager.vida_maxima)

func actualizar_visual() -> void:
	label_nombre.text = datos.nombre
	label_costo.text = str(datos.costo_vida)
	label_desc.text = datos.descripcion
	icono.texture = datos.icono


func _on_vida_cambiada(_vida_actual: int, _vida_maxima: int) -> void:
	modulate = Color.WHITE if VidaManager.puede_pagar_costo(datos.costo_vida) else Color(1, 0.4, 0.4)

func _on_jugada(enemigo_objetivo: Node) -> void:
	var exito = CartaEjecutor.jugar_carta(datos, enemigo_objetivo)
	if exito:
		ManoManager.mover_a_descarte(self)

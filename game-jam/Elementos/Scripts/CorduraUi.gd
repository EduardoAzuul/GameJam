# CorduraUI.gd
extends Control

@onready var barra: TextureProgressBar = $BarraCordura
@onready var label: Label = $LabelCordura


func _ready() -> void:
	EstadoManager.estado_cambiado.connect(_on_estado_cambiado)
	EstadoManager.panico_activado.connect(_on_panico_activado)
	EstadoManager.panico_desactivado.connect(_on_panico_desactivado)

	_actualizar(EstadoManager.obtener_nivel("cordura"))


func _on_estado_cambiado(nombre: String, nivel: int, _max: int) -> void:
	if nombre == "cordura":
		_actualizar(nivel)


func _actualizar(nivel: int) -> void:
	barra.max_value = EstadoManager.NIVEL_MAXIMO
	barra.value = nivel
	if label:
		label.text = "%d/%d" % [nivel, EstadoManager.NIVEL_MAXIMO]


func _on_panico_activado() -> void:
	modulate = Color(1, 0.3, 0.3)


func _on_panico_desactivado() -> void:
	modulate = Color.WHITE

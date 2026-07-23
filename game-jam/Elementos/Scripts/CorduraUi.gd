# CorduraUI.gd
extends Control

@onready var barra: ProgressBar = $BarraCordura
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
	label.text = "Cordura: %d/%d" % [nivel, EstadoManager.NIVEL_MAXIMO]


func _on_panico_activado() -> void:
	modulate = Color(1, 0.3, 0.3)
	# acá enganchás efectos visuales de pantalla completa si querés (shader, vignette rojo, etc.)


func _on_panico_desactivado() -> void:
	modulate = Color.WHITE

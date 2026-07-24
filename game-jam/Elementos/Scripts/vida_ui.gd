# VidaUI.gd
extends Control

@onready var barra_vida: TextureProgressBar = $BarraVida
@onready var label_vida: Label = $LabelVida
@onready var label_escudo: Label = $LabelEscudo


func _ready() -> void:
	VidaManager.vida_cambiada.connect(_on_vida_cambiada)
	VidaManager.escudo_cambiado.connect(_on_escudo_cambiado)
	VidaManager.dano_recibido.connect(_on_dano_recibido)
	VidaManager.curacion_recibida.connect(_on_curacion_recibida)

	# estado inicial
	_on_vida_cambiada(VidaManager.vida_actual, VidaManager.vida_maxima)
	_on_escudo_cambiado(VidaManager.escudo)


func _on_vida_cambiada(vida_actual: int, vida_maxima: int) -> void:
	barra_vida.max_value = vida_maxima
	barra_vida.value = vida_actual
	label_vida.text = "%d / %d" % [vida_actual, vida_maxima]


func _on_escudo_cambiado(escudo_actual: int) -> void:
	label_escudo.visible = escudo_actual > 0
	label_escudo.text = "🛡 %d" % escudo_actual


func _on_dano_recibido(_cantidad: int, _fuente: String) -> void:
	_flash(Color(1, 0.3, 0.3))  # rojo


func _on_curacion_recibida(_cantidad: int) -> void:
	_flash(Color(0.3, 1, 0.3))  # verde


func _flash(color: Color) -> void:
	var tween = create_tween()
	modulate = color
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

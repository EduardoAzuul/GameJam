# Ripple.gd
extends Node2D

var _radio: float = 5.0
var _alpha: float = 1.0
var _color: Color = Color.WHITE
var _grosor: float = 4.0


func configurar(color: Color, radio_final: float = 80.0, duracion: float = 0.5, grosor: float = 4.0) -> void:
	_color = color
	_grosor = grosor

	var tween = create_tween().set_parallel(true)
	tween.tween_method(_set_radio, 5.0, radio_final, duracion).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_alpha, 1.0, 0.0, duracion).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(queue_free)


func _set_radio(valor: float) -> void:
	_radio = valor
	queue_redraw()


func _set_alpha(valor: float) -> void:
	_alpha = valor
	queue_redraw()


func _draw() -> void:
	var color_con_alpha = Color(_color.r, _color.g, _color.b, _alpha)
	draw_arc(Vector2.ZERO, _radio, 0, TAU, 48, color_con_alpha, _grosor, true)

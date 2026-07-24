# inventario_ui.gd
extends CanvasLayer

const CARTA_SCENE := preload("res://Elementos/CartaUI.tscn")
const ANCHO_PANEL := 430.0
const DURACION_SLIDE := 0.3

var _abierto := false

@onready var panel    : PanelContainer = $Raiz/PanelDeslizable
@onready var grid     : GridContainer  = $Raiz/PanelDeslizable/MarginContainer/VBoxContainer/ScrollContainer/GridCartas
@onready var contador : Label          = $Raiz/PanelDeslizable/MarginContainer/VBoxContainer/ContadorLabel
@onready var scroll   : ScrollContainer = $Raiz/PanelDeslizable/MarginContainer/VBoxContainer/ScrollContainer


func _ready() -> void:
	panel.position.x = -ANCHO_PANEL


func _on_boton_inventario_pressed() -> void:
	if _abierto:
		_cerrar()
	else:
		_abrir()


func _on_btn_cerrar_pressed() -> void:
	_cerrar()


func _abrir() -> void:
	_abierto = true
	_poblar_cartas()
	var tween := create_tween()
	tween.tween_property(panel, "position:x", 0.0, DURACION_SLIDE)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _cerrar() -> void:
	_abierto = false
	var tween := create_tween()
	tween.tween_property(panel, "position:x", -ANCHO_PANEL, DURACION_SLIDE * 0.8)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(_limpiar_cartas)


func _poblar_cartas() -> void:
	_limpiar_cartas()
	var cartas: Array = ManoManager.mazo_completo
	contador.text = "%d cartas" % cartas.size()
	for carta in cartas:
		grid.add_child(_crear_miniatura(carta))
	scroll.scroll_vertical = 0


func _limpiar_cartas() -> void:
	for child in grid.get_children():
		child.queue_free()


func _crear_miniatura(carta: Carta) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(126, 166)
	wrapper.clip_contents = true

	var carta_ui = CARTA_SCENE.instantiate()
	carta_ui.interactiva = false
	carta_ui.datos = carta        # @export: se puede asignar antes de _ready()
	wrapper.add_child(carta_ui)   # _ready() corre aquí y lee .datos
	return wrapper

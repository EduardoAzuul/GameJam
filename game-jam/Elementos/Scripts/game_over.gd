# GameOverUI.gd
extends Control

func _ready() -> void:
	visible = false
	VidaManager.jugador_murio.connect(_on_jugador_murio)


func _on_jugador_murio() -> void:
	visible = true
	get_tree().paused = true  # opcional: congela el juego


func _on_boton_reintentar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

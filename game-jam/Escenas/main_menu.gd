extends Control

@onready var settings_panel = $SettingsPanel
@onready var volume_slider = $SettingsPanel/VBoxContainer/VolumeSlider

func _ready():
	# Asegurarnos de que el panel de ajustes esté oculto al iniciar
	settings_panel.hide()

# --- BOTONES PRINCIPALES ---

func _on_play_button_pressed():
	# Cambiar a tu escena principal de juego
	get_tree().change_scene_to_file("res://Escenas/JuegoPrincipal.tscn")

func _on_settings_button_pressed():
	settings_panel.show()

func _on_exit_button_pressed():
	get_tree().quit()

# --- BOTONES DE AJUSTES ---

func _on_close_settings_button_pressed():
	settings_panel.hide()

# Conecta la señal 'value_changed' del HSlider aquí
func _on_volume_slider_value_changed(value):
	# Godot maneja el audio en Decibeles (dB).
	# Convertimos un valor de 0 a 100 (del slider) a decibeles lineales.
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100.0))


func _on_volumen_h_slider_value_changed(value: float) -> void:
	pass # Replace with function body.

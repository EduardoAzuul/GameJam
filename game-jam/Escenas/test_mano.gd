# TestMano.gd
extends Control

func _ready() -> void:
	var mazo: Array[Carta] = [
		load("res://Elementos/Cartas/Mordisco.tres"),
		load("res://Elementos/Cartas/Golpe.tres"),
		load("res://Elementos/Cartas/Defensa.tres"),
	]
	ManoManager.iniciar_mazo(mazo)
	ManoManager.rellenar_mano()

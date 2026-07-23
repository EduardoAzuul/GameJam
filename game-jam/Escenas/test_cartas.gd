# TestCartas.gd
extends Node

@onready var enemigo_prueba: Enemigo = $Enemigo

func _ready() -> void:
	print("--- INICIO DE PRUEBA ---")
	print("Vida inicial del jugador: ", VidaManager.vida_actual)
	print("Vida inicial del enemigo: ", enemigo_prueba.current_hp)

	var mordisco: Carta = load("res://Elementos/Cartas/Mordisco.tres")

	print("Jugando carta: ", mordisco.nombre)
	var exito = CartaEjecutor.jugar_carta(mordisco, enemigo_prueba)

	print("¿Se jugó con éxito? ", exito)
	print("Vida del jugador: ", VidaManager.vida_actual)
	print("Vida del enemigo: ", enemigo_prueba.current_hp)

	print("--- Forzando intent ATTACK para prueba determinística ---")
	enemigo_prueba.current_intent = Enemigo.Intent.ATTACK
	enemigo_prueba.intent_value = 8
	enemigo_prueba.execute_turn()

	print("Vida del jugador tras turno enemigo: ", VidaManager.vida_actual)
	print("--- FIN DE PRUEBA ---")

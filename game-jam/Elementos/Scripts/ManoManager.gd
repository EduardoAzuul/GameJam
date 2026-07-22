# ManoManager.gd
extends Node

signal mano_actualizada(cartas_en_mano: Array[Carta])
signal pila_robo_actualizada(cantidad: int)
signal pila_descarte_actualizada(cantidad: int)

const TAMANO_MANO: int = 5

var pila_robo: Array[Carta] = []
var pila_descarte: Array[Carta] = []
var mano: Array[Carta] = []

func iniciar_mazo(mazo_inicial: Array[Carta]) -> void:
	pila_robo = mazo_inicial.duplicate()
	pila_robo.shuffle()
	pila_descarte.clear()
	mano.clear()
	pila_robo_actualizada.emit(pila_robo.size())
	pila_descarte_actualizada.emit(pila_descarte.size())

func robar(cantidad: int = 1) -> void:
	for i in range(cantidad):
		if pila_robo.is_empty():
			_reciclar_descarte()
		if pila_robo.is_empty():
			break  # no hay más cartas en ningún lado, se detiene
		var carta = pila_robo.pop_back()
		mano.append(carta)
	pila_robo_actualizada.emit(pila_robo.size())
	mano_actualizada.emit(mano)

func rellenar_mano() -> void:
	var faltantes = TAMANO_MANO - mano.size()
	if faltantes > 0:
		robar(faltantes)

func mover_a_descarte(carta: Carta) -> void:
	mano.erase(carta)
	pila_descarte.append(carta)
	mano_actualizada.emit(mano)
	pila_descarte_actualizada.emit(pila_descarte.size())

func descartar_mano_completa() -> void:
	for carta in mano.duplicate():
		mover_a_descarte(carta)

func _reciclar_descarte() -> void:
	if pila_descarte.is_empty():
		return
	pila_robo = pila_descarte.duplicate()
	pila_robo.shuffle()
	pila_descarte.clear()
	pila_descarte_actualizada.emit(pila_descarte.size())

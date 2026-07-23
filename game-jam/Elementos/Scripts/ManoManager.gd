# ManoManager.gd
extends Node

signal mano_actualizada(cartas_en_mano: Array[Carta])
signal pila_robo_actualizada(cantidad: int)
signal pila_descarte_actualizada(cantidad: int)

const TAMANO_MANO_BASE: int = 5

var pila_robo: Array[Carta] = []
var pila_descarte: Array[Carta] = []
var mano: Array[Carta] = []
var mazo_completo: Array[Carta] = []


func tamano_mano_actual() -> int:
	var extra = 1 if RelicManager.tiene("mano_larga") else 0
	print("Tamaño mano base: ", TAMANO_MANO_BASE, " + extra: ", extra, " = ", TAMANO_MANO_BASE + extra)
	return TAMANO_MANO_BASE + extra


func iniciar_mazo(mazo_inicial: Array[Carta]) -> void:
	mazo_completo = mazo_inicial.duplicate()
	pila_robo = mazo_inicial.duplicate()
	pila_robo.shuffle()
	pila_descarte.clear()
	mano.clear()
	pila_robo_actualizada.emit(pila_robo.size())
	pila_descarte_actualizada.emit(pila_descarte.size())


func robar(cantidad: int = 1) -> void:
	for i in range(cantidad):
		if mano.size() >= tamano_mano_actual():
			print("Mano llena (", mano.size(), "/", tamano_mano_actual(), "), no se roba más")
			break
		if pila_robo.is_empty():
			_reciclar_descarte()
		if pila_robo.is_empty():
			break
		var carta = pila_robo.pop_back()
		carta = EstadoManager.intentar_corromper(carta)
		mano.append(carta)
	pila_robo_actualizada.emit(pila_robo.size())
	mano_actualizada.emit(mano)


func rellenar_mano() -> void:
	var faltantes = tamano_mano_actual() - mano.size()
	print("rellenar_mano: faltantes = ", faltantes)
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

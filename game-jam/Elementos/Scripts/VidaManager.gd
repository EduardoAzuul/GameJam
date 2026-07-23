extends Node
# VidaManager.gd — Autoload

signal vida_cambiada(vida_actual, vida_maxima)
signal escudo_cambiado(escudo_actual)
signal dano_recibido(cantidad, fuente)
signal curacion_recibida(cantidad)
signal jugador_murio

var vida_maxima: int = 50
var vida_actual: int = 50
var escudo: int = 0

func recibir_dano(cantidad: int, fuente: String = "desconocida") -> void:
	if vida_actual <= 0:
		return # ya está muerto, evita doble-muerte
	var dano_restante = cantidad
	if escudo > 0:
		var absorbido = min(escudo, dano_restante)
		escudo -= absorbido
		dano_restante -= absorbido
		escudo_cambiado.emit(escudo)
	if dano_restante > 0:
		vida_actual = max(0, vida_actual - dano_restante)
	dano_recibido.emit(cantidad, fuente)
	vida_cambiada.emit(vida_actual, vida_maxima)
	if vida_actual <= 0:
		jugador_murio.emit()

func curar(cantidad: int) -> void:
	vida_actual = min(vida_maxima, vida_actual + cantidad)
	curacion_recibida.emit(cantidad)
	vida_cambiada.emit(vida_actual, vida_maxima)

func ganar_escudo(cantidad: int) -> void:
	escudo += cantidad
	escudo_cambiado.emit(escudo)

func puede_pagar_costo(costo: int) -> bool:
	return vida_actual - costo > 0  # > 0 si "no puedes suicidarte con una carta"

func pagar_costo_carta(costo: int) -> bool:
	if not puede_pagar_costo(costo):
		return false
	recibir_dano(costo, "costo_carta")
	return true

func modificar_vida_maxima(delta: int, piso_minimo: int = 20) -> void:
	vida_maxima = max(piso_minimo, vida_maxima + delta)
	vida_actual = min(vida_actual, vida_maxima)
	vida_cambiada.emit(vida_actual, vida_maxima)
	

func resetear_escudo() -> void:
	if RelicManager.tiene("piel_de_piedra"):
		return   # no se resetea, la reliquia lo protege
	escudo = 0
	escudo_cambiado.emit(escudo)

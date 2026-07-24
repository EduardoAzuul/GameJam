# TurnoManager.gd
extends Node

signal turno_terminado
signal nuevo_turno_iniciado

const COSTO_TERMINAR_TURNO: int = 3

var enemigo_actual: Enemigo = null
var procesando_turno: bool = false
var cartas_jugadas_este_turno: int = 0


func registrar_enemigo(enemigo: Enemigo) -> void:
	enemigo_actual = enemigo


func terminar_turno() -> void:
	if procesando_turno:
		return
	if VidaManager.vida_actual <= 0:
		return

	procesando_turno = true

	ManoManager.descartar_mano_completa()

	VidaManager.recibir_dano(COSTO_TERMINAR_TURNO, "fin_de_turno")
	if VidaManager.vida_actual <= 0:
		procesando_turno = false
		return

	if enemigo_actual != null and is_instance_valid(enemigo_actual):
		await enemigo_actual.execute_turn()
	if VidaManager.vida_actual <= 0:
		procesando_turno = false
		return

	EstadoManager.resolver_efectos_de_turno()
	if VidaManager.vida_actual <= 0:
		procesando_turno = false
		return

	VidaManager.resetear_escudo()  
	RelicManager.reiniciar_turno()
	ManoManager.rellenar_mano()

	cartas_jugadas_este_turno = 0
	turno_terminado.emit()
	nuevo_turno_iniciado.emit()
	procesando_turno = false

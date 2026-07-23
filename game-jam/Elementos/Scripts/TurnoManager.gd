# TurnoManager.gd
extends Node

signal turno_terminado
signal nuevo_turno_iniciado

const COSTO_TERMINAR_TURNO: int = 3

var enemigo_actual: Enemigo = null
var procesando_turno: bool = false


func registrar_enemigo(enemigo: Enemigo) -> void:
	enemigo_actual = enemigo


func terminar_turno() -> void:
	if procesando_turno:
		return  # evita doble-click mientras se procesa
	if VidaManager.vida_actual <= 0:
		return  # ya está muerto, no hacer nada más

	procesando_turno = true

	# 1. Descartar cartas no jugadas
	ManoManager.descartar_mano_completa()

	# 2. Costo fijo de terminar turno
	VidaManager.recibir_dano(COSTO_TERMINAR_TURNO, "fin_de_turno")
	if VidaManager.vida_actual <= 0:
		procesando_turno = false
		return

	# 3. Turno del enemigo
	if enemigo_actual != null and is_instance_valid(enemigo_actual):
		enemigo_actual.execute_turn()
	if VidaManager.vida_actual <= 0:
		procesando_turno = false
		return

	# 4. Efectos de Hambre/Cordura
	EstadoManager.resolver_efectos_de_turno()
	if VidaManager.vida_actual <= 0:
		procesando_turno = false
		return

	# 5. Nueva mano
	ManoManager.rellenar_mano()

	turno_terminado.emit()
	nuevo_turno_iniciado.emit()
	procesando_turno = false

# RelicManager.gd
extends Node

signal reliquia_agregada(reliquia: Reliquia)

const PROB_REFLEJO := 0.35        # 35% de chance de reflejar
const PORCENTAJE_REFLEJO := 0.3   # refleja 30% del daño recibido

var reliquias_activas: Array[Reliquia] = []
var _ids_activos: Dictionary = {}

# Estado temporal que se resetea cada turno del jugador
var primer_golpe_usado: bool = false


func agregar_reliquia(reliquia: Reliquia) -> void:
	reliquias_activas.append(reliquia)
	_ids_activos[reliquia.id] = true
	reliquia_agregada.emit(reliquia)


func tiene(id: String) -> bool:
	return _ids_activos.has(id)


func reiniciar_turno() -> void:
	primer_golpe_usado = false


# --- LÓGICA ESPECÍFICA DE CADA RELIQUIA ---

func calcular_dano_con_primer_golpe(valor_base: int) -> int:
	if tiene("primer_golpe") and not primer_golpe_usado:
		primer_golpe_usado = true
		return int(valor_base * 1.5)
	return valor_base


func intentar_reflejar(dano_recibido: int, enemigo: Enemigo) -> void:
	if not tiene("reflejo"):
		return
	if enemigo == null or not is_instance_valid(enemigo):
		return
	if randf() < PROB_REFLEJO:
		var reflejado = int(dano_recibido * PORCENTAJE_REFLEJO)
		if reflejado > 0:
			enemigo.recibir_dano(reflejado)

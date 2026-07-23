# EstadoManager.gd
extends Node

signal estado_cambiado(nombre_estado: String, nivel_actual: int, nivel_max: int)
signal panico_activado
signal panico_desactivado
signal carta_corrompida(carta: Carta, carta_original: Carta)

const NIVEL_MAXIMO := 10
const NIVEL_MINIMO := 0
const UMBRAL_PANICO := 0
const UMBRAL_CORRUPCION := 4
const DECAIMIENTO_CORDURA_POR_TURNO := 1   # 👈 nuevo: cuánto baja cada fin de turno

var estados: Dictionary = {
	"cordura": 10
}

var en_panico: bool = false


func aplicar(nombre_estado: String, delta: int) -> void:
	if not estados.has(nombre_estado):
		push_warning("Estado no reconocido: " + nombre_estado)
		return
	estados[nombre_estado] = clamp(estados[nombre_estado] + delta, NIVEL_MINIMO, NIVEL_MAXIMO)
	estado_cambiado.emit(nombre_estado, estados[nombre_estado], NIVEL_MAXIMO)

	if nombre_estado == "cordura":
		_revisar_panico()


func obtener_nivel(nombre_estado: String) -> int:
	return estados.get(nombre_estado, 0)


func resolver_efectos_de_turno() -> void:
	if not RelicManager.tiene("ancla"):  
		aplicar("cordura", -DECAIMIENTO_CORDURA_POR_TURNO)
	_resolver_cordura_pasiva()


func _resolver_cordura_pasiva() -> void:
	if en_panico:
		VidaManager.recibir_dano(3, "panico")


func _revisar_panico() -> void:
	var cordura = estados["cordura"]
	if cordura <= UMBRAL_PANICO and not en_panico:
		en_panico = true
		panico_activado.emit()
	elif cordura > UMBRAL_PANICO and en_panico:
		en_panico = false
		panico_desactivado.emit()


func intentar_corromper(carta: Carta) -> Carta:
	var cordura = estados["cordura"]
	if cordura > UMBRAL_CORRUPCION:
		return carta

	var probabilidad = (UMBRAL_CORRUPCION - cordura) / float(UMBRAL_CORRUPCION)
	if randf() > probabilidad:
		return carta

	var corrupta = _generar_version_corrupta(carta)
	carta_corrompida.emit(corrupta, carta)
	return corrupta


func _generar_version_corrupta(carta: Carta) -> Carta:
	var copia = carta.duplicate(true)
	copia.nombre = carta.nombre + " (corrupta)"
	for efecto in copia.efectos:
		if efecto.tipo == Efecto.TipoEfecto.ATACAR or efecto.tipo == Efecto.TipoEfecto.CURAR:
			efecto.valor = max(1, int(efecto.valor * 0.5))
	return copia

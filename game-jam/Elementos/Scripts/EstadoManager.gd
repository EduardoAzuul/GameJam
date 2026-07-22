# EstadoManager.gd
extends Node

signal estado_cambiado(nombre_estado: String, nivel_actual: int, nivel_max: int)

const NIVEL_MAXIMO := 10
const NIVEL_MINIMO := 0

var estados: Dictionary = {
	"hambre": 0,
	"cordura": 10  # cordura empieza llena, hambre empieza vacía
}

func aplicar(nombre_estado: String, delta: int) -> void:
	if not estados.has(nombre_estado):
		push_warning("Estado no reconocido: " + nombre_estado)
		return
	estados[nombre_estado] = clamp(estados[nombre_estado] + delta, NIVEL_MINIMO, NIVEL_MAXIMO)
	estado_cambiado.emit(nombre_estado, estados[nombre_estado], NIVEL_MAXIMO)

func obtener_nivel(nombre_estado: String) -> int:
	return estados.get(nombre_estado, 0)

func resolver_efectos_de_turno() -> void:
	_resolver_hambre()
	_resolver_cordura()

func _resolver_hambre() -> void:
	var nivel = estados["hambre"]
	if nivel >= 7:
		VidaManager.modificar_vida_maxima(-2, 20)  # hambre alta reduce vida máxima
	elif nivel >= 4:
		VidaManager.modificar_vida_maxima(-1, 20)

func _resolver_cordura() -> void:
	var nivel = estados["cordura"]
	# a menor cordura, más difícil el minijuego de la Rueda (esto lo lee RuedaManager directamente)
	if nivel <= 2:
		VidaManager.recibir_dano(2, "cordura_baja")  # ejemplo: pánico daña un poco

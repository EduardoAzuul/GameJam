# TestMano.gd
extends Control

const RUTA_CARTAS: String = "res://Elementos/Cartas/"
const TAMANO_MAZO_INICIAL: int = 10


func _ready() -> void:
	var cartas_disponibles = _cargar_todas_las_cartas(RUTA_CARTAS)

	if cartas_disponibles.is_empty():
		push_error("No se encontraron cartas .tres en " + RUTA_CARTAS)
		return

	var mazo: Array[Carta] = _armar_mazo_random(cartas_disponibles, TAMANO_MAZO_INICIAL)

	ManoManager.iniciar_mazo(mazo)
	ManoManager.rellenar_mano()

	TurnoManager.registrar_enemigo($Enemigo)


func _cargar_todas_las_cartas(ruta: String) -> Array[Carta]:
	var resultado: Array[Carta] = []
	var dir = DirAccess.open(ruta)
	if dir:
		dir.list_dir_begin()
		var archivo = dir.get_next()
		while archivo != "":
			if archivo.ends_with(".tres"):
				var carta = load(ruta + archivo)
				if carta is Carta:
					resultado.append(carta)
			archivo = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("No se pudo abrir la carpeta: " + ruta)
	return resultado


func _armar_mazo_random(disponibles: Array[Carta], cantidad: int) -> Array[Carta]:
	var mazo: Array[Carta] = []
	for i in range(cantidad):
		var carta_base = disponibles[randi() % disponibles.size()]
		mazo.append(carta_base.duplicate())
	return mazo

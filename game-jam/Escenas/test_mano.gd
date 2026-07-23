# TestMano.gd
extends Control

const RUTA_CARTAS: String = "res://Elementos/Cartas/"
const RUTA_RELIQUIAS: String = "res://Elementos/Reliquias/"
const TAMANO_MAZO_INICIAL: int = 10


func _ready() -> void:
	var cartas_disponibles = _cargar_recursos_de_carpeta(RUTA_CARTAS, "Carta")
	if cartas_disponibles.is_empty():
		push_error("No se encontraron cartas .tres en " + RUTA_CARTAS)
		return

	var mazo: Array[Carta] = _armar_mazo_random(cartas_disponibles, TAMANO_MAZO_INICIAL)
	ManoManager.iniciar_mazo(mazo)

	_agregar_todas_las_reliquias()

	ManoManager.rellenar_mano()
	TurnoManager.registrar_enemigo($Enemigo)


func _cargar_recursos_de_carpeta(ruta: String, tipo_esperado: String) -> Array:
	var resultado: Array = []
	var dir = DirAccess.open(ruta)
	if dir:
		dir.list_dir_begin()
		var archivo = dir.get_next()
		while archivo != "":
			if archivo.ends_with(".tres"):
				var recurso = load(ruta + archivo)
				if recurso != null and recurso.get_class() != "":
					if (tipo_esperado == "Carta" and recurso is Carta) or (tipo_esperado == "Reliquia" and recurso is Reliquia):
						resultado.append(recurso)
			archivo = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("No se pudo abrir la carpeta: " + ruta)
	return resultado


func _armar_mazo_random(disponibles: Array, cantidad: int) -> Array[Carta]:
	var mazo: Array[Carta] = []
	for i in range(cantidad):
		var carta_base = disponibles[randi() % disponibles.size()]
		mazo.append(carta_base.duplicate())
	return mazo


func _agregar_todas_las_reliquias() -> void:
	var reliquias = _cargar_recursos_de_carpeta(RUTA_RELIQUIAS, "Reliquia")
	if reliquias.is_empty():
		push_warning("No se encontraron reliquias .tres en " + RUTA_RELIQUIAS)
		return

	for reliquia in reliquias:
		RelicManager.agregar_reliquia(reliquia)
		print("Reliquia activa: ", reliquia.nombre, " (id: ", reliquia.id, ")")

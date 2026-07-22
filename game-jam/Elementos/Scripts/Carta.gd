# Carta.gd
extends Resource
class_name Carta

@export var nombre: String = "Carta sin nombre"
@export var descripcion: String = ""
@export var icono: Texture2D
@export var costo_vida: int = 5
@export var efectos: Array[Efecto] = []

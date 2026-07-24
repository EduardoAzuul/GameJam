# Efecto.gd
extends Resource
class_name Efecto

enum TipoEfecto { ATACAR, DEFENDER, CURAR, APLICAR_ESTADO, ROBAR_CARTAS, APLICAR_ESTADO_ENEMIGO, DESCARTAR_ELEGIDAS, TODO_O_NADA }

@export var tipo: TipoEfecto = TipoEfecto.ATACAR
@export var valor: int = 5
@export var estado_a_aplicar: String = ""
@export var num_golpes: int = 1
@export var aleatorio: bool = false
@export var valor_max: int = 0
@export var escalado_vida: bool = false

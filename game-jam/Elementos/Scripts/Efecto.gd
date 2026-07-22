# Efecto.gd
extends Resource
class_name Efecto

enum TipoEfecto { ATACAR, DEFENDER, CURAR, APLICAR_ESTADO, ROBAR_CARTAS }

@export var tipo: TipoEfecto = TipoEfecto.ATACAR
@export var valor: int = 5
@export var estado_a_aplicar: String = ""

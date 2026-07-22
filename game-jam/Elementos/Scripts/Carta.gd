# Carta.gd
extends Resource
class_name Carta

enum TipoEfecto { ATACAR, DEFENDER, CURAR, APLICAR_ESTADO, ROBAR_CARTAS }

@export var nombre: String = "Carta sin nombre"
@export var descripcion: String = ""
@export var icono: Texture2D
@export var costo_vida: int = 5

@export var tipo_efecto: TipoEfecto = TipoEfecto.ATACAR
@export var valor_efecto: int = 5          # daño, escudo o curación según tipo_efecto
@export var estado_a_aplicar: String = ""  # "hambre", "cordura", etc. (solo si TipoEfecto.APLICAR_ESTADO)
@export var valor_estado: int = 1

# Enemigo.gd
extends Area2D
class_name Enemigo

signal enemigo_murio
signal hp_cambiado(hp_actual: int, hp_maximo: int)
signal intent_cambiado(intent: Intent, valor: int)

enum Intent { ATTACK, DEFEND, APPLY_STATUS }

@export var max_hp: int = 40
@export var estado_a_aplicar: String = "hambre"  # configurable por enemigo/tipo

var current_hp: int = 40
var block: int = 0
var current_intent: Intent
var intent_value: int = 0
var esta_muerto: bool = false

@onready var hp_label = $UI/HPLabel
@onready var intent_label = $UI/IntentLabel


func _ready() -> void:
	current_hp = max_hp
	decide_next_turn()
	update_ui()


# --- CICLO DE TURNO ---

func decide_next_turn() -> void:
	current_intent = Intent.values()[randi() % Intent.size()]
	match current_intent:
		Intent.ATTACK:
			intent_value = 8
		Intent.DEFEND:
			intent_value = 5
		Intent.APPLY_STATUS:
			intent_value = 1
	intent_cambiado.emit(current_intent, intent_value)
	update_ui()


func execute_turn() -> void:
	if esta_muerto:
		return

	block = 0
	match current_intent:
		Intent.ATTACK:
			VidaManager.recibir_dano(intent_value, "enemigo")
		Intent.DEFEND:
			block += intent_value
		Intent.APPLY_STATUS:
			EstadoManager.aplicar(estado_a_aplicar, intent_value)

	decide_next_turn()
	update_ui()


# --- INTERACCIÓN CON CARTAS ---

func recibir_dano(cantidad: int) -> void:
	if esta_muerto:
		return

	var dano_restante = max(cantidad - block, 0)
	block = max(block - cantidad, 0)
	current_hp = max(current_hp - dano_restante, 0)

	hp_cambiado.emit(current_hp, max_hp)
	update_ui()

	if current_hp <= 0:
		morir()


func morir() -> void:
	if esta_muerto:
		return
	esta_muerto = true
	print("Enemigo derrotado")
	enemigo_murio.emit()
	queue_free()


func update_ui() -> void:
	hp_label.text = "HP: %d/%d | Escudo: %d" % [current_hp, max_hp, block]
	match current_intent:
		Intent.ATTACK:
			intent_label.text = "Atacará (%d)" % intent_value
		Intent.DEFEND:
			intent_label.text = "Defenderá (%d)" % intent_value
		Intent.APPLY_STATUS:
			intent_label.text = "Aplicará Estado (%s)" % estado_a_aplicar

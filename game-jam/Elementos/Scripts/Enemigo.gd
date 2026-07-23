# Enemigo.gd
extends Area2D
class_name Enemigo

signal enemigo_murio
signal hp_cambiado(hp_actual: int, hp_maximo: int)
signal intent_cambiado(intent: Intent, valor: int)

enum Intent { ATTACK, DEFEND, APPLY_STATUS }

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://Escenas/UserInterface/DamageNumber.tscn")

@export var max_hp: int = 40
@export var estado_a_aplicar: String = "hambre"

var current_hp: int = 40
var block: int = 0
var current_intent: Intent
var intent_value: int = 0
var esta_muerto: bool = false

@onready var hp_label = $UI/HPLabel
@onready var intent_label = $UI/IntentLabel
@onready var sprite: Node2D = $Sprite2D  # cambiá a $Polygon2D si usás ese como visual principal

var _escala_base: Vector2


func _ready() -> void:
	current_hp = max_hp
	_escala_base = sprite.scale
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

	_mostrar_numero_flotante(dano_restante)
	_squish()
	_flash(Color(1, 0.3, 0.3) if dano_restante > 0 else Color(0.6, 0.6, 1))

	if current_hp <= 0:
		morir()


func _squish() -> void:
	sprite.scale = _escala_base
	var tween = create_tween()
	tween.tween_property(sprite, "scale", _escala_base * Vector2(1.25, 0.75), 0.08)
	tween.tween_property(sprite, "scale", _escala_base, 0.15).set_trans(Tween.TRANS_ELASTIC)


func _flash(color: Color) -> void:
	sprite.modulate = color
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func _mostrar_numero_flotante(cantidad: int, es_curacion: bool = false) -> void:
	if cantidad <= 0:
		return
	var numero = DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().root.add_child(numero)
	numero.global_position = global_position + Vector2(randf_range(-20, 20), -40)
	numero.configurar(cantidad, es_curacion)
	numero.configurar(cantidad, es_curacion)


func morir() -> void:
	if esta_muerto:
		return
	esta_muerto = true
	enemigo_murio.emit()

	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)


func update_ui() -> void:
	hp_label.text = "HP: %d/%d | Escudo: %d" % [current_hp, max_hp, block]
	match current_intent:
		Intent.ATTACK:
			intent_label.text = "Atacará (%d)" % intent_value
		Intent.DEFEND:
			intent_label.text = "Defenderá (%d)" % intent_value
		Intent.APPLY_STATUS:
			intent_label.text = "Aplicará Estado (%s)" % estado_a_aplicar

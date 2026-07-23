# Enemigo.gd
extends Area2D
class_name Enemigo

signal enemigo_murio
signal hp_cambiado(hp_actual: int, hp_maximo: int)
signal intent_cambiado(intent: Intent, valor: int)

enum Intent { ATTACK, DEFEND, APPLY_STATUS }

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://Escenas/UserInterface/DamageNumber.tscn")

const ICONO_ATAQUE: Texture2D = preload("res://Assets/ATAQUE.png")
const ICONO_DEFENSA: Texture2D = preload("res://Assets/DEFENSA.png")
const ICONO_ESTADO: Texture2D = preload("res://Assets/ESTADO.png")

const COLOR_ATAQUE := Color(1, 0.35, 0.35)
const COLOR_DEFENSA := Color(0.35, 0.55, 1)
const COLOR_ESTADO := Color(0.7, 0.35, 1)

const UMBRAL_HP_AGITADO := 0.25  # bajo este % de HP, la respiración se acelera

@export var max_hp: int = 40
@export var estado_a_aplicar: String = "cordura"

var current_hp: int = 40
var block: int = 0
var current_intent: Intent
var intent_value: int = 0
var esta_muerto: bool = false

@onready var hp_label = $UI/HPLabel
@onready var intent_label = $UI/IntentLabel
@onready var intent_icono: TextureRect = $UI/IntentIcono
@onready var sprite: Node2D = $Sprite2D

var _escala_base: Vector2
var _pos_base: Vector2
var _tween_idle: Tween
var _material_sprite: ShaderMaterial


func _ready() -> void:
	current_hp = max_hp
	_escala_base = sprite.scale
	_pos_base = sprite.position
	_material_sprite = sprite.material as ShaderMaterial

	decide_next_turn()
	update_ui()
	_iniciar_idle()

	EstadoManager.estado_cambiado.connect(_on_estado_cambiado)
	_actualizar_intensidad_paranormal()


# --- IDLE (respiración) ---

func _iniciar_idle() -> void:
	var duracion = 2.2
	var amplitud_escala = 1.02

	if current_hp < max_hp * UMBRAL_HP_AGITADO:
		duracion = 0.7          # respiración agitada solo cerca de la muerte
		amplitud_escala = 1.05

	_tween_idle = create_tween().set_loops()
	_tween_idle.tween_property(sprite, "scale", _escala_base * amplitud_escala, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_idle.tween_property(sprite, "scale", _escala_base, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _pausar_idle() -> void:
	if _tween_idle:
		_tween_idle.kill()


func _reanudar_idle() -> void:
	_iniciar_idle()


# --- SHADER PARANORMAL (ligado a Cordura) ---

func _on_estado_cambiado(nombre: String, _nivel: int, _max: int) -> void:
	if nombre == "cordura":
		_actualizar_intensidad_paranormal()


func _actualizar_intensidad_paranormal() -> void:
	if _material_sprite == null:
		return
	var cordura = EstadoManager.obtener_nivel("cordura")
	var intensidad = 1.0 - (cordura / float(EstadoManager.NIVEL_MAXIMO))
	intensidad = clamp(intensidad, 0.2, 1.0)
	_material_sprite.set_shader_parameter("intensidad", intensidad)


func _pulso_paranormal_temporal() -> void:
	if _material_sprite == null:
		return
	var tween = create_tween()
	tween.tween_method(
		func(v): _material_sprite.set_shader_parameter("amplitud", v),
		0.01, 0.04, 0.15
	)
	tween.tween_method(
		func(v): _material_sprite.set_shader_parameter("amplitud", v),
		0.04, 0.01, 0.3
	)


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
	_pop_intent()


func execute_turn() -> void:
	if esta_muerto:
		return
	block = 0
	_pausar_idle()

	match current_intent:
		Intent.ATTACK:
			await _animar_ataque()
			VidaManager.recibir_dano(intent_value, "enemigo")
		Intent.DEFEND:
			await _animar_defensa()
			block += intent_value
		Intent.APPLY_STATUS:
			await _animar_estado()
			EstadoManager.aplicar(estado_a_aplicar, -intent_value)

	_reanudar_idle()
	decide_next_turn()
	update_ui()


# --- ANIMACIONES DE ACCIÓN ---

func _animar_ataque() -> void:
	var direccion_embiste = Vector2(-40, 20)  # ajustá según hacia dónde está el jugador

	var tween = create_tween()
	tween.tween_property(sprite, "position", _pos_base - direccion_embiste * 0.4, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position", _pos_base + direccion_embiste, 0.1).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate", COLOR_ATAQUE, 0.05)
	tween.tween_property(sprite, "position", _pos_base, 0.2).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.2)

	await tween.finished


func _animar_defensa() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "scale", _escala_base * 1.2, 0.2).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate", COLOR_DEFENSA, 0.2)
	await tween.finished


func _animar_estado() -> void:
	_pulso_paranormal_temporal()
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(sprite, "position", _pos_base + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.05)
	tween.tween_property(sprite, "position", _pos_base, 0.05)
	tween.parallel().tween_property(sprite, "modulate", COLOR_ESTADO, 0.15)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	await tween.finished


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

	if block == 0:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", _escala_base, 0.15)

	if current_hp <= 0:
		morir()
		return

	# recalcular si la respiración debe agitarse por HP bajo
	_pausar_idle()
	_reanudar_idle()


func _squish() -> void:
	var escala_actual = sprite.scale
	var tween = create_tween()
	tween.tween_property(sprite, "scale", escala_actual * Vector2(1.25, 0.75), 0.08)
	tween.tween_property(sprite, "scale", escala_actual, 0.15).set_trans(Tween.TRANS_ELASTIC)


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


func morir() -> void:
	if esta_muerto:
		return
	esta_muerto = true
	_pausar_idle()
	enemigo_murio.emit()

	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.35).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)


# --- INTENT: ÍCONOS, COLORES Y POP ---

func _pop_intent() -> void:
	intent_icono.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(intent_icono, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func update_ui() -> void:
	hp_label.text = "HP: %d/%d | Escudo: %d" % [current_hp, max_hp, block]
	match current_intent:
		Intent.ATTACK:
			intent_label.text = "Atacará (%d)" % intent_value
			intent_icono.texture = ICONO_ATAQUE
			intent_label.modulate = COLOR_ATAQUE
		Intent.DEFEND:
			intent_label.text = "Defenderá (%d)" % intent_value
			intent_icono.texture = ICONO_DEFENSA
			intent_label.modulate = COLOR_DEFENSA
		Intent.APPLY_STATUS:
			intent_label.text = "Aplicará Estado (%s)" % estado_a_aplicar
			intent_icono.texture = ICONO_ESTADO
			intent_label.modulate = COLOR_ESTADO

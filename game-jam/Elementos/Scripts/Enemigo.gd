# Enemigo.gd
extends Area2D
class_name Enemigo

signal enemigo_murio
signal hp_cambiado(hp_actual: int, hp_maximo: int)
signal intent_cambiado(intent: Intent, valor: int)

enum Intent { ATTACK, DEFEND, APPLY_STATUS, MULTI_ATTACK, BUFF_SELF, DEBILITAR, COMBO_CARGA }

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://Escenas/UserInterface/DamageNumber.tscn")

const ICONO_ATAQUE: Texture2D = preload("res://Assets/ATAQUE.png")
const ICONO_DEFENSA: Texture2D = preload("res://Assets/DEFENSA.png")
const ICONO_ESTADO: Texture2D = preload("res://Assets/ESTADO.png")
const ICONO_MULTI: Texture2D = preload("res://Assets/ATAQUE2.png")

const COLOR_ATAQUE := Color(1, 0.35, 0.35)
const COLOR_DEFENSA := Color(0.35, 0.55, 1)
const COLOR_ESTADO := Color(0.7, 0.35, 1)
const COLOR_MULTI := Color(1, 0.55, 0.2)
const COLOR_BUFF := Color(0.9, 0.8, 0.1)
const COLOR_DEBILITAR := Color(0.5, 0.2, 0.8)
const COLOR_COMBO := Color(1, 0.1, 0.1)

const UMBRAL_HP_AGITADO := 0.25
const UMBRAL_FASE_2 := 0.50
const UMBRAL_FASE_3 := 0.25

# Patrones de intents por fase (se ciclan), inicializados en _ready()
var PATRON_FASE_0: Array = []
var PATRON_FASE_1: Array = []
var PATRON_FASE_2: Array = []

@export var max_hp: int = 40
@export var estado_a_aplicar: String = "cordura"

var current_hp: int = 40
var block: int = 0
var current_intent: Intent
var intent_value: int = 0
var esta_muerto: bool = false
var estados_enemigo: Dictionary = {}

var _fase_actual: int = 0
var _patron_indice: int = 0
var _combo_cargado: bool = false

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

	PATRON_FASE_0 = [Intent.ATTACK, Intent.DEFEND, Intent.APPLY_STATUS, Intent.ATTACK]
	PATRON_FASE_1 = [Intent.ATTACK, Intent.ATTACK, Intent.MULTI_ATTACK, Intent.DEFEND]
	PATRON_FASE_2 = [Intent.BUFF_SELF, Intent.ATTACK, Intent.COMBO_CARGA, Intent.DEBILITAR, Intent.ATTACK]

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
		duracion = 0.7
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


# --- FASES Y PATRONES ---

func _verificar_cambio_fase() -> void:
	var ratio = float(current_hp) / float(max_hp)
	var nueva_fase: int
	if ratio <= UMBRAL_FASE_3:
		nueva_fase = 2
	elif ratio <= UMBRAL_FASE_2:
		nueva_fase = 1
	else:
		nueva_fase = 0

	if nueva_fase != _fase_actual:
		_fase_actual = nueva_fase
		_patron_indice = 0


func _patron_para_fase_actual() -> Intent:
	var patron: Array
	match _fase_actual:
		0: patron = PATRON_FASE_0
		1: patron = PATRON_FASE_1
		2: patron = PATRON_FASE_2
		_: patron = PATRON_FASE_0

	var intent: Intent = patron[_patron_indice % patron.size()]
	_patron_indice = (_patron_indice + 1) % patron.size()
	return _intent_reactivo(intent)


func _intent_reactivo(intent_base: Intent) -> Intent:
	# Si tiene veneno alto, el enemigo huye a defensa
	if tiene_estado("veneno") and estados_enemigo.get("veneno", 0) >= 3:
		return Intent.DEFEND
	# Si el jugador jugó 3+ cartas este turno, el enemigo se pone defensivo
	if TurnoManager.cartas_jugadas_este_turno >= 3:
		return Intent.DEFEND
	# Si el jugador está en pánico, el enemigo presiona
	if EstadoManager.en_panico:
		return Intent.ATTACK
	return intent_base


# --- CICLO DE TURNO ---

func decide_next_turn() -> void:
	# Si hay combo cargado, el siguiente turno SIEMPRE es el golpe fuerte
	if _combo_cargado:
		current_intent = Intent.ATTACK
		intent_value = 18
		_combo_cargado = false
	else:
		current_intent = _patron_para_fase_actual()
		match current_intent:
			Intent.ATTACK:
				var enrage = estados_enemigo.get("enrage", 0)
				intent_value = int(8 * (1.0 + enrage * 0.25))
			Intent.DEFEND:
				intent_value = 5
			Intent.APPLY_STATUS:
				intent_value = 1
			Intent.MULTI_ATTACK:
				intent_value = 3
			Intent.BUFF_SELF:
				intent_value = 2
			Intent.DEBILITAR:
				intent_value = 1
			Intent.COMBO_CARGA:
				intent_value = 18

	intent_cambiado.emit(current_intent, intent_value)
	update_ui()
	_pop_intent()


func aplicar_estado(nombre: String, valor: int) -> void:
	estados_enemigo[nombre] = max(0, estados_enemigo.get(nombre, 0) + valor)


func tiene_estado(nombre: String) -> bool:
	return estados_enemigo.get(nombre, 0) > 0


func resolver_estados() -> void:
	var veneno = estados_enemigo.get("veneno", 0)
	if veneno > 0:
		recibir_dano(veneno)
	for nombre in estados_enemigo.keys():
		estados_enemigo[nombre] = max(0, estados_enemigo[nombre] - 1)
	# enrage decae separado (no se reduce dos veces si se agregó arriba)


func execute_turn() -> void:
	if esta_muerto:
		return
	resolver_estados()
	block = 0
	_pausar_idle()

	match current_intent:
		Intent.ATTACK:
			var dano = intent_value
			if tiene_estado("debilidad"):
				dano = max(1, int(dano * 0.5))
			if EstadoManager.obtener_nivel("vulnerabilidad") > 0:
				dano = int(dano * 1.5)
			await _animar_ataque()
			if EstadoManager.obtener_nivel("esquiva") > 0:
				EstadoManager.aplicar("esquiva", -1)
				if EstadoManager.obtener_nivel("contraataque") > 0:
					EstadoManager.aplicar("contraataque", -1)
					recibir_dano(dano)
			else:
				VidaManager.recibir_dano(dano, "enemigo")
				RelicManager.intentar_reflejar(dano, self)

		Intent.DEFEND:
			await _animar_defensa()
			block += intent_value

		Intent.APPLY_STATUS:
			await _animar_estado()
			EstadoManager.aplicar(estado_a_aplicar, -intent_value)

		Intent.MULTI_ATTACK:
			var dano_por_golpe = intent_value
			if tiene_estado("debilidad"):
				dano_por_golpe = max(1, int(dano_por_golpe * 0.5))
			if EstadoManager.obtener_nivel("vulnerabilidad") > 0:
				dano_por_golpe = int(dano_por_golpe * 1.5)
			for _i in range(3):
				if esta_muerto:
					break
				await _animar_ataque()
				if EstadoManager.obtener_nivel("esquiva") > 0:
					EstadoManager.aplicar("esquiva", -1)
					if EstadoManager.obtener_nivel("contraataque") > 0:
						EstadoManager.aplicar("contraataque", -1)
						recibir_dano(dano_por_golpe)
				else:
					VidaManager.recibir_dano(dano_por_golpe, "enemigo")
					RelicManager.intentar_reflejar(dano_por_golpe, self)
				await get_tree().create_timer(0.1).timeout

		Intent.BUFF_SELF:
			await _animar_buff()
			aplicar_estado("enrage", intent_value)
			# En fase 1+, también gana barrera
			if _fase_actual >= 1:
				aplicar_estado("barrera", 1)

		Intent.DEBILITAR:
			await _animar_estado()
			EstadoManager.aplicar("cordura", -intent_value)
			EstadoManager.aplicar("vulnerabilidad", intent_value)
			EstadoManager.aplicar("debilidad", intent_value)

		Intent.COMBO_CARGA:
			await _animar_carga()
			_combo_cargado = true

	_reanudar_idle()
	decide_next_turn()
	update_ui()


# --- ANIMACIONES DE ACCIÓN ---

func _animar_ataque() -> void:
	SonidoManager.enemigo_ataca()
	var direccion_embiste = Vector2(-40, 20)

	var tween = create_tween()
	tween.tween_property(sprite, "position", _pos_base - direccion_embiste * 0.4, 0.18).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position", _pos_base + direccion_embiste, 0.1).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite, "modulate", COLOR_ATAQUE, 0.05)
	tween.tween_property(sprite, "position", _pos_base, 0.2).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.2)

	await tween.finished


func _animar_defensa() -> void:
	SonidoManager.enemigo_defiende()
	var tween = create_tween()
	tween.tween_property(sprite, "scale", _escala_base * 1.2, 0.2).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate", COLOR_DEFENSA, 0.2)
	await tween.finished


func _animar_estado() -> void:
	SonidoManager.enemigo_aplica_estado()
	_pulso_paranormal_temporal()
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(sprite, "position", _pos_base + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.05)
	tween.tween_property(sprite, "position", _pos_base, 0.05)
	tween.parallel().tween_property(sprite, "modulate", COLOR_ESTADO, 0.15)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
	await tween.finished


func _animar_buff() -> void:
	SonidoManager.enemigo_aplica_estado()
	var tween = create_tween()
	tween.tween_property(sprite, "scale", _escala_base * 1.3, 0.25).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate", COLOR_BUFF, 0.25)
	tween.tween_property(sprite, "scale", _escala_base, 0.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	await tween.finished


func _animar_carga() -> void:
	SonidoManager.enemigo_aplica_estado()
	var tween = create_tween()
	# Vibración intensa de advertencia
	for i in range(5):
		tween.tween_property(sprite, "position", _pos_base + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.04)
	tween.tween_property(sprite, "position", _pos_base, 0.05)
	# Crece y se tiñe de rojo intenso
	tween.parallel().tween_property(sprite, "scale", _escala_base * 1.3, 0.25).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate", COLOR_COMBO, 0.15)
	tween.tween_property(sprite, "scale", _escala_base, 0.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	await tween.finished


# --- INTERACCIÓN CON CARTAS ---

func recibir_dano(cantidad: int) -> void:
	if esta_muerto:
		return

	# Barrera: solo se rompe con un ataque perfecto
	if tiene_estado("barrera"):
		if SkillCheckManager.ultimo_resultado != "perfect":
			_flash(Color(0.6, 0.6, 1))  # flash azul = golpe absorbido por barrera
			_squish()
			return
		else:
			estados_enemigo["barrera"] = 0  # barrera rota por golpe perfect

	var dano_restante = max(cantidad - block, 0)
	block = max(block - cantidad, 0)
	current_hp = max(current_hp - dano_restante, 0)

	hp_cambiado.emit(current_hp, max_hp)
	_verificar_cambio_fase()
	update_ui()

	if dano_restante > 0:
		SonidoManager.enemigo_recibe_danio()
	_mostrar_numero_flotante(dano_restante)
	_squish()
	_flash(Color(1, 0.3, 0.3) if dano_restante > 0 else Color(0.6, 0.6, 1))

	if block == 0:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", _escala_base, 0.15)

	if current_hp <= 0:
		morir()
		return

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
	SonidoManager.enemigo_muere()
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
	var escudo_str = ""
	if block > 0:
		escudo_str = " | Escudo: %d" % block
	var enrage = estados_enemigo.get("enrage", 0)
	var enrage_str = ""
	if enrage > 0:
		enrage_str = " | Enrage: %d" % enrage
	var barrera_str = ""
	if tiene_estado("barrera"):
		barrera_str = " | [Barrera]"
	hp_label.text = "HP: %d/%d%s%s%s" % [current_hp, max_hp, escudo_str, enrage_str, barrera_str]

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
		Intent.MULTI_ATTACK:
			intent_label.text = "Multi-Golpe (3x%d)" % intent_value
			intent_icono.texture = ICONO_MULTI
			intent_label.modulate = COLOR_MULTI
		Intent.BUFF_SELF:
			intent_label.text = "Se fortalece (+%d enrage)" % intent_value
			intent_icono.texture = ICONO_ESTADO
			intent_label.modulate = COLOR_BUFF
		Intent.DEBILITAR:
			intent_label.text = "Debilitará (cord/vuln/deb)"
			intent_icono.texture = ICONO_ESTADO
			intent_label.modulate = COLOR_DEBILITAR
		Intent.COMBO_CARGA:
			intent_label.text = "¡Cargando! Próx: %d dmg" % intent_value
			intent_icono.texture = ICONO_ATAQUE
			intent_label.modulate = COLOR_COMBO

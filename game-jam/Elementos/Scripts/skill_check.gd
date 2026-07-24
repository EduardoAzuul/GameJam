extends Node2D
signal check_finished(success: bool, tipo: String)
signal rebote_alcanzado

const RIPPLE_SCENE: PackedScene = preload("res://Escenas/UserInterface/Ripple.tscn")
const ESCALA_OBJETIVO := Vector2(0.2, 0.2)

# --- Opacidad de efectos ---
const ALPHA_PARTICULAS := 0.45
const ALPHA_REBOTE := 0.18

# --- Feedback de Cordura ---
const COLOR_FANTASMA := Color(0.4, 1.0, 0.55)

@export var rotation_speed_base: float = 300.0
@export var velocidad_rotacion_aro: float = 15.0
@export var radio_decoy: float = 150.0
@export var amplitud_jitter_max: float = 25.0
@export var alpha_fondo_min: float = 0.5
@export var alpha_fondo_max: float = 0.85

var _velocidad_suavizada: float = 0.0
const SUAVIZADO_VELOCIDAD := 12.0
const SENSIBILIDAD_INCLINACION := 0.05

# --- Variables de Estado ---
var rotation_speed: float = 300.0
var is_active: bool = false
var current_rotation: float = 0.0
var move_direction: int = 1
var zonas: Array = []
var limite_fallo_superior: float = 720.0
var limite_fallo_inferior: float = -10.0
var _uso_doble_oportunidad: bool = false
var _tween_rotacion_aro: Tween

var _jitter_amplitud: float = 0.0
var _fondo_alpha_base: float = 1.0
var _material_rueda: ShaderMaterial

# --- Capas de partículas ---
var _p_main_hit: CPUParticles2D
var _p_flare: CPUParticles2D
var _p_spread: CPUParticles2D
var _p_floating: CPUParticles2D

# --- Rayos en punta (dibujados en _draw) ---
var _spikes: Array = []
# --- Zonas fantasma / señuelo ---
var _fantasmas: Array = []

# --- Referencias a los Nodos ---
@onready var aguja_pivot = $RuedaCompleta/AgujaPivot
@onready var zona_exito_nodo = $RuedaCompleta/ZonaExito
@onready var base_rueda = $RuedaCompleta/BaseRueda
@onready var fondo_oscuro = $FondoOscuro


func _ready():
	scale = Vector2.ZERO
	modulate.a = 0.0
	hide()
	set_process(false)
	_iniciar_rotacion_aro()
	_crear_capas_particulas()

	if fondo_oscuro:
		_fondo_alpha_base = fondo_oscuro.modulate.a
	_material_rueda = base_rueda.material as ShaderMaterial


# --- ROTACIÓN CONTINUA DEL ARO EXTERIOR ---

func _iniciar_rotacion_aro() -> void:
	_tween_rotacion_aro = create_tween().set_loops()
	_tween_rotacion_aro.tween_property(
		base_rueda, "rotation_degrees",
		base_rueda.rotation_degrees + 360.0,
		360.0 / velocidad_rotacion_aro
	).as_relative().set_trans(Tween.TRANS_LINEAR)


# --- FEEDBACK DE CORDURA ---

func _aplicar_vinculacion_cordura(factor: float) -> void:
	if fondo_oscuro:
		var alpha_objetivo = lerp(alpha_fondo_min, alpha_fondo_max, factor) * _fondo_alpha_base
		var t = create_tween()
		t.tween_property(fondo_oscuro, "modulate:a", alpha_objetivo, 0.3)

	_jitter_amplitud = lerp(0.0, amplitud_jitter_max, factor)

	if _material_rueda:
		_material_rueda.set_shader_parameter("intensidad", clamp(factor, 0.15, 1.0))


func _restaurar_vinculacion_cordura() -> void:
	_jitter_amplitud = 0.0
	$RuedaCompleta.position = Vector2.ZERO
	_fantasmas.clear()
	if fondo_oscuro:
		var t = create_tween()
		t.tween_property(fondo_oscuro, "modulate:a", _fondo_alpha_base, 0.3)


func _loop_efectos_paranormales(factor: float) -> void:
	if factor <= 0.05:
		return  # cordura casi llena, sin ruido paranormal

	while is_active:
		var espera = randf_range(1.2, 2.6) / (0.4 + factor)
		await get_tree().create_timer(espera, true, false, true).timeout
		if not is_active:
			break

		if randf() < factor * 0.5:
			_flicker_zona_real()
		if randf() < factor * 0.45:
			_aparecer_zona_fantasma()
		if randf() < factor * 0.3:
			_telegrafiar_inversion()


func _flicker_zona_real() -> void:
	var tween = create_tween()
	tween.tween_property(zona_exito_nodo, "modulate:a", 0.05, 0.15)
	tween.tween_property(zona_exito_nodo, "modulate:a", 1.0, 0.25)


func _aparecer_zona_fantasma() -> void:
	var start_deg = randf_range(0.0, 360.0)
	var size_deg = randf_range(8.0, 16.0)
	var entrada = {"start": start_deg, "end": start_deg + size_deg, "alpha": 0.0}
	_fantasmas.append(entrada)

	var tween = create_tween()
	tween.tween_method(
		func(v): entrada["alpha"] = v; queue_redraw(),
		0.0, 0.8, 0.2
	)
	tween.tween_interval(randf_range(0.3, 0.6))
	tween.tween_method(
		func(v): entrada["alpha"] = v; queue_redraw(),
		0.8, 0.0, 0.3
	)
	tween.tween_callback(func():
		_fantasmas.erase(entrada)
		queue_redraw()
	)


func _telegrafiar_inversion() -> void:
	if not is_active:
		return
	var aguja_grafico = $RuedaCompleta/AgujaPivot/AgujaGrafico
	var tween = create_tween()
	tween.tween_property(aguja_grafico, "modulate", Color(1, 0.3, 1), 0.12)
	tween.tween_property(aguja_grafico, "modulate", Color.WHITE, 0.12)

	await get_tree().create_timer(0.3, true, false, true).timeout
	if is_active:
		move_direction *= -1


# --- SISTEMA DE PARTÍCULAS EN CAPAS ---

func _curva_colapso() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(0.25, 0.85))
	c.add_point(Vector2(1.0, 0.0))
	return c


func _setup_capa(p: CPUParticles2D, lifetime: float, vel_min: float, vel_max: float,
		sphere_r: float, grav: Vector2, sc_min: float, sc_max: float) -> void:
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = lifetime
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = sphere_r
	p.initial_velocity_min = vel_min
	p.initial_velocity_max = vel_max
	p.gravity = grav
	p.scale_amount_min = sc_min
	p.scale_amount_max = sc_max

	p.direction = Vector2(0, -1)
	p.spread = 180.0

	p.damping_min = vel_min * 0.6
	p.damping_max = vel_max * 0.9

	p.angular_velocity_min = -720.0
	p.angular_velocity_max = 720.0

	p.scale_amount_curve = _curva_colapso()

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat


func _gradient(color: Color, alpha_max: float) -> Gradient:
	var g = Gradient.new()
	g.offsets = [0.0, 0.15, 1.0]
	g.colors = [
		Color(1.0, 1.0, 1.0, alpha_max),
		Color(color.r, color.g, color.b, alpha_max),
		Color(color.r, color.g, color.b, 0.0)
	]
	return g


func _initial_ramp(color: Color, alpha_max: float) -> Gradient:
	var g = Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, alpha_max * 0.35))
	g.set_color(1, Color(color.r, color.g, color.b, alpha_max))
	return g


func _crear_textura_estrella() -> ImageTexture:
	var tamano := 32
	var puntas := 4
	var img = Image.create(tamano, tamano, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var cx := tamano * 0.5
	var cy := tamano * 0.5
	var r_outer := tamano * 0.45
	var r_inner := r_outer * 0.18
	var paso := TAU / puntas
	for y in range(tamano):
		for x in range(tamano):
			var dx := float(x) - cx + 0.5
			var dy := float(y) - cy + 0.5
			var dist := sqrt(dx * dx + dy * dy)
			if dist > r_outer + 1.5:
				continue
			var angulo := atan2(dy, dx)
			var angulo_local := fmod(angulo + TAU * 100.0, paso)
			var t := 1.0 - absf(angulo_local / paso - 0.5) * 2.0
			var r_actual := lerpf(r_inner, r_outer, t)
			var edge_alpha := clampf(r_actual - dist + 1.0, 0.0, 1.0)
			if edge_alpha > 0.0:
				var center_glow := clampf(1.0 - (dist / r_outer) * 0.65, 0.35, 1.0)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, edge_alpha * center_glow))
	return ImageTexture.create_from_image(img)


func _crear_capas_particulas() -> void:
	_p_main_hit = CPUParticles2D.new()
	$RuedaCompleta.add_child(_p_main_hit)
	_setup_capa(_p_main_hit, 0.45, 900.0, 1900.0, 40.0, Vector2(0, 300), 5.0, 9.0)

	_p_flare = CPUParticles2D.new()
	$RuedaCompleta.add_child(_p_flare)
	_setup_capa(_p_flare, 0.22, 2000.0, 3500.0, 20.0, Vector2.ZERO, 1.0, 5.0)

	_p_spread = CPUParticles2D.new()
	$RuedaCompleta.add_child(_p_spread)
	_setup_capa(_p_spread, 0.9, 150.0, 600.0, 150.0, Vector2(0, 125), 4.0, 8.0)
	_p_spread.explosiveness = 0.7

	_p_floating = CPUParticles2D.new()
	$RuedaCompleta.add_child(_p_floating)
	_setup_capa(_p_floating, 1.5, 75.0, 250.0, 100.0, Vector2(0, -250), 1.0, 2.0)
	_p_floating.explosiveness = 0.4
	_p_floating.damping_min = 20.0
	_p_floating.damping_max = 60.0

	var tex_estrella := _crear_textura_estrella()
	_p_main_hit.texture = tex_estrella
	_p_flare.texture    = tex_estrella
	_p_spread.texture   = tex_estrella
	_p_floating.texture = tex_estrella


func _disparar(p: CPUParticles2D, color: Color, cantidad: int, alpha: float = ALPHA_PARTICULAS) -> void:
	p.amount = cantidad
	p.color_ramp = _gradient(color, alpha)
	p.color_initial_ramp = _initial_ramp(color, alpha)
	p.emitting = true


func _disparar_retrasado(p: CPUParticles2D, color: Color, cantidad: int, delay: float, alpha: float = ALPHA_PARTICULAS) -> void:
	await get_tree().create_timer(delay).timeout
	_disparar(p, color, cantidad, alpha)


func _emitir_impacto(color: Color, tipo: String) -> void:
	var color_hdr = Color(color.r * 2.2, color.g * 2.2, color.b * 2.2, color.a)
	var color_flare = color.lerp(Color.WHITE, 0.6)
	color_flare = Color(color_flare.r * 3.0, color_flare.g * 3.0, color_flare.b * 3.0, 1.0)

	match tipo:
		"perfect":
			_disparar(_p_main_hit, color_hdr, 28)
			_disparar(_p_flare, color_flare, 10)
			_emitir_spikes(color, 8, 280.0, false)
			_disparar_retrasado(_p_spread, color_hdr, 16, 0.05)
			_disparar_retrasado(_p_floating, color, 9, 0.1, ALPHA_PARTICULAS * 0.6)
		"normal":
			_disparar(_p_main_hit, color_hdr, 16)
			_disparar(_p_flare, color_flare, 4)
			_emitir_spikes(color, 5, 180.0, false)
			_disparar_retrasado(_p_spread, color_hdr, 10, 0.05)
			_disparar_retrasado(_p_floating, color, 5, 0.08, ALPHA_PARTICULAS * 0.6)
		"rebote":
			_disparar(_p_flare, color_flare, 5, ALPHA_REBOTE)
			_emitir_spikes(color, 4, 90.0, false, 0.4)
		"fallo":
			_disparar(_p_main_hit, color_hdr, 12)
			_emitir_spikes(color, 6, 180.0, true)
			_disparar_retrasado(_p_spread, color, 8, 0.04)


# --- HITSTOP ---

func _hitstop(duracion: float, escala_tiempo: float = 0.05) -> void:
	Engine.time_scale = escala_tiempo
	await get_tree().create_timer(duracion, true, false, true).timeout
	Engine.time_scale = 1.0


# --- SPIKY SHAPES + ZONAS FANTASMA (dibujados en _draw) ---

func _emitir_spikes(color: Color, cantidad: int, largo_max: float, aleatorio: bool, alpha_max: float = 1.0) -> void:
	_spikes.clear()
	for i in range(cantidad):
		var angulo_base = (TAU / cantidad) * i
		var angulo = angulo_base + randf_range(-0.26, 0.26)
		var largo = largo_max if not aleatorio else randf_range(largo_max * 0.4, largo_max)
		_spikes.append({
			"angle": angulo,
			"length": 0.0,
			"length_max": largo,
			"alpha": alpha_max,
			"color": color
		})

	var tween = create_tween()
	tween.tween_method(
		func(t: float) -> void:
			for s in _spikes:
				s["length"] = s["length_max"] * t
			queue_redraw(),
		0.0, 1.0, 0.12
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(v: float) -> void:
			for s in _spikes:
				s["alpha"] = v * alpha_max
			queue_redraw(),
		1.0, 0.0, 0.35
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		_spikes.clear()
		queue_redraw()
	)


func _draw() -> void:
	for s in _spikes:
		if s["alpha"] <= 0.01:
			continue
		var dir = Vector2(cos(s["angle"]), sin(s["angle"]))
		var fin = dir * s["length"]
		var c = Color(s["color"].r, s["color"].g, s["color"].b, s["alpha"])
		var c_dim = Color(s["color"].r, s["color"].g, s["color"].b, s["alpha"] * 0.35)
		draw_line(Vector2.ZERO, fin, c, 3.0, true)
		var perp = Vector2(-dir.y, dir.x)
		draw_line(fin * 0.65 + perp * 12.0, fin, c_dim, 1.5, true)
		draw_line(fin * 0.65 - perp * 12.0, fin, c_dim, 1.5, true)

	for f in _fantasmas:
		if f["alpha"] <= 0.01:
			continue
		var col = Color(COLOR_FANTASMA.r, COLOR_FANTASMA.g, COLOR_FANTASMA.b, f["alpha"] * 0.7)
		draw_arc(Vector2.ZERO, radio_decoy, deg_to_rad(f["start"]), deg_to_rad(f["end"]), 16, col, 8.0, true)


# --- ENTRADA / SALIDA CON VIDA ---

func start_check():
	is_active = true
	_uso_doble_oportunidad = false
	current_rotation = 0.0
	move_direction = 1
	aguja_pivot.rotation_degrees = 0.0
	zonas.clear()
	_fantasmas.clear()

	limite_fallo_superior = 720.0
	limite_fallo_inferior = -10.0

	var cordura = EstadoManager.obtener_nivel("cordura")
	var factor_dificultad = 1.0 - (cordura / float(EstadoManager.NIVEL_MAXIMO))
	factor_dificultad = clamp(factor_dificultad, 0.0, 0.85)

	rotation_speed = rotation_speed_base + (factor_dificultad * 250.0)

	var normal_start = randf_range(60.0, 230.0)
	var normal_size = lerp(45.0, 25.0, factor_dificultad)
	zonas.append({
		"tipo": "normal",
		"start": normal_start,
		"end": normal_start + normal_size,
		"color": Color(1, 1, 1, 0.6)
	})

	var perfect_size = lerp(12.0, 6.0, factor_dificultad)
	var perfect_start = normal_start + normal_size
	zonas.append({
		"tipo": "perfect",
		"start": perfect_start,
		"end": perfect_start + perfect_size,
		"color": Color(0, 1, 0, 0.8)
	})

	if randf() < 0.3:
		var rebote_size = randf_range(8.0, 25.0)
		var rebote_start = randf_range(15.0, normal_start - rebote_size - 10.0)
		zonas.append({
			"tipo": "rebote",
			"start": rebote_start,
			"end": rebote_start + rebote_size,
			"color": Color(1, 0.8, 0, 0.8)
		})

	zona_exito_nodo.queue_redraw()
	show()

	var tween_entrada = create_tween().set_parallel(true)
	tween_entrada.tween_property(self, "scale", ESCALA_OBJETIVO, 0.3).set_trans(Tween.TRANS_BACK)
	tween_entrada.tween_property(self, "modulate:a", 1.0, 0.25)
	await tween_entrada.finished

	_aplicar_vinculacion_cordura(factor_dificultad)
	_loop_efectos_paranormales(factor_dificultad)

	set_process(true)


func _salir_con_fade() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", ESCALA_OBJETIVO * 0.8, 0.25).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	hide()


func _process(delta):
	if not is_active: return

	current_rotation += rotation_speed * move_direction * delta
	aguja_pivot.rotation_degrees = current_rotation

	if _jitter_amplitud > 0.0:
		$RuedaCompleta.position = Vector2(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)
		) * _jitter_amplitud

	if current_rotation >= limite_fallo_superior or current_rotation <= limite_fallo_inferior:
		fail()


func _input(event):
	if not is_active: return

	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		check_input()


func check_input():
	var angle = fmod(current_rotation, 360.0)

	if angle < 0:
		angle += 360.0

	var zona_tocada = null

	for i in range(zonas.size() - 1, -1, -1):
		var z = zonas[i]
		if angle >= z["start"] and angle <= z["end"]:
			zona_tocada = z["tipo"]
			if zona_tocada == "rebote":
				zonas.remove_at(i)
				zona_exito_nodo.queue_redraw()
			break

	match zona_tocada:
		"perfect":
			await _hitstop(0.09, 0.04)
			_emitir_impacto(Color(0.3, 1, 0.4), "perfect")
			_mostrar_ripples_perfect()
			_pulso_rueda()
			_flash_zona_perfect()
			end_minigame(Color.GREEN)
			check_finished.emit(true, "perfect")
		"normal":
			await _hitstop(0.04, 0.15)
			_emitir_impacto(Color.WHITE, "normal")
			_mostrar_ripple(Color.WHITE, 80.0)
			_mostrar_ripple(Color(1, 1, 1, 0.5), 120.0)
			_pulso_rueda()
			end_minigame(Color.WHITE)
			check_finished.emit(true, "normal")
		"rebote":
			_emitir_impacto(Color(1, 0.8, 0), "rebote")
			_mostrar_ripple(Color(1, 0.8, 0, 0.35), 90.0)
			rebote_alcanzado.emit()
			move_direction *= -1
			limite_fallo_inferior = current_rotation - 720.0
		_:
			fail()


# --- FEEDBACK VISUAL ---

func _mostrar_ripple(color: Color, radio_final: float) -> void:
	var ripple = RIPPLE_SCENE.instantiate()
	add_child(ripple)
	ripple.position = Vector2.ZERO
	ripple.configurar(color, radio_final, 0.5, 5.0)


func _mostrar_ripples_perfect() -> void:
	_mostrar_ripple(Color(0.3, 1, 0.4), 90.0)
	await get_tree().create_timer(0.1).timeout
	_mostrar_ripple(Color(0.3, 1, 0.4, 0.7), 140.0)
	await get_tree().create_timer(0.1).timeout
	_mostrar_ripple(Color(0.3, 1, 0.4, 0.4), 190.0)


func _pulso_rueda() -> void:
	var tween = create_tween()
	tween.tween_property($RuedaCompleta, "scale", Vector2(1.15, 1.15), 0.1).set_trans(Tween.TRANS_QUAD)
	tween.tween_property($RuedaCompleta, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC)


func _flash_zona_perfect() -> void:
	zona_exito_nodo.modulate = Color(2.0, 2.5, 2.0, 1.0)
	var tween = create_tween()
	tween.tween_property(zona_exito_nodo, "modulate", Color.WHITE, 0.4).set_trans(Tween.TRANS_CUBIC)


func fail():
	if RelicManager.tiene("doble_oportunidad") and not _uso_doble_oportunidad:
		_uso_doble_oportunidad = true
		print("¡Doble Oportunidad activada! Intento adicional")
		_reintentar_con_penalizacion()
		return

	_emitir_impacto(Color(1, 0.2, 0.2), "fallo")
	_mostrar_ripple(Color(1, 0.2, 0.2), 90.0)
	_shake_fallo()
	end_minigame(Color.RED)
	check_finished.emit(false, "fallo")


func _shake_fallo() -> void:
	var pos_original = position
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(self, "position", pos_original + Vector2(randf_range(-8, 8), randf_range(-8, 8)), 0.04)
	tween.tween_property(self, "position", pos_original, 0.04)


func _reintentar_con_penalizacion() -> void:
	current_rotation = 0.0
	move_direction = 1
	aguja_pivot.rotation_degrees = 0.0
	rotation_speed *= 0.7
	limite_fallo_superior = 720.0
	limite_fallo_inferior = -10.0

	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = Color.ORANGE
	await get_tree().create_timer(0.3).timeout
	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = Color.WHITE

	set_process(true)


func end_minigame(aguja_color: Color):
	is_active = false
	set_process(false)
	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = aguja_color
	await get_tree().create_timer(0.4).timeout
	$RuedaCompleta/AgujaPivot/AgujaGrafico.modulate = Color.WHITE
	_restaurar_vinculacion_cordura()
	await _salir_con_fade()


# Prueba con F
func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_F and event.pressed and not event.echo:
		if not is_active:
			start_check()

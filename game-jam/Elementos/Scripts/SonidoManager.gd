# SonidoManager.gd
# Abre res://Escenas/SonidoManager.tscn para asignar los AudioStream en el inspector.
extends Node

@onready var _jugador_ataca:         AudioStreamPlayer = $JugadorAtaca
@onready var _jugador_defiende:      AudioStreamPlayer = $JugadorDefiende
@onready var _jugador_cura_vida:     AudioStreamPlayer = $JugadorCuraVida
@onready var _jugador_pierde_vida:   AudioStreamPlayer = $JugadorPierdeVida
@onready var _jugador_gana_cordura:  AudioStreamPlayer = $JugadorGanaCordura
@onready var _jugador_pierde_cordura:AudioStreamPlayer = $JugadorPierdeCordura
@onready var _estado_aplicado:       AudioStreamPlayer = $EstadoAplicado
@onready var _enemigo_recibe_danio:  AudioStreamPlayer = $EnemigoRecibeDanio
@onready var _enemigo_muere:         AudioStreamPlayer = $EnemigoMuere
@onready var _enemigo_ataca:         AudioStreamPlayer = $EnemigoAtaca
@onready var _enemigo_defiende:      AudioStreamPlayer = $EnemigoDefiende
@onready var _enemigo_aplica_estado: AudioStreamPlayer = $EnemigoAplicaEstado
@onready var _panico:                AudioStreamPlayer = $Panico

var _cordura_previa: int = 10


func _ready() -> void:
	_cordura_previa = EstadoManager.obtener_nivel("cordura")

	VidaManager.dano_recibido.connect(_on_dano_recibido)
	VidaManager.curacion_recibida.connect(_on_curacion)
	EstadoManager.estado_cambiado.connect(_on_estado_cambiado)
	EstadoManager.panico_activado.connect(_on_panico)


# --- Llamadas directas desde CartaEjecutor y Enemigo ---

func jugador_ataca() -> void:
	_play(_jugador_ataca)

func jugador_defiende() -> void:
	_play(_jugador_defiende)

func enemigo_ataca() -> void:
	_play(_enemigo_ataca)

func enemigo_defiende() -> void:
	_play(_enemigo_defiende)

func enemigo_aplica_estado() -> void:
	_play(_enemigo_aplica_estado)

func enemigo_recibe_danio() -> void:
	_play(_enemigo_recibe_danio)

func enemigo_muere() -> void:
	_play(_enemigo_muere)


# --- Conectados a señales ---

func _on_dano_recibido(_cantidad: int, fuente: String) -> void:
	if fuente != "costo_carta":
		_play(_jugador_pierde_vida)


func _on_curacion(_cantidad: int) -> void:
	_play(_jugador_cura_vida)


func _on_estado_cambiado(nombre: String, nivel: int, _max: int) -> void:
	if nombre == "cordura":
		if nivel > _cordura_previa:
			_play(_jugador_gana_cordura)
		elif nivel < _cordura_previa:
			_play(_jugador_pierde_cordura)
		_cordura_previa = nivel
	else:
		_play(_estado_aplicado)


func _on_panico() -> void:
	_play(_panico)


func _play(player: AudioStreamPlayer) -> void:
	if player == null or player.stream == null:
		return
	player.play()

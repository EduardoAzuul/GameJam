extends Area2D
class_name Enemy

# Tipos de acciones que puede hacer el enemigo
enum Intent {ATTACK, DEFEND, APPLY_STATUS}

# Estadísticas base
var max_hp: int = 40
var current_hp: int = 40
var block: int = 0
var current_intent: Intent
var intent_value: int = 0 # Cuánto daño hará o cuánto escudo ganará

# Referencias a la UI
@onready var hp_label = $UI/HPLabel
@onready var intent_label = $UI/IntentLabel

func _ready():
	current_hp = max_hp
	decide_next_turn()
	update_ui()

# --- CICLO DEL TURNO ---

# 1. Se llama en cuanto empieza el turno del jugador (para que vea qué le espera)
func decide_next_turn():
	# Aquí puedes hacer una IA compleja, un patrón cíclico o aleatorio.
	# Por ahora, es aleatorio simple:
	current_intent = Intent.values()[randi() % Intent.size()]
	
	match current_intent:
		Intent.ATTACK:
			intent_value = 8 # Daño que hará
		Intent.DEFEND:
			intent_value = 5 # Escudo que ganará
		Intent.APPLY_STATUS:
			intent_value = 1 # Ej: 1 de Hambre o 1 de daño a Cordura
			
	update_ui()

# 2. Se llama cuando el jugador presiona el botón "Terminar Turno"
func execute_turn():
	# El bloqueo del enemigo dura solo un turno, se resetea antes de actuar
	block = 0 
	
	match current_intent:
		Intent.ATTACK:
			# Aquí te conectarás a tu Autoload/Singleton
			# Ejemplo: VidaManager.take_damage(intent_value)
			print("Enemigo ataca por ", intent_value)
			
		Intent.DEFEND:
			block += intent_value
			print("Enemigo se defiende. Gana ", intent_value, " de escudo")
			
		Intent.APPLY_STATUS:
			# Ejemplo: EstadoManager.add_hambre(intent_value)
			print("Enemigo aplica estado")

	# Al terminar de actuar, decide su siguiente movimiento para el nuevo turno
	decide_next_turn()
	update_ui()


# --- INTERACCIÓN CON CARTAS ---

# Se llama cuando el jugador juega una carta de daño contra este enemigo
func take_damage(amount: int):
	# El escudo absorbe el daño primero
	var damage_taken = max(amount - block, 0)
	block = max(block - amount, 0)
	
	current_hp -= damage_taken
	update_ui()
	
	if current_hp <= 0:
		die()

func die():
	print("Enemigo derrotado")
	queue_free() # Elimina el nodo de la memoria

func update_ui():
	hp_label.text = "HP: %d/%d | Escudo: %d" % [current_hp, max_hp, block]
	
	match current_intent:
		Intent.ATTACK:
			intent_label.text = "Atacará (%d)" % intent_value
		Intent.DEFEND:
			intent_label.text = "Defenderá (%d)" % intent_value
		Intent.APPLY_STATUS:
			intent_label.text = "Aplicará Estado"

extends Node2D

# Puedes modificar estos valores desde el Inspector para que la barra 
# encaje perfectamente sobre tu dibujo de la cadena.
@export var radio_barra: float = 300.0 
@export var grosor_barra: float = 60.0

@onready var main_script = get_parent().get_parent() 

func _draw():
	# Recorremos todas las zonas creadas en el script principal
	for zona in main_script.zonas:
		var start_rad = deg_to_rad(zona["start"] - 90)
		var end_rad = deg_to_rad(zona["end"] - 90)
		
		# draw_arc(centro, radio, angulo_inicio, angulo_fin, puntos_resolucion, color, grosor, antialiasing)
		draw_arc(Vector2.ZERO, radio_barra, start_rad, end_rad, 32, zona["color"], grosor_barra, true)

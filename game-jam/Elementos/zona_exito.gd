extends Node2D

# Referencia al script principal para leer los ángulos
@onready var main_script = get_parent().get_parent() 

func _draw():
	# Si no hay datos, no dibujamos
	if main_script.target_angle_end == 0: return
	
	var centro = Vector2.ZERO
	var radio = 100 # Ajusta según el tamaño de tu Sprite de base
	
	# Godot usa radianes para dibujar, convertimos los grados del script principal
	var start_rad = deg_to_rad(main_script.target_angle_start - 90) # -90 para que 0 sea arriba
	var end_rad = deg_to_rad(main_script.target_angle_end - 90)
	
	# Color de zona de éxito normal (verde o blanco)
	var color_exito = Color(1, 1, 1, 0.5) # Blanco semitransparente
	
	# Dibujar el arco relleno
	draw_arc_poly(centro, radio, start_rad, end_rad, color_exito)

# Función auxiliar para dibujar un arco relleno (tipo porción de tarta)
func draw_arc_poly(center, radius, angle_from, angle_to, color):
	var nb_points = 32 # Suavizado del círculo
	var points_arc = PackedVector2Array()
	points_arc.push_back(center) # El centro es el primer punto
	
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	
	draw_polygon(points_arc, PackedColorArray([color]))

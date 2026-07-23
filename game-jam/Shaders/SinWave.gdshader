shader_type canvas_item;

uniform float amplitud : hint_range(0.0, 0.05) = 0.01;
uniform float frecuencia : hint_range(1.0, 20.0) = 8.0;
uniform float velocidad : hint_range(0.0, 10.0) = 2.0;
uniform float intensidad : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float onda = sin(UV.y * frecuencia + TIME * velocidad) * amplitud * intensidad;
	vec2 uv_distorsionada = UV + vec2(onda, 0.0);
	vec4 tex_color = texture(TEXTURE, uv_distorsionada);
	COLOR = tex_color * COLOR;   
}
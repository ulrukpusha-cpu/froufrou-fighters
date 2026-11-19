shader_type canvas_item;
// Recoloration des sprites de combattant.
// Les sprites encodent leurs zones par canal : R = tenue, G = peau, B = accessoires
// (une valeur plus sombre = membre à l'arrière-plan). Le noir reste noir (contours).
// flash_amount (0..1) blanchit le sprite lors d'un impact (animé par AnimationPlayer).

uniform vec4 outfit_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform vec4 skin_color : source_color = vec4(0.42, 0.26, 0.15, 1.0);
uniform vec4 accent_color : source_color = vec4(0.95, 0.76, 0.19, 1.0);
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

varying vec4 vertex_modulate;

void vertex() {
	vertex_modulate = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 rgb = tex.r * outfit_color.rgb + tex.g * skin_color.rgb + tex.b * accent_color.rgb;
	rgb = mix(rgb, flash_color.rgb, flash_amount);
	COLOR = vec4(rgb, tex.a) * vertex_modulate;
}

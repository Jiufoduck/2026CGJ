shader_type canvas_item;
render_mode world_vertex_coords;

uniform vec4 base_color : source_color = vec4(0.92, 0.92, 0.88, 1.0);
uniform vec4 line_color : source_color = vec4(0.65, 0.66, 0.62, 1.0);
uniform float cell_size = 24.0;
uniform float line_width = 1.4;

varying vec2 world_position;

void vertex() {
	world_position = VERTEX;
}

void fragment() {
	vec2 grid_position = abs(fract(world_position / cell_size) - 0.5) * cell_size;
	float grid_line = step(min(grid_position.x, grid_position.y), line_width);
	COLOR = mix(base_color, line_color, grid_line);
}

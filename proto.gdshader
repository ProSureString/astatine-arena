shader_type canvas_item;

uniform float scanline_count : hint_range(0, 1080) = 180.0;
uniform float scanline_opacity : hint_range(0, 1) = 0.4;
uniform vec2 screen_size = vec2(320.0, 240.0);
uniform bool enable_curved_screen = true;
uniform float curvature = 4.0;

vec2 curve(vec2 uv) {
	if (!enable_curved_screen) {
		return uv;
	}
	uv = uv * 2.0 - 1.0;
	vec2 offset = abs(uv.yx) / vec2(curvature, curvature);
	uv = uv + uv * offset * offset;
	uv = uv * 0.5 + 0.5;
	return uv;
}

void fragment() {
	// Apply screen curvature
	vec2 curved_uv = curve(UV);
	if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	}
	
	// Sample the screen texture
	vec4 color = texture(TEXTURE, curved_uv);
	
	// Apply scanlines
	float scanline = sin(curved_uv.y * scanline_count * PI * 2.0);
	scanline = (scanline * 0.5 + 0.5) * 0.9 + 0.1;
	color.rgb *= mix(1.0, scanline, scanline_opacity);
	
	// Apply RGB separation (chromatic aberration)
	float aberration = 0.01;
	color.r = texture(TEXTURE, curved_uv + vec2(aberration, 0.0)).r;
	color.b = texture(TEXTURE, curved_uv - vec2(aberration, 0.0)).b;
	
	COLOR = color;
}

shader_type canvas_item;
render_mode unshaded;
uniform vec2 ember_uv = vec2(0.5,0.5);
uniform float ember_radius = 230.0;
uniform float weakness = 0.0;
uniform float threat = 0.0;
uniform float beat = 0.0;
uniform float freeze = 0.0;
uniform float transition = 0.0;
void fragment() {
	vec2 px = (UV-ember_uv)*vec2(1280.0,720.0);
	float distance_to_ember = length(px);
	float outside = smoothstep(ember_radius*0.48,ember_radius*1.35,distance_to_ember);
	vec2 edge = abs(UV-vec2(0.5))*2.0;
	float vignette = smoothstep(0.55,1.15,length(edge*vec2(0.78,0.62)));
	float alpha = outside*(0.12+weakness*0.15)+vignette*(0.12+threat*0.14);
	vec3 ink = mix(vec3(0.018,0.027,0.075),vec3(0.25,0.012,0.052),threat*vignette*(0.4+beat*0.25));
	ink = mix(ink,vec3(0.06,0.19,0.25),freeze*0.2);
	alpha = mix(alpha,1.0,transition);
	COLOR = vec4(ink,alpha);
}

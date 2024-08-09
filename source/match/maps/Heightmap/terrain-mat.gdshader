shader_type spatial;

uniform sampler2D _a;
uniform sampler2D heightmap;
uniform float height_ratio = 1.0;
uniform float height_offset = 0.0;
uniform float max_height = 50.0;

uniform ivec2 src_size = ivec2(300,300);

uniform float gsize = 0.5;//size of the grid
uniform float gwidth = 2;//grid lines'width in pixelsvarying 
varying vec3 P;

void fragment() {
	//ALBEDO = texture(_a, UV*tiles).rgb;
	//vec3 f  = fract (pos * 1.0);
	//vec3 df = fwidth(pos * 1.0);
	//vec3 g = smoothstep(df * 1.0, df * 2.0, f);
	//float c = g.x * g.y * g.z;
	//ALBEDO = vec3(c, c, c);
	
	

		
	vec3 f  = abs(fract (P * gsize)-0.5);
	vec3 df = fwidth(P * gsize);
	float mi=max(0.0,gwidth-1.0), ma=max(1.0,gwidth);//should be uniforms
	vec3 g=clamp((f-df*mi)/(df*(ma-mi)),max(0.0,1.0-gwidth),1.0);//max(0.0,1.0-gwidth) should also be sent as uniform
	float c = g.x * g.y * g.z;
	
	float relHeight = clamp((P.y+height_offset)/max_height, 0.1, 0.9);
	//int gradMax = textureSize(_a, 0).x;
	//int gradPos = gradMax/2;//clamp(relHeight * float(gradMax), 0., float(gradMax));
	
	ALBEDO = mix(vec3(c, c, c), texture(_a, vec2(relHeight,0)).rgb, length(c));
	//ALBEDO = vec3(c, c, c);
	//ALBEDO = texture(_a, vec2(relHeight,0)).rgb;
}

void vertex() {
	//ivec2 pixel = ivec2(UV * vec2(src_size));
	
	//VERTEX.y += texelFetch(heightmap, pixel, 0).r;
	//VERTEX.y -= texelFetch ( heightmap, UV*src_size, 0 ).r/100.0;
	//VERTEX.y -= texture(heightmap, UV).r/100.0;// * height_ratio;
	P=VERTEX+NODE_POSITION_WORLD;
	
	//vec2 e = vec2(0.01, 0.0);
	//vec3 normal = normalize(vec3(texture(heightmap, VERTEX.xz - e).r - texture(heightmap, VERTEX.xz + e).r, 2.0 * e.x, texture(heightmap, VERTEX.xz - e.yx).r - texture(heightmap, VERTEX.xz + e.yx).r));
	//NORMAL = normal;
}
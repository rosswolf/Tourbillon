shader_type canvas_item;


uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Three color layers
uniform vec4 color1: source_color = vec4(0.,0.5,1.0,1.0);
uniform vec4 color2: source_color = vec4(0.2,0.8,0.9,0.5);
uniform vec4 color3: source_color = vec4(0.5,0.3,1.0,0.3);

uniform float frequency : hint_range(0., 1000. , 1.) = 3.;
uniform float compress : hint_range(1., 2. , 0.01) = 1.;
uniform float add_light : hint_range(0., 2. , 0.01) = 0.;

uniform float scale : hint_range(0., 2. , 0.01) = 1.;
uniform float speed : hint_range(-1000., 1000. , 0.01) = 1.;

// Separate angles for each layer
uniform float x_angle1: hint_range(-1.57, 1.57, 0.01) = 1.57;
uniform float y_angle1: hint_range(-1.57, 1.57, 0.01) = 1.57;
uniform float x_angle2: hint_range(-1.57, 1.57, 0.01) = 1.0;
uniform float y_angle2: hint_range(-1.57, 1.57, 0.01) = 1.0;
uniform float x_angle3: hint_range(-1.57, 1.57, 0.01) = 0.5;
uniform float y_angle3: hint_range(-1.57, 1.57, 0.01) = 0.5;

uniform float base_alpha : hint_range(-2., 2. , 0.01) = 0.8;
uniform float refraction_ratio: hint_range(-100, 100, 0.01) = 10.;//0.2;
uniform float clear : hint_range(0., 1. , 0.01) = 0.;

uniform float surf_sinpowder : hint_range(0., 8. , 1.) = 8.;
uniform float surf_speed : hint_range(-10., 10. , 0.01) = 1.;
uniform float surf_angle : hint_range(-1.57, 1.57, 0.01) = 1.57;
uniform float surf_magnitude : hint_range(0., 10. , 0.01) = 0.;

uniform float s11: hint_range(-10, 10, 0.01) = 2.221;
uniform float sinpowder : hint_range(0., 8. , 1.) = 8.;

// Layer offset speeds (to make layers move differently)
uniform float layer2_speed_offset: hint_range(-2., 2., 0.01) = 0.3;
uniform float layer3_speed_offset: hint_range(-2., 2., 0.01) = -0.2;

// Layer scales (to vary wave sizes)
uniform float layer2_scale: hint_range(0.5, 2., 0.01) = 1.2;
uniform float layer3_scale: hint_range(0.5, 2., 0.01) = 0.8;

vec2 UVtoSreenUV(vec2 uv, bool is_camera_center, vec2 texture_pixel_size, vec2 screen_pixel_size, vec4 fragcoord) {

	vec2 suv = (uv - 0.5)*2.;

	if (is_camera_center) {

		return (fragcoord.xy + suv*0.01/texture_pixel_size)*screen_pixel_size*0.5;
	} else {

		return (fragcoord.xy + suv*0.01/texture_pixel_size)*screen_pixel_size;
	}
}

vec2 shiftuv2(vec2 uv, float shiftratio) {

	vec2 suv = (uv - 0.5)*2.;

	return (suv + suv*-1.*shiftratio)*0.5 + 0.5;
}

float yget(float x,float fc1,float fc2,float fc3,float fc4,float tc1,float tc2,float tc3,float tc4,float amc1,float amc2,float amc3,float amc4,float way,float addt, float speed_mult) {

	float t = speed*speed_mult*TIME*way + addt;
	float y = sin(x * frequency);

	y += pow(abs(sin(x*frequency*fc1 + t*tc1)),sinpowder)*amc1;
	y += pow(abs(sin(x*frequency*fc2 + t*tc2)),sinpowder)*amc2;
	y += pow(abs(sin(x*frequency*fc3 + t*tc3)),sinpowder)*amc3;
	y += pow(abs(sin(x*frequency*fc4 + t*tc4)),sinpowder)*amc4;
	y /= (amc1+amc2+amc3+amc4);

	return y;
}

vec4 calculateLayer(vec2 uv_coord, float scale_mult, float speed_mult, float x_angle, float y_angle, vec4 layer_color, vec4 fragcoord, vec2 texture_pixel_size, vec2 screen_pixel_size) {

	vec2 st = (uv_coord-0.5)*2.*scale*scale_mult;

	float dl = distance(vec2(0.), vec2(dFdx(st.x), dFdy(st.y)));

	vec2 st2 = ((uv_coord-0.5)*2. + dl)*scale*scale_mult;

	float x = st.x;
	float y = st.y;

	float adda = pow(abs(sin(surf_speed*TIME*scale*scale_mult + x*sin(surf_angle) + y*cos(surf_angle))),surf_sinpowder)*surf_magnitude;

	st.x += adda*cos(surf_angle);
	st.y += adda*sin(surf_angle);

	// Wave calculations with speed multiplier
 	float a1 = (yget(distance(vec2(0.5,3.5),st),1.32,1.72,s11,3.1122,1.,1.121,0.437,4.269,4.5,4.,5.,2.5,-1.,0., speed_mult)
	+ yget(distance(vec2(4.5,-4.5),st),1.31,1.72,s11,3.1122,1.,1.121,0.437,4.269,4.5,4.,5.,2.5,1.,0., speed_mult)
	+ yget(distance(vec2(-5.5,-2.5),st),1.27,1.72,s11,3.1122,1.,1.121,0.437,5.,4.5,4.,5.,2.5,-1.,0., speed_mult)
	+ yget(distance(vec2(-7.5,3.5),st),1.25,1.72,s11,3.1122,1.,1.121,0.437,5.,4.5,4.,5.,2.5,1.,0., speed_mult)
	+ yget(distance(vec2(3.25,3.25),st),1.34,1.72,s11,3.1122,1.,1.121,0.437,4.269,4.5,4.,5.,2.5,1.,0., speed_mult)
	+ yget(distance(vec2(6.25,-4.25),st),1.36,1.72,s11,3.1122,1.,1.121,0.437,4.269,4.5,4.,5.,2.5,-1.,0., speed_mult)
	+ yget(distance(vec2(-7.25,-1.25),st),1.27,1.72,s11,3.1122,1.,1.121,0.437,5.,4.5,4.,5.,2.5,1.,0., speed_mult)
	+ yget(distance(vec2(-0.25,5.25),st),1.59,1.72,s11,3.1122,1.,1.121,0.437,5.,4.5,4.,5.,2.5,-1.,0., speed_mult))/8.;

 	float a2 = (yget(distance(vec2(0.5,3.5),st2),1.32,1.72,s11,3.1122,1.,1.121,0.437,4.269,4.5,4.,5.,2.5,-1.,0., speed_mult)
	+ yget(distance(vec2(4.5,-4.5),st2),1.31,1.72,s11,3.1122,1.,1.121,0.437,4.269,4.5,4.,5.,2.5,1.,0., speed_mult)
	+ yget(distance(vec2(-5.5,-2.5),st2),1.27,1.72,s11,3.1122,1.,1.121,0.437,5.,4.5,4.,5.,2.5,-1.,0., speed_mult)
	+ yget(distance(vec2(-7.5,3.5),st2),1.25,1.72,s11,3.1122,1.,1.121,0.437,5.,4.5,4.,5.,2.5,1.,0., speed_mult)
	+ yget(distance(vec2(3.25,3.25),st2),1.34,1.72,s11,3.1122,1.,1.121,0.437,4.269,4.5,4.,5.,2.5,1.,0., speed_mult)
	+ yget(distance(vec2(6.25,-4.25),st2),1.36,1.72,s11,3.1122,1.,1.121,0.437,4.269,4.5,4.,5.,2.5,-1.,0., speed_mult)
	+ yget(distance(vec2(-7.25,-1.25),st2),1.27,1.72,s11,3.1122,1.,1.121,0.437,5.,4.5,4.,5.,2.5,1.,0., speed_mult)
	+ yget(distance(vec2(-0.25,5.25),st2),1.59,1.72,s11,3.1122,1.,1.121,0.437,5.,4.5,4.,5.,2.5,-1.,0., speed_mult))/8.;

	float da = clamp((a2 - a1)*compress, 0., 1.);
	float ang = atan(da/dl);

	vec2 rUV = uv_coord;
	rUV.y = (1. - rUV.y) + fragcoord.y*screen_pixel_size.y;
	vec4 bC = textureLod(screen_texture, UVtoSreenUV(shiftuv2(uv_coord, ang*refraction_ratio), false, texture_pixel_size, screen_pixel_size, fragcoord), 0.0);

	float a = ((sin(ang - PI*0.5 + y_angle) + cos(ang - PI*1.5 + x_angle)) + adda)/1.5;

	vec4 result = layer_color;
	result.a = clamp(base_alpha + a, 0., 1.) * layer_color.a; // Multiply by input alpha for layering
	result.rgb = clamp(layer_color.rgb + mix(vec3(result.a), bC.rgb, clear)*vec3(1. + add_light), vec3(0.), vec3(1.));

	return result;
}

void fragment(){
	// Calculate each layer
	vec4 layer1 = calculateLayer(UV, 1.0, 1.0, x_angle1, y_angle1, color1, FRAGCOORD, TEXTURE_PIXEL_SIZE, SCREEN_PIXEL_SIZE);
	vec4 layer2 = calculateLayer(UV, layer2_scale, 1.0 + layer2_speed_offset, x_angle2, y_angle2, color2, FRAGCOORD, TEXTURE_PIXEL_SIZE, SCREEN_PIXEL_SIZE);
	vec4 layer3 = calculateLayer(UV, layer3_scale, 1.0 + layer3_speed_offset, x_angle3, y_angle3, color3, FRAGCOORD, TEXTURE_PIXEL_SIZE, SCREEN_PIXEL_SIZE);

	// Additive blending - waves intensify when overlapping
	COLOR.rgb = layer1.rgb * layer1.a;
	COLOR.rgb += layer2.rgb * layer2.a;
	COLOR.rgb += layer3.rgb * layer3.a;

	// Add alphas together for combined intensity, clamped to 1.0
	COLOR.a = clamp(layer1.a + layer2.a + layer3.a, 0.0, 1.0);

	// Clamp final color to prevent overflow
	COLOR.rgb = clamp(COLOR.rgb, vec3(0.0), vec3(1.0));
}
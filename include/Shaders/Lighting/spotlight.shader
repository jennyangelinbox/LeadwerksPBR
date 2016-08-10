SHADER version 1
@OpenGL2.Vertex
#version 400

uniform mat4 projectioncameramatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec3 lightglobalposition;
uniform vec2 lightrange;
uniform vec2 lightconeangles;
uniform mat4 entitymatrix;

in vec3 vertex_position;

out vec4 vertexposition;

void main(void)
{
	gl_Position = projectioncameramatrix * entitymatrix * vec4(vertex_position,1.0);
	/*
	vec3 position = vertex_position;
	position.x *= lightrange.y * tan(lightconeangles[1]);
	position.y *= lightrange.y;
	position.z *= lightrange.y * tan(lightconeangles[1]);
	gl_Position = projectioncameramatrix * vec4(lightglobalposition + position,1.0);*/
}
@OpenGLES2.Vertex

@OpenGLES2.Fragment

@OpenGL4.Vertex
#version 400

uniform mat4 projectioncameramatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec3 lightglobalposition;
uniform vec2 lightrange;
uniform vec2 lightconeangles;
uniform mat4 entitymatrix;

in vec3 vertex_position;

out vec4 vertexposition;

void main(void)
{
	gl_Position = projectioncameramatrix * entitymatrix * vec4(vertex_position,1.0);
	/*
	vec3 position = vertex_position;
	position.x *= lightrange.y * tan(lightconeangles[1]);
	position.y *= lightrange.y;
	position.z *= lightrange.y * tan(lightconeangles[1]);
	gl_Position = projectioncameramatrix * vec4(lightglobalposition + position,1.0);*/
}
@OpenGL4.Fragment
#version 400
#ifndef SAMPLES
	#define SAMPLES 1
#endif
#define PI 3.14159265359
#define HALFPI PI/2.0
#define LOWERLIGHTTHRESHHOLD 0.001
#ifndef KERNEL
	#define KERNEL 3
#endif
#define KERNELF float(KERNEL)
#define GLOSS 10.0

#if SAMPLES==0
	uniform sampler2D texture0;
	uniform sampler2D texture1;
	uniform sampler2D texture2;
	uniform sampler2D texture3;
	uniform sampler2D texture4;
#else
	uniform sampler2DMS texture0;
	uniform sampler2DMS texture1;
	uniform sampler2DMS texture2;
	uniform sampler2DMS texture3;
	uniform sampler2DMS texture4;
#endif

uniform mat3 camerainversenormalmatrix;
uniform sampler2DShadow texture5;//shadowmap
uniform vec2 lightconeangles;
uniform vec2 lightconeanglescos;
uniform vec4 ambientlight;
uniform vec2 buffersize;

uniform vec3 lightposition;
uniform vec3 lightdirection;
uniform vec4 lightcolor;
uniform vec4 lightspecular;
uniform vec2 lightrange;

uniform vec2 camerarange;
uniform float camerazoom;
uniform float shadowmapsize;
uniform mat4 lightprojectioncamerainversematrix;
uniform mat3 lightnormalmatrix;
uniform vec2 lightshadowmapoffset;
uniform float shadowsoftness;
uniform bool isbackbuffer;

in vec4 vertexposition;

out vec4 fragData0;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float depthToPosition(in float depth, in vec2 depthrange)
{
	return depthrange.x / (depthrange.y - depth * (depthrange.y - depthrange.x)) * depthrange.y;
}

float positionToDepth(in float z, in vec2 depthrange) {
	return (depthrange.x / (z / depthrange.y) - depthrange.y) / -(depthrange.y - depthrange.x);
}

float shadowLookup(in sampler2DShadow shadowmap, in vec3 shadowcoord, in float offset)
{
	float f=0.0;
	const float cornerdamping = 0.7071067;
	int x,y;
	vec2 sampleoffset;
	
	for (x=0; x<KERNEL; ++x)
	{
		sampleoffset.x = float(x) - KERNELF*0.5 + 0.5;
		for (y=0; y<KERNEL; ++y)
		{
			sampleoffset.y = float(y) - KERNELF*0.5 + 0.5;
			f += texture(shadowmap,vec3(shadowcoord.x+x*offset,shadowcoord.y+y*offset,shadowcoord.z));
		}
	}
	return f/(KERNEL*KERNEL);
}

void main(void)
{
	vec3 flipcoord = vec3(1.0);	
	vec2 coord = gl_FragCoord.xy / buffersize;
	ivec2 icoord = ivec2(gl_FragCoord.xy);	
	
	if (!isbackbuffer) 
	{ 
		flipcoord.y = -1.0; 
	}
	else 
	{
		coord.y = 1.0 - coord.y;
		icoord.y = int(buffersize.y) - icoord.y;
	}
	
	float depth;		
	vec3 screencoord;
	vec3 screennormal;
	float attenuation;
	float distanceattenuation;
	int materialflags;
			
	float specular;
	float metalness;
	float gloss;
	float roughnessmip;
	float specular_power;
		
	vec3 normal;			
	vec4 albedo;
	vec4 normaldata;
	vec4 samplenormal;		
	vec4 surfacedata;
	vec4 specular_colour;
		
	float lightdistance;
	vec3 lightvector;
	vec3 lightnormal;
	vec4 PIlightcolor = lightcolor*PI; 
		
	vec4 sample_out;	
	fragData0 = vec4(0.0);
	
	for (int i=0; i<max(1,SAMPLES); i++)
	{
		//----------------------------------------------------------------------
		//Retrieve data from gbuffer
		//----------------------------------------------------------------------
#if SAMPLES==0
		float depth = 		texelFetch(texture0,icoord,i).x;
		vec4 diffuse = 		texelFetch(texture1,icoord,i);
		vec4 normaldata =	texelFetch(texture2,icoord,i);
		vec4 emission = 	texelFetch(texture3,icoord,i);
#else		
		float depth = 		texelFetch(texture0,icoord,i).x;
		vec4 diffuse = 		texelFetch(texture1,icoord,i);
		vec4 normaldata =	texelFetch(texture2,icoord,i);
		vec4 emission = 	texelFetch(texture3,icoord,i);
#endif
		
		#if SAMPLES==0
		depth = 		texture(texture0,coord).x;
		albedo = 		texture(texture1,coord);
		normaldata =	texture(texture2,coord);
		surfacedata = 	texture(texture3,coord);
#else
		depth = 		texelFetch(texture0,icoord,i).x;
		albedo = 		texelFetch(texture1,icoord,i);
		normaldata =	texelFetch(texture2,icoord,i);
		surfacedata = 	texelFetch(texture3,icoord,i);
#endif			
		materialflags = int(normaldata.a * 255.0 + 0.5);
		sample_out = 	albedo;
		
		screencoord = vec3(((gl_FragCoord.x/buffersize.x)-0.5) * 2.0 * (buffersize.x/buffersize.y),((-gl_FragCoord.y/buffersize.y)+0.5) * 2.0,depthToPosition(depth,camerarange));
		screencoord.x *= screencoord.z / camerazoom;
		screencoord.y *= -screencoord.z / camerazoom;		
		screennormal = normalize(screencoord) * flipcoord;		
		screencoord *= flipcoord;
		
		if ((1 & materialflags)!=0) // if use lighting
		{			
			normal = 	camerainversenormalmatrix * normalize(normaldata.xyz*2.0-1.0);	
			specular =	surfacedata.b;				
			gloss =		1 - surfacedata.r;
			metalness = 1 - surfacedata.g;
				
			specular_colour = mix(albedo, vec4(specular), metalness) * PIlightcolor;
		
			lightvector = (screencoord - lightposition);
			lightdistance = length(lightvector);	
			lightnormal = normalize(lightvector);
			
			// ATTENUATION			
			float n_dot_l = max(-dot(lightnormal, normal), 0.0);			
			attenuation = n_dot_l * (1 / lightdistance); // linear fall off, spot lights focus light 
			//TODO look into physically correct spotlight falloff, how does it change with spot angle?		
			attenuation *= min(1.0, lightrange.y-lightdistance); //not physically correct but needed for performance			
			
			float denom = lightconeanglescos.y-lightconeanglescos.x;			
			float anglecos = dot(lightnormal, lightdirection);
			
			if (denom>0.0)
			{					
				attenuation *= 1.0-clamp((lightconeanglescos.y-anglecos)/denom,0.0,1.0);
			}
			else
			{
		#if SAMPLES==1
				if (anglecos<lightconeanglescos.x) discard;
		#endif
			}
			
			// DIFFUSE					
			vec4 sample_diffuse = albedo*lightcolor*metalness;			

			// SPECULAR - GGX
			vec4 sample_specular = vec4(0.0);
			
			vec3 h_v = normalize( lightnormal + screennormal);	
			float h_dot_n = clamp(-dot(h_v, normal), 0.0, 1.0);	
			float n_dot_v = clamp(-dot(normal, screennormal), 0.0, 1.0);
			float h_dot_l = dot(h_v, screennormal);	
					
			float alpha = gloss*gloss+0.00001;			
			float _denom = h_dot_n * h_dot_n *(alpha-1.0) + 1.0f;
			float D = alpha/(PI * _denom * _denom);
				
			float exponent = pow((1.0f - h_dot_l), 5.0f);		
			vec4 F = specular_colour + ((1.0f - specular_colour) * exponent);	
			
			float k = 2.f/alpha;
			float G_l = n_dot_l * (1.0f - k) + k;
			float G_v = n_dot_v * (1.0f - k) + k;
			float V = 1.0f/ G_l*G_v;
			
			sample_specular = F * D * V;
		
	#ifdef USESHADOW
		
		//----------------------------------------------------------------------
		//Shadow lookup
		//----------------------------------------------------------------------
		vec3 shadowcoord = lightnormalmatrix * lightvector;
		shadowcoord.x /= -shadowcoord.z/0.5;
		shadowcoord.y /= shadowcoord.z/0.5;
		shadowcoord.x += 0.5;
		shadowcoord.y += 0.5;
		shadowcoord.z = positionToDepth(shadowcoord.z * lightshadowmapoffset.y - lightshadowmapoffset.x,lightrange);
		attenuation *= shadowLookup(texture5,shadowcoord,1.0/shadowmapsize);	
		#if SAMPLES==1
		if (attenuation<LOWERLIGHTTHRESHHOLD) discard;
		#endif	
	#endif
				
		fragData0 += ( sample_diffuse + sample_specular ) * attenuation;
		//Removes banding
		//fragData0 += rand(lightnormal.xy) * 0.04 - 0.02;
		}
	}
		
	fragData0 /= float(max(1,SAMPLES));
	fragData0 = max(fragData0,0.0);
}
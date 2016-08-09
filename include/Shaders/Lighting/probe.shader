SHADER version 1
@OpenGL2.Vertex
#version 400

uniform mat4 projectioncameramatrix;
uniform mat4 drawmatrix;
uniform vec2 offset;
uniform vec2 position[4];
uniform vec3 lightglobalposition;
uniform vec2 lightrange;
uniform mat4 entitymatrix;
uniform mat4 camerainversematrix;

in vec3 vertex_position;

out vec3 ex_aabbmin;
out vec3 ex_aabbmax;
out vec3 ex_localaabbmin;
out vec3 ex_localaabbmax;
out vec3 ex_VertexCameraPosition;

uniform float aabbpadding;

void main(void)
{
	const float padding = 0.1;
	
	vec3 scaleoffset;
	vec3 scale;
	scale.x = length(entitymatrix[0].xyz);
	scale.y = length(entitymatrix[1].xyz);
	scale.z = length(entitymatrix[2].xyz);
	
	scale.x = 1.0 + aabbpadding / scale.x * 2.0;
	scale.y = 1.0 + aabbpadding / scale.y * 2.0;
	scale.z = 1.0 + aabbpadding / scale.z * 2.0;
		
	gl_Position = projectioncameramatrix * entitymatrix * vec4(vertex_position * scale,1.0);
	ex_VertexCameraPosition = vec3(camerainversematrix * gl_Position);


	ex_aabbmin = (entitymatrix * vec4(-0.5,-0.5,-0.5,1.0)).xyz;
	ex_aabbmax = (entitymatrix * vec4(0.5,0.5,0.5,1.0)).xyz;
	ex_localaabbmin = (projectioncameramatrix * vec4(ex_aabbmin,1.0)).xyz;
	ex_localaabbmax = (projectioncameramatrix * vec4(ex_aabbmax,1.0)).xyz;
	//gl_Position = projectioncameramatrix * vec4(lightglobalposition + vertex_position * lightrange.y * 2.0,1.0);
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
uniform mat4 entitymatrix;
uniform mat4 camerainversematrix;

in vec3 vertex_position;

out vec3 ex_aabbmin;
out vec3 ex_aabbmax;
out vec3 ex_localaabbmin;
out vec3 ex_localaabbmax;
out vec3 ex_VertexCameraPosition;

uniform float aabbpadding;

void main(void)
{
	const float padding = 0.1;
	
	vec3 scaleoffset;
	vec3 scale;
	scale.x = length(entitymatrix[0].xyz);
	scale.y = length(entitymatrix[1].xyz);
	scale.z = length(entitymatrix[2].xyz);
	
	scale.x = 1.0 + aabbpadding / scale.x * 2.0;
	scale.y = 1.0 + aabbpadding / scale.y * 2.0;
	scale.z = 1.0 + aabbpadding / scale.z * 2.0;
		
	gl_Position = projectioncameramatrix * entitymatrix * vec4(vertex_position * scale,1.0);
	ex_VertexCameraPosition = vec3(camerainversematrix * gl_Position);


	ex_aabbmin = (entitymatrix * vec4(-0.5,-0.5,-0.5,1.0)).xyz;
	ex_aabbmax = (entitymatrix * vec4(0.5,0.5,0.5,1.0)).xyz;
	ex_localaabbmin = (projectioncameramatrix * vec4(ex_aabbmin,1.0)).xyz;
	ex_localaabbmax = (projectioncameramatrix * vec4(ex_aabbmax,1.0)).xyz;
	//gl_Position = projectioncameramatrix * vec4(lightglobalposition + vertex_position * lightrange.y * 2.0,1.0);
}
@OpenGL4.Fragment
#version 400
#ifndef SAMPLES
	#define SAMPLES 1
#endif
#define LOWERLIGHTTHRESHHOLD 0.001
#define PI 3.14159265359
#define HALFPI PI/2.0
#ifndef KERNEL
	#define KERNEL 3
#endif
#define KERNELF float(KERNEL)
#define GLOSS 10.0

#define PARALLAX_CUBEMAP 1

#define AMBIENT_ROUGHNESS 7
#define SPECULAR_ROUGHNESS 0

uniform vec4 lighting_ambient;

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

uniform mat3 cameranormalmatrix;
uniform mat3 camerainversenormalmatrix;
uniform vec3 cameraposition;
uniform samplerCube texture5;//shadowmap
uniform vec4 ambientlight;
uniform vec2 buffersize;
uniform vec3 lightposition;
uniform vec4 lightcolor;
uniform vec4 lightspecular;
uniform vec2 lightrange;
uniform vec3 lightglobalposition;
uniform vec2 camerarange;
uniform float camerazoom;
uniform mat4 lightprojectionmatrix;
uniform mat4 lightprojectioninversematrix;
uniform mat4 projectioncameramatrix;
uniform mat4 cameramatrix;
uniform mat4 camerainversematrix;
uniform mat4 projectionmatrix;
uniform vec2 lightshadowmapoffset;
uniform mat3 lightnormalmatrix;
uniform float shadowmapsize;
uniform bool isbackbuffer;
uniform float aabbpadding;

in vec3 ex_VertexCameraPosition;

in vec3 ex_aabbmin;
in vec3 ex_aabbmax;
in vec3 ex_localaabbmin;
in vec3 ex_localaabbmax;

out vec4 fragData0;

float depth;
vec4 diffuse;
vec3 normal;
vec4 materialdata;
float specularity;
float ao;
bool uselighting;
vec4 emission;	
vec4 sampleoutput;
vec4 stagecolor;
vec3 screencoord;
vec3 screennormal;
float attenuation;	
vec3 lightreflection;
float fade;
vec3 shadowcoord;
float dist;
vec3 offset;
vec2 sampleoffset;
vec3 lp;
vec4 normaldata;
int materialflags;

vec4 albedo;		
vec4 surfacedata;		
float specular;
float metalness;
float gloss;
float roughnessmip;
float specular_power;	
float roughness;
vec4 specular_colour;
	
vec4 sample_out;	

float depthToPosition(in float depth, in vec2 depthrange)
{
	return depthrange.x / (depthrange.y - depth * (depthrange.y - depthrange.x)) * depthrange.y;
}

float positionToDepth(in float z, in vec2 depthrange) {
	return (depthrange.x / (z / depthrange.y) - depthrange.y) / -(depthrange.y - depthrange.x);
}

//function to parallax correct reflection
vec3 getBoxIntersection( vec3 pos, vec3 reflectionVector, vec3 cubeSize, vec3 cubePos )
{
        vec3 rbmax = ((cubePos-cubeSize *.5) + cubeSize - pos ) / reflectionVector;
        vec3 rbmin = ((cubePos-cubeSize *.5) - pos ) / reflectionVector;   
        
        vec3 rbminmax = vec3(
                ( reflectionVector.x > 0.0f ) ? rbmax.x : rbmin.x,
                ( reflectionVector.y > 0.0f ) ? rbmax.y : rbmin.y,
                ( reflectionVector.z > 0.0f ) ? rbmax.z : rbmin.z );
        
        float correction = min( min( rbminmax.x, rbminmax.y ), rbminmax.z );
        return ( pos + reflectionVector * abs( correction ) );
}

//Correct cubemaps
vec3 LocalCorrect(vec3 origVec, vec3 bboxMin, vec3 bboxMax, vec3 vertexPos, vec3 cubemapPos, float offset)
{
    // Find the ray intersection with box plane
    vec3 invOrigVec = vec3(1.0)/origVec;
    vec3 intersecAtMaxPlane = (bboxMax - vertexPos) * invOrigVec;
    vec3 intersecAtMinPlane = (bboxMin - vertexPos) * invOrigVec;
    // Get the largest intersection values
    // (we are not intersted in negative values)
    vec3 largestIntersec = max(intersecAtMaxPlane, intersecAtMinPlane);
    // Get the closest of all solutions
    float Distance = min(min(largestIntersec.x, largestIntersec.y),
                         largestIntersec.z);
    // Get the intersection position
    vec3 IntersectPositionWS = vertexPos + origVec * (Distance + offset);// * (length(cubemapPos-cameraposition)));
    // Get corrected vector
    vec3 localCorrectedVec = IntersectPositionWS - cubemapPos;
    return localCorrectedVec;
}

bool AABBIntersectsPoint(in vec3 aabbmin, in vec3 aabbmax, in vec3 p)
{
	if (p.x<aabbmin.x) return false;
	if (p.y<aabbmin.y) return false;
	if (p.z<aabbmin.z) return false;
	if (p.x>aabbmax.x) return false;
	if (p.y>aabbmax.y) return false;
	if (p.z>aabbmax.z) return false;		
	return true;
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

	//AABB
	float aabbf=lightrange.y;
	vec3 aabbmin=lightglobalposition+vec3(-aabbf,-aabbf,-aabbf);
	vec3 aabbmax=lightglobalposition+vec3(aabbf,aabbf,aabbf);

	for (int i=0; i<max(1,SAMPLES); i++)
	{
		//----------------------------------------------------------------------
		//Retrieve data from gbuffer
		//----------------------------------------------------------------------
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
		normal = 		camerainversenormalmatrix * normalize(normaldata.xyz*2.0-1.0);

		materialflags = int(normaldata.a * 255.0 + 0.5);
		sample_out = 	albedo;
		
		screencoord = vec3(((gl_FragCoord.x/buffersize.x)-0.5) * 2.0 * (buffersize.x/buffersize.y),((-gl_FragCoord.y/buffersize.y)+0.5) * 2.0,depthToPosition(depth,camerarange));
		screencoord.x *= screencoord.z / camerazoom;
		screencoord.y *= -screencoord.z / camerazoom;		
		screennormal = normalize(screencoord);		
		screencoord *= flipcoord;

		if ((1 & materialflags)!=0)
		{		
			specular =	surfacedata.b;				
			gloss =		surfacedata.r;
			metalness = 1 - surfacedata.g;
				
			float specular_power  	= gloss*gloss;
			specular_colour = mix(albedo, vec4(specular), metalness) * lightcolor;
			roughness 		= AMBIENT_ROUGHNESS - (specular_power * AMBIENT_ROUGHNESS);
				
			//get vertex positions for local correction
			vec3 vpos = (cameramatrix * vec4(screencoord,1)).xyz;
			
			if (AABBIntersectsPoint(ex_aabbmin-aabbpadding,ex_aabbmax+aabbpadding,vpos))
			{
				//Distance attenuation
				float attenuation = 1.0 - max(0.0,(vpos.z-(ex_aabbmax.z))/aabbpadding);
				attenuation *= 1.0 - max(0.0,(vpos.x-(ex_aabbmax.x))/aabbpadding);
				attenuation *= 1.0 - max(0.0,(vpos.y-(ex_aabbmax.y))/aabbpadding);
				attenuation *= 1.0 - max(0.0,(ex_aabbmin.x-(vpos.x))/aabbpadding);
				attenuation *= 1.0 - max(0.0,(ex_aabbmin.y-(vpos.y))/aabbpadding);
				attenuation *= 1.0 - max(0.0,(ex_aabbmin.z-(vpos.z))/aabbpadding);
				
				vec3 lightvector = (screencoord - lightposition);
				vec3 lightnormal = normalize(lightvector);	

				//Fresnel effect
				vec3 reflectvec 	= normalize(reflect(screencoord, normal));
				float exponent = pow(1.0f - clamp(dot(normal, reflectvec), 0.0, 1.0), 5.0f);		
				vec3 fresnel_term = specular_colour.xyz + (1.0f - max(1.0 - vec3(specular_power), specular_colour.xyz)) * exponent;	
				
				//Ambient lighting
				vec3 shadowcoord = cameranormalmatrix * normalize(reflect(lightnormal,normal));
				float miplevel = max(int(textureQueryLod(texture5,shadowcoord).y), AMBIENT_ROUGHNESS);
				vec4 ambient = textureLod(texture5,shadowcoord,miplevel) * albedo * metalness;

				
				//Specular reflection
				shadowcoord = lightnormalmatrix * reflect(screennormal*flipcoord,normal);
#if PARALLAX_CUBEMAP==1
				shadowcoord=LocalCorrect(shadowcoord,ex_aabbmin,ex_aabbmax,vpos,vec3(lightglobalposition),0.0f);
#endif
				miplevel = max(textureQueryLod(texture5,shadowcoord).y, roughness);
				vec4 specular = textureLod(texture5,shadowcoord,miplevel);	
				specular *= vec4(fresnel_term,1.0);	
				
				//Max blend mode
				fragData0 += (ambient + specular) * attenuation;				
			}
#if SAMPLES<2
			else
			{
				discard;
			}
#endif
		}
	}
	fragData0 /= max(1,SAMPLES);	
}

#version 130 

uniform vec4 eye;
uniform vec4 ambient;
uniform vec4[20] objects;
uniform vec4[20] objColors;// Ka = Kd for every object[i]
uniform vec4[10] lightsDirection;// w = 0.0 => directional light; w = 1.0 => spotlight
uniform vec4[10] lightsIntensity;// (R,G,B,A)
uniform vec4[10] lightPosition;// Positions for spotlights
uniform ivec3 sizes; //number of objects & number of lights

in vec3 position1;

float quadraticEquation(float a, float b, float c){
	float delta = b * b - 4.0 * a * c;	
	if(delta < 0){
		return -1.0;
	}
	float x1 = (-b + sqrt(delta)) / (2.0 * a);
	float x2 = (-b - sqrt(delta)) / (2.0 * a); 
	
	return min(x1, x2);
}

float sphereIntersection(vec3 p0, vec3 v, vec4 sphere){
	vec3 o = sphere.xyz;
	float r = sphere.w;
			
	float a = length(v) * length(v);
	float b = 2.0 * dot(v, (p0 - o));
	float c = (length(p0 - o) * length(p0 - o)) - (r * r);
	
	return quadraticEquation(a, b, c);
}

float planeIntersection(vec3 p0, vec3 v, vec4 plane){
	vec3 n = plane.xyz;
	float d = plane.w;
	
	float distance = -(d + p0.z * n.z + p0.y * n.y + p0.x * n.x)/(v.z * n.z + v.y * n.y + v.x * n.x);
	if(distance <  0){
		return -1.0;
	} else{
		return distance;
	}
}

bool isSphere(vec4 obj){
	return obj.w > 0;
}

float intersection(vec3 p0, vec3 v, vec4 obj)
{
	if(isSphere(obj)){
		return sphereIntersection(p0, v, obj);
	} else{
		return planeIntersection(p0, v, obj);
	}
}

bool quart1_3(vec3 p){
	return p.x * p.y > 0;
}

bool squareCoefficient(vec3 p){
	return mod(int(1.5*p.x),2) == mod(int(1.5*p.y),2);
}

vec3 calcEmissionColor(vec3 position0){
	return vec3(0,0,0);
}

vec3 calcAmbientColor(int intersection){
	//return ambient.xyz * objColors[intersection].xyz;
	return vec3(0.1, 0.2, 0.3) * objColors[intersection].xyz;
}

bool occulded(vec4 light_ray, vec4 light){
	return true;
}

bool isDirectional(vec4 light){
	return light.w == 0;
}

vec3 sphereNormal(vec3 o, vec3 p){
	return (p - o) / length(p - o);
}

vec3 directionalIntensity(vec3 lightIntensity, vec3 lightDirection, vec3 L){
	return lightIntensity * dot(lightDirection, L);
}

vec3 spotlightIntensity(vec4 lightDirection, vec4 lightIntensity, vec3 L){
	return vec3(0,0,0);
}

vec3 calcDiffuseColor(int intersection, int light, vec3 p){
	vec3 N = isSphere(objects[intersection]) ? sphereNormal(objects[intersection].xyz, p) : objects[intersection].xyz;
	vec3 L = normalize(lightsDirection[light].xyz);
	float cosTheta = dot(normalize(N), normalize(L));//dot(N, L) / (length(N) * length(L));
	vec3 I = isDirectional(lightDirection) ? directionalIntensity(lightIntensity.xyz, lightDirection.xyz, L) : vec3(0,0,0);
	return objColors[intersection].xyz * cosTheta * I;
}

vec3 calcSpecularColor(vec4 light){
	return vec3(0,0,0);
}

vec4 getSpecularK(){
	return vec4(0.7,0.7,0.7,1.0);
}

int lightsCount(){
	return sizes.y;
}

int objectsCount(){
	return sizes.x;
}

vec4 getLight(int i){
	return lightsDirection[i];
}

vec4 ConstructRaytoLight(vec3 position0, vec4 light){
		return light.xyz - position0;
}

vec3 colorCalc(vec3 intersectionPoint)
{
	vec3 p0 = intersectionPoint;
	vec3 v = normalize(position1 - p0);
	
	float distance = 1000000;
	float t_obj;
	int intersection = -1;
	float coefficient = 1.0;
	
	for(int i=0; i<objectsCount(); i++){
		t_obj = intersection(p0, v, objects[i]);
		if(t_obj < distance && t_obj != -1){
			distance = t_obj;
			intersection = i;
		}
	}

	vec3 p = p0 + distance * v;
	if(!isSphere(objects[intersection]) && ((squareCoefficient(p) && quart1_3(p)) || !(squareCoefficient(p) || quart1_3(p)))){
		coefficient = 0.5;
	}
	
	/******** Lighting [pseudo-code] *********/
	// Ambient calculations
	vec3 ambient = coefficient * calcAmbientColor(intersection);
	// Diffuse and Specular calculations
	vec3 diffuse = vec3(0, 0, 0);
	for(int i=0; i<lightsCount(); i++){
		diffuse = diffuse + calcDiffuseColor(intersection, i, p);
		/*vec4 light = getLight(i);
		vec4 light_ray = ConstructRaytoLight(intersectionPoint, light);
		// Add color only if light is not occulded
		if(!occulded(light_ray, light)){
			color += calcDiffuseColor(light)+
					 calcSpecularColor(light);
		}*/
	}
	
	vec3 result = ambient + diffuse;
	
    return result;
}


void main()
{  
   gl_FragColor = vec4(colorCalc(eye.xyz),1);      
}
 


shader_type canvas_item;

// Add a color picker to inspector.
uniform vec4 CAST_COLOR : source_color;

// Get the underlying screen texture.
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

// Add a noise resource to inspector (for fast noise). 
// Using repeat_enable will force the noise texture to tile infinitely. 
uniform sampler2D fast_noise : repeat_enable;

// Speed at which waves move.
uniform vec2 speed = vec2(0.03, 0.07);

// Strength of waves.
uniform float wave_strength = 2;

// Scale and Zoom properties parameters for when editor changes (set from script).
uniform float scale_y;
uniform float y_zoom;

// Called for every vertex the material is visible on.
void vertex() {   
// Move water up and down with sine.
VERTEX.y += sin(TIME) * 0.01;   
}

// Called for every pixel the material is visible on.
void fragment() {   
// Get ripple noise position and make it change position each frame.
vec2 uv = UV + speed * TIME;   

// Get the noise texture from fast noise and follow the position coded above.
vec2 noise = texture(fast_noise, uv).rg;

// Get the size of the object the shader is on.
float uv_height = (SCREEN_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.y);

// To get the position of the pixel to reflect, get the current position on screen
// and change the y value by subtracting the UV height just calculated above
// multiplied by scale and zoom properties.
vec2 reflected_uv = vec2(SCREEN_UV.x, SCREEN_UV.y - (uv_height * UV.y * scale_y * y_zoom));

// Get the appropriate pixel to reflect from the underlying screen texture using reflected UV.
vec4 reflection = texture(SCREEN_TEXTURE, reflected_uv);

// Calculate waves for ripples.
// Grab the appropriate pixel then displace it by using the noise values on screen_texture and 
// multiply zoom level and wave strength.
vec4 waves = texture(SCREEN_TEXTURE, reflected_uv + noise * y_zoom * (wave_strength / 100.0));

// Apply and output the wave ripples value plus the selected color.
// Basically, it combines the color tint selected and the displacement and reflections 
// calculated into the waves variable.
COLOR = waves + CAST_COLOR ;

}
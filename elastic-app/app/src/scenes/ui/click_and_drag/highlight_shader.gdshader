shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_width : hint_range(0, 10) = 1.0;
uniform bool enable_outline = false;
uniform bool pixel_perfect = true;

varying vec4 modulate_color;

void vertex() {
    // Pass the modulation from vertex to fragment
    modulate_color = COLOR;
}

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    vec2 size = vec2(textureSize(TEXTURE, 0));

    float pixel_size_x = 1.0 / size.x;
    float pixel_size_y = 1.0 / size.y;

    vec4 final_color = texture_color;

    if (enable_outline && texture_color.a <= 0.1) {
        float outline_found = 0.0;

        // Calculate the actual width to scan in pixels
        float width = pixel_perfect ? floor(outline_width) : outline_width;

        for(float x = -width; x <= width; x++) {
            for(float y = -width; y <= width; y++) {
                if (x == 0.0 && y == 0.0) continue;

                // Calculate the distance from the center for a more circular outline
                float dist = sqrt(x*x + y*y);
                if (dist > width) continue; // Skip if outside the outline radius

                vec2 outline_uv = UV + vec2(x * pixel_size_x, y * pixel_size_y);

                // Check if we're still within the texture
                if (outline_uv.x >= 0.0 && outline_uv.x <= 1.0 &&
                    outline_uv.y >= 0.0 && outline_uv.y <= 1.0) {
                    vec4 neighbor_color = texture(TEXTURE, outline_uv);
                    if (neighbor_color.a > 0.1) {
                        // Use inverse distance for a smooth fade if not pixel perfect
                        float intensity = pixel_perfect ? 1.0 : (1.0 - dist/width);
                        outline_found = max(outline_found, intensity);
                    }
                }
            }
        }

        if (outline_found > 0.0) {
            final_color = outline_color;
            final_color.a *= outline_found; // Apply intensity for smoother outlines
        }
    }

    // Apply the modulation that was passed from vertex shader
    COLOR = final_color * modulate_color;
}
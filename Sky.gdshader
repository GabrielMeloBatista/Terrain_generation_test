// Nome do arquivo: stylized_sky.gdshader
shader_type sky;

// --- Uniforms do Gradiente e Estrelas ---
uniform vec4 zenith_color : source_color = vec4(0.1, 0.2, 0.4, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.7, 0.4, 0.3, 1.0);
uniform vec4 nadir_color : source_color = vec4(0.2, 0.1, 0.2, 1.0);
uniform float horizon_blur : hint_range(0.0, 1.0) = 0.1;

uniform vec4 star_color : source_color = vec4(1.0, 1.0, 0.9, 1.0);
uniform float star_density : hint_range(0.95, 1.0) = 0.995;
uniform float star_twinkle_speed : hint_range(0.0, 5.0) = 1.0;

// --- Uniforms do Sol ---
uniform vec3 sun_direction = vec3(0.0, 0.3, -1.0);
uniform vec4 sun_disk_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform vec4 sun_halo_color : source_color = vec4(0.9, 0.6, 0.3, 1.0);
uniform float sun_disk_size : hint_range(0.0, 1.0) = 0.998;
uniform float sun_halo_size : hint_range(0.0, 1.0) = 0.85;
uniform float sun_halo_falloff : hint_range(1.0, 32.0) = 8.0;

// --- Uniforms das Nuvens ---
uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.4;
uniform float cloud_scale : hint_range(0.1, 5.0) = 2.0;
uniform float cloud_speed : hint_range(0.0, 0.2) = 0.05;

// --- Uniforms de Dia/Noite (NOVAS) ---
uniform float daylight_factor : hint_range(0.0, 1.0) = 1.0; // 1.0 = dia, 0.0 = noite
uniform vec4 night_color : source_color = vec4(0.01, 0.02, 0.04, 1.0);

// --- Funções de Ruído para Nuvens ---
float random(vec2 uv) { return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123); }
float noise(vec2 uv) { vec2 i = floor(uv); vec2 f = fract(uv); f = f * f * (3.0 - 2.0 * f); float a = random(i); float b = random(i + vec2(1.0, 0.0)); float c = random(i + vec2(0.0, 1.0)); float d = random(i + vec2(1.0, 1.0)); return mix(mix(a, b, f.x), mix(c, d, f.x), f.y); }
float fbm(vec2 uv) { float v = 0.0; float a = 0.5; for (int i = 0; i < 4; i++) { v += a * noise(uv); uv *= 2.0; a *= 0.5; } return v; }


void sky() {
    vec3 normalized_sun_dir = normalize(sun_direction);
    float y_pos = EYEDIR.y;

    // ----- DESENHO DO GRADIENTE (AGORA SENSÍVEL AO DIA/NOITE) -----
    vec3 current_zenith = mix(night_color.rgb, zenith_color.rgb, daylight_factor);
    vec3 current_horizon = mix(night_color.rgb * 0.5, horizon_color.rgb, daylight_factor);

    float sky_mix = smoothstep(-horizon_blur, horizon_blur, y_pos);
    vec3 sky_gradient = mix(current_horizon, current_zenith, sky_mix);
    float ground_mix = smoothstep(0.0, -0.2, y_pos);
    vec3 final_color = mix(sky_gradient, nadir_color.rgb, ground_mix);

    // ----- DESENHO DO SOL E HALO -----
    // O sol só será visível se estiver acima do horizonte, o que já acontece naturalmente.
    float sun_dist = distance(EYEDIR, normalized_sun_dir);
    float sun_disk = smoothstep(sun_disk_size, sun_disk_size + 0.005, 1.0 - sun_dist);
    final_color = mix(final_color, sun_disk_color.rgb, sun_disk);
    float sun_halo = pow(smoothstep(sun_halo_size, 1.0, 1.0 - sun_dist), sun_halo_falloff);
    final_color = mix(final_color, sun_halo_color.rgb, sun_halo * sun_halo_color.a);

    // ----- DESENHO DAS ESTRELAS (AGORA SENSÍVEL À NOITE) -----
    float star_visibility = 1.0 - daylight_factor; // A visibilidade é o inverso do fator de luz do dia
    if (y_pos > 0.0 && star_visibility > 0.0) { // Só calcula se as estrelas forem visíveis
        vec2 star_uv = EYEDIR.xz / EYEDIR.y;
        float star_noise = random(star_uv * 1000.0);
        float twinkle = pow((sin(TIME * star_twinkle_speed + star_noise * 100.0) + 1.0) / 2.0, 4.0);

        if (star_noise > star_density) {
            float star_brightness = (star_noise - star_density) / (1.0 - star_density);
            // Multiplica o brilho pela visibilidade
            final_color = mix(final_color, star_color.rgb, star_brightness * twinkle * (1.0 - sun_disk) * star_visibility);
        }
    }

    // ----- DESENHO DAS NUVENS (AGORA SENSÍVEIS AO DIA/NOITE) -----
    if (y_pos > 0.05) {
        vec2 cloud_uv = EYEDIR.xz * cloud_scale + vec2(TIME * cloud_speed, 0.0);
        float cloud_noise = fbm(cloud_uv);
        float cloud_mask = smoothstep(1.0 - cloud_coverage, 1.0, cloud_noise);

        // Iluminação das nuvens também depende do dia/noite
        float sun_influence = pow(max(0.0, dot(EYEDIR, normalized_sun_dir)), 2.0);
        vec3 ambient_light = mix(vec3(0.1), vec3(0.5), daylight_factor); // Menos luz ambiente à noite
        vec3 lit_cloud_color = cloud_color.rgb * mix(ambient_light, sun_disk_color.rgb, sun_influence);

        final_color = mix(final_color, lit_cloud_color, cloud_mask * (1.0 - sun_disk));
    }

    COLOR = final_color;
}

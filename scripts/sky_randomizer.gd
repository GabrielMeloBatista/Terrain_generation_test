# Nome do arquivo: SkyManager.gd
extends Node

## Arraste o nó WorldEnvironment da sua cena para esta variável no Inspetor.
@export var world_environment: WorldEnvironment
## Arraste o nó DirectionalLight3D da sua cena para esta variável.
@export var sun_light: DirectionalLight3D

func _ready():
	# Gera as propriedades estéticas do céu (cores, nuvens) assim que a cena é carregada.
	randomize_sky_properties()
	# Garante que a posição inicial do sol seja definida imediatamente.
	update_sun_position()

func _process(delta):
	# Atualiza a posição do sol no shader em tempo real, baseado na DirectionalLight3D.
	update_sun_position()

# Atualiza a posição do sol e o fator dia/noite no shader.
func update_sun_position():
	if not is_instance_valid(sun_light):
		# Se não houver uma luz configurada, não faz nada para evitar erros.
		return
	
	var sky_material = get_sky_material()
	if not sky_material:
		return

	# A direção de uma DirectionalLight3D é o seu eixo Z negativo.
	# Normalizamos para garantir que o vetor tenha comprimento 1.
	var sun_direction = sun_light.transform.basis.z.normalized()
	
	# Cria um valor suave entre 0.0 (noite) e 1.0 (dia) baseado na altura do sol.
	var daylight_factor = smoothstep(-0.15, 0.15, sun_direction.y)

	# Atualiza os parâmetros do shader em tempo real
	sky_material.set_shader_parameter("sun_direction", sun_direction)
	sky_material.set_shader_parameter("daylight_factor", daylight_factor)

# Randomiza apenas as propriedades estéticas do céu (cores, nuvens, etc).
func randomize_sky_properties():
	var sky_material = get_sky_material()
	if not sky_material:
		return

	# --- ATUALIZAÇÃO DAS UNIFORMS NO SHADER ---
	# Gradiente e Estrelas
	sky_material.set_shader_parameter("horizon_blur", randf_range(0.05, 0.2))
	sky_material.set_shader_parameter("star_density", randf_range(0.99, 0.998))
	sky_material.set_shader_parameter("star_twinkle_speed", randf_range(0.5, 2.0))
	
	# Nuvens
	sky_material.set_shader_parameter("cloud_coverage", randf_range(0.1, 0.7))
	sky_material.set_shader_parameter("cloud_scale", randf_range(1.0, 4.0))
	sky_material.set_shader_parameter("cloud_speed", randf_range(0.01, 0.1))

# Função auxiliar para obter o material do shader de forma segura e limpa.
func get_sky_material() -> ShaderMaterial:
	if not is_instance_valid(world_environment) or not is_instance_valid(world_environment.environment):
		push_error("WorldEnvironment não foi definido ou é inválido no SkyManager.")
		return null

	var sky = world_environment.environment.sky
	if not is_instance_valid(sky) or not is_instance_valid(sky.sky_material):
		push_error("O material do céu (Sky com ShaderMaterial) não foi encontrado no Environment.")
		return null
		
	return sky.sky_material

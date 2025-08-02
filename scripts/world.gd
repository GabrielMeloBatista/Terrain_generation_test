# world.gd (Carregamento Dinâmico)
# Este script gerencia a criação e remoção dinâmica de chunks ao redor do jogador,
extends Node3D

const CHUNK_WIDTH: int = 32
const CHUNK_DEPTH: int = 32
const CUBE_SIZE: float = 1.0

@export var chunk_scene: PackedScene
@export var player: CharacterBody3D

@export var noise: FastNoiseLite
@export var terrain_amplitude: float = 12.0
@export var view_distance: int = 4

var chunks = {}
var current_player_chunk_coord: Vector2i = Vector2i(9999, 9999)

@onready var check_timer: Timer = $CheckTimer

# A função _ready agora é 'async' para poder usar 'await'.
func _ready():
	if noise == null:
		noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.03
		noise.fractal_octaves = 4
	
	noise.seed = randi()
	
	if not player:
		push_error("Nó do jogador não foi definido no inspetor do World!")
		return
		
	# 1. Desabilita o jogador temporariamente para que ele não caia.
	player.process_mode = Node.PROCESS_MODE_DISABLED
	
	# 2. Faz a primeira chamada para gerar os chunks iniciais ao redor do jogador.
	update_chunks()
	
	# 3. Pega a referência para o chunk onde o jogador está.
	var initial_chunk_coord = world_to_chunk_coord(player.global_position)
	var initial_chunk = chunks.get(initial_chunk_coord)
	
	# 4. Se o chunk existe, espera pelo sinal 'mesh_generated'.
	# A execução do código vai pausar aqui até o sinal ser emitido.
	if initial_chunk:
		print("Esperando o chunk inicial (%s) ser gerado..." % initial_chunk_coord)
		await initial_chunk.mesh_generated
		print("Chunk inicial gerado!")
	
	# 5. Agora que o terreno existe, calcula a altura e posiciona o jogador.
	var player_pos = player.global_position
	var terrain_top_y = get_terrain_height(player_pos)
	player.global_position = Vector3(player_pos.x, terrain_top_y + 1.0, player_pos.z) # +1 para garantir que não fique preso
	
	# 6. Reabilita o jogador e inicia o timer para atualizações contínuas.
	player.process_mode = Node.PROCESS_MODE_INHERIT
	
	check_timer.wait_time = 0.25
	check_timer.timeout.connect(update_chunks)
	check_timer.start()


func world_to_chunk_coord(world_position: Vector3) -> Vector2i:
	var x = floori(world_position.x / (CHUNK_WIDTH * CUBE_SIZE))
	var z = floori(world_position.z / (CHUNK_DEPTH * CUBE_SIZE))
	return Vector2i(x, z)

func get_terrain_height(world_position: Vector3) -> float:
	var noise_val = noise.get_noise_2d(world_position.x, world_position.z)
	return ((noise_val + 1.0) / 2.0 * terrain_amplitude)
	
func update_chunks():
	var new_player_chunk_coord = world_to_chunk_coord(player.global_position)
	
	if new_player_chunk_coord == current_player_chunk_coord:
		return
		
	current_player_chunk_coord = new_player_chunk_coord
	
	# Descarrega chunks distantes
	var chunks_to_remove = []
	for chunk_coord in chunks:
		var diff = chunk_coord - current_player_chunk_coord
		if max(abs(diff.x), abs(diff.y)) > view_distance:
			chunks_to_remove.append(chunk_coord)
	
	for chunk_coord in chunks_to_remove:
		var chunk_node = chunks.get(chunk_coord)
		if is_instance_valid(chunk_node):
			chunk_node.queue_free()
		chunks.erase(chunk_coord)

	# Carrega novas chunks próximas
	for x in range(-view_distance, view_distance + 1):
		for z in range(-view_distance, view_distance + 1):
			var chunk_coord = current_player_chunk_coord + Vector2i(x, z)
			if not chunks.has(chunk_coord):
				create_chunk(chunk_coord)

# Cria um único chunk e inicia sua geração assíncrona.
func create_chunk(chunk_coord: Vector2i):
	if chunk_scene == null:
		push_error("Cena da Chunk não foi definida no inspetor!")
		return
		
	var new_chunk = chunk_scene.instantiate()
	add_child(new_chunk)
	chunks[chunk_coord] = new_chunk
	
	new_chunk.build_mesh(chunk_coord, noise, terrain_amplitude, {})

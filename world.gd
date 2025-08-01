# world.gd (Geração Estática)
# Este script gera um mundo de tamanho fixo no início do jogo.
extends Node3D

const CHUNK_WIDTH: int = 32
const CHUNK_DEPTH: int = 32
const CUBE_SIZE: float = 1.0

@export var chunk_scene: PackedScene
@export var player: CharacterBody3D

@export var noise: FastNoiseLite
@export var terrain_amplitude: float = 12.0

@export_group("World Size")
@export var world_size_x: int = 5
@export var world_size_z: int = 5

var chunks = {}

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
	
	# 2. Gera todos os chunks do mundo de uma vez.
	for x in range(world_size_x):
		for z in range(world_size_z):
			create_chunk(Vector2i(x, z))
	
	# 3. Pega a referência para o chunk inicial (0, 0).
	var initial_chunk_coord = Vector2i.ZERO
	var initial_chunk = chunks.get(initial_chunk_coord)
	
	# 4. Se o chunk inicial existe, espera pelo sinal 'mesh_generated'.
	if initial_chunk:
		print("Esperando o chunk inicial (%s) ser gerado..." % initial_chunk_coord)
		await initial_chunk.mesh_generated
		print("Chunk inicial gerado!")
	
	# 5. calcula a altura e posiciona o jogador.
	var player_pos = player.global_position
	var terrain_top_y = get_terrain_height(player_pos)
	player.global_position = Vector3(player_pos.x, terrain_top_y + 1.0, player_pos.z) # +1 para garantir que não fique preso
	
	# 6. Reabilita o jogador.
	player.process_mode = Node.PROCESS_MODE_INHERIT

func get_terrain_height(world_position: Vector3) -> float:
	var noise_val = noise.get_noise_2d(world_position.x, world_position.z)
	return ((noise_val + 1.0) / 2.0 * terrain_amplitude)

# A função de criar chunk agora é chamada apenas no _ready.
func create_chunk(chunk_coord: Vector2i):
	if chunk_scene == null:
		push_error("Cena da Chunk não foi definida no inspetor!")
		return
		
	var new_chunk = chunk_scene.instantiate()
	add_child(new_chunk)
	chunks[chunk_coord] = new_chunk
	
	new_chunk.build_mesh(chunk_coord, noise, terrain_amplitude, {})

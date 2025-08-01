# Geração Procedural de Terreno com Marching Cubes no Godot

Este projeto é um experimento para criar terrenos 3D suaves e orgânicos no Godot Engine, utilizando o algoritmo Marching Cubes. O foco principal é a otimização do desempenho através da geração de malhas (meshes) em múltiplas threads, evitando que o jogo congele durante a criação do mundo.

## Funcionalidades Principais
- **Geração de Malha com Marching Cubes:** Cria terrenos com aparências suaves e naturais, ideais para cavernas, ilhas flutuantes e paisagens orgânicas.
- **Terreno Baseado em Ruído: Utiliza FastNoiseLite para determinar a altura e a forma do terreno, permitindo uma grande variedade de paisagens.
- **Multithreading**: Cada "chunk" (pedaço do mundo) tem sua malha e colisão calculadas em uma thread separada. Isso garante que a thread principal do jogo permaneça livre, resultando em uma experiência fluida e sem travamentos.
- **Geração Estática do Mundo**: O mundo é gerado inteiramente no início, com um tamanho configurável (ex: 5x5 chunks). A lógica de carregamento dinâmico foi removida para focar em um ambiente de tamanho fixo.- Spawn Seguro do Jogador: O jogador só é posicionado no mundo após o chunk inicial ter sua malha de colisão completamente gerada, evitando que ele caia no vazio.
- **Colisão Automática**: Formas de colisão (ConcavePolygonShape3D) são geradas automaticamente para cada chunk, permitindo a interação física do jogador com o terreno. (não funciona no momento)

## Estrutura do codigo
- world.gd (O Gerente do Mundo):
    - Responsável por orquestrar a criação do mundo no início do jogo.
    - Lê as variáveis de tamanho do mundo (ex: world_size_x, world_size_z) definidas no inspetor.
    - Instancia cada cena de chunk e chama a função para iniciar a geração da malha.
    - Gerencia o spawn inicial do jogador, esperando o chunk principal ficar pronto antes de posicioná-lo.
- chunk.gd (O Construtor de Terreno):
    - Representa um único pedaço do mundo.
    - Contém a lógica principal do algoritmo Marching Cubes.
    - Ao ser instruído pelo world.gd, ele inicia uma Thread para fazer todo o trabalho pesado:
    - Calcular os valores de densidade em uma grade 3D usando FastNoiseLite.
    - Construir os vértices da malha com base nos dados de densidade.
    - Após a thread terminar, a função de callback é chamada na thread principal para, de forma segura, criar a ArrayMesh, gerar a CollisionShape3D e tornar o chunk visível.
    - Emite um sinal mesh_generated para notificar o world.gd de que seu trabalho foi concluído.

## Melhorias futuras
- [ ] Carregamento Dinâmico: Adaptar o código para voltar a carregar e descarregar chunks ao redor do jogador para criar um mundo "infinito".
- [ ] Nível de Detalhe (LOD): Gerar chunks distantes com menos polígonos para melhorar ainda mais o desempenho.
- [ ] Biomas: Utilizar múltiplos FastNoiseLite para criar diferentes biomas com características únicas.
- [ ] Texturização e Materiais: Aplicar materiais mais complexos ao terreno, usando, por exemplo, triplanar mapping para texturas que se adaptam à inclinação do terreno.
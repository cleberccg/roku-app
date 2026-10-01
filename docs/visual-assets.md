# Recursos visuais

As imagens foram criadas com a ferramenta integrada de geração de imagens. Os PNGs originais foram preservados fora do repositório; as versões empacotadas foram redimensionadas para reduzir o uso de memória no Roku. Não foi utilizada uma API com chave local.

## Arquivos e dimensões

| Arquivo | Dimensões | Uso |
| --- | --- | --- |
| `images/icon.png` | 290 × 218 | Ícone HD na tela inicial |
| `images/icon-fhd.png` | 540 × 405 | Ícone FHD na tela inicial |
| `images/splash.png` | 1280 × 720 | Tela de abertura HD |
| `images/posters/*.jpg` | 640 × 360 | Capas dos seis vídeos |

As dimensões de ícone e splash seguem a [documentação do manifest Roku](https://developer.roku.com/dev/docs/channel-manifest). A interface continua usando coordenadas HD: incluir um ícone FHD não muda `ui_resolutions`.

As capas são interpretações ilustrativas originais, não cartazes oficiais ou imagens extraídas dos filmes. A imagem local permite navegar no catálogo sem internet; a URL de vídeo continua sendo uma dependência externa.

## Como as imagens chegam à interface

1. `data/catalog.json` aponta `poster` para um arquivo `pkg:/images/posters/...jpg`.
2. `buildCatalog()` copia essa URI para `ContentNode.hdPosterUrl`.
3. A RowList entrega o ContentNode ao field `itemContent` de cada cartão.
4. `showContent()` atribui a URI a `Poster.uri`.
5. A tela de detalhes usa a mesma URI com um tamanho maior.

O node Poster decodifica o arquivo e o exibe. `loadDisplayMode="scaleToFit"` preserva sua proporção inteira dentro da área disponível. Se a imagem e a área tiverem proporções diferentes, sobra espaço em um dos eixos. Alterar width e height do node não altera o arquivo no pacote.

## Prompts usados

### Ícone

```text
Use case: logo-brand. Generate a polished original app icon for the independent portfolio video app named Roku Showcase. Landscape 4:3 canvas, 1200x900. Deep midnight navy background (#0B1220), luminous violet (#8B5CF6) and a subtle cyan highlight. A single large, bold, dimensional rounded play symbol centered, elegant cinema light and subtle film grain. Beautiful clean professional streaming app identity. No text, no letters, no Roku corporate logo, no watermark. Keep the mark inside the central 65% so it reads at 290x218 pixels.
```

### Tela de abertura

```text
Use case: ads-marketing. Create an original launch splash screen for Roku Showcase, an independent test video app. Landscape 16:9 1536x864. Deep midnight navy background (#0B1220), refined violet (#8B5CF6) flowing cinematic light ribbons and subtle cyan highlights at the edges. At center a crisp bold rounded play symbol above the exact words "ROKU SHOWCASE" in premium clean white sans serif typography. Calm spacious design, generous safe margins, strong readable hierarchy, cinematic and professional. No other text, no corporate Roku logo, no mockup frame, no watermark. This will be resized to 1280x720.
```

### Capas

Foi feita uma chamada independente para cada capa. O prompt completo usa o modelo abaixo, substituindo `<SUBJECT>` pelo texto correspondente da lista:

```text
Use case: stylized-concept. Asset: distinct original video catalog cover for Roku Showcase. Landscape 16:9 1536x864, polished cinematic illustration, readable composition at thumbnail size. <SUBJECT> Subtle deep navy and violet palette accents matching the app. Edge to edge artwork, no text, no logos, no watermark, no frame. These are independent illustrative covers, not official movie posters or exact reproductions of any film characters.
```

- `bunny.jpg`: A friendly plump white rabbit in a sunny green woodland clearing, warm cheerful original stylized 3D illustration.
- `dream.jpg`: Two tiny silhouettes exploring an immense surreal mechanical labyrinth of bronze gears, cool blue light, original cinematic concept illustration.
- `sintel.jpg`: A young cloaked traveler and a small dragon viewed from behind facing distant snowy mountains under golden light, original fantasy illustration.
- `blazes.jpg`: Abstract dynamic orange flames swirling around a luminous violet play symbol, cinematic light, original illustration.
- `escapes.jpg`: An open road between dramatic mountains leading toward an ocean sunset, original stylized cinematic travel illustration.
- `fun.jpg`: Colorful floating geometric objects, bouncing spheres and confetti in a deep navy scene, vibrant original playful 3D illustration.

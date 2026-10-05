# Roku Showcase

Aplicativo de teste para Roku, desenvolvido em **BrightScript e SceneGraph**, com catálogo de vídeos, navegação por controle remoto e reprodução no player nativo.

## Funcionalidades

- Catálogo organizado em Animação e Demonstrações.
- Tela de detalhes com título e descrição.
- Favoritos salvos no dispositivo e exibidos em uma categoria própria.
- Reprodução de vídeos MP4 com controles nativos do Roku.
- Retorno aos detalhes ao terminar ou interromper um vídeo.
- Mensagem de erro com opção de tentar reproduzir novamente.
- Catálogo e imagens locais, disponíveis sem conexão; reprodução exige internet.
- Interface HD com destaque de foco e instruções de navegação.

## Tecnologias e arquitetura

A entrada em `source/main.brs` cria uma `roSGScreen` e a `MainScene`. O componente `ApiTask` lê o catálogo JSON em uma Task, e a cena transforma os dados em uma hierarquia de `ContentNode` para a `RowList`. `PosterItem` renderiza os cartões; o node `Video` reproduz o conteúdo selecionado. Favoritos são persistidos com `roRegistrySection`.

O nome `ApiTask` foi mantido como ponto de integração de dados, mas a versão atual utiliza um catálogo local e não faz requisições HTTP para listar os vídeos.

```text
roku-app/
├── manifest
├── source/main.brs
├── components/
│   ├── MainScene.xml / MainScene.brs
│   ├── PosterItem.xml / PosterItem.brs
│   └── ApiTask.xml / ApiTask.brs
├── data/catalog.json
├── images/
└── scripts/package.ps1
```

## Executar em um Roku

1. Ative o modo de desenvolvedor no dispositivo Roku.
2. Conecte o computador e o Roku à mesma rede.
3. Na raiz do projeto, execute o comando abaixo para gerar o pacote:

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/package.ps1
   ```

4. Abra `http://IP_DO_ROKU` no navegador e entre no instalador de desenvolvimento.
5. Envie `dist/roku-showcase.zip` e selecione **Install**.

O pacote contém o `manifest` na raiz e somente os arquivos necessários ao app. Não é necessário instalar Node.js para empacotar.

## Controle remoto

| Tecla | Ação |
| --- | --- |
| Direcionais | Navegar pelas categorias e pelos vídeos |
| OK no catálogo | Abrir detalhes |
| OK nos detalhes | Reproduzir ou tentar novamente |
| Estrela (*) nos detalhes | Adicionar ou remover favorito |
| BACK no vídeo | Parar e voltar aos detalhes |
| BACK nos detalhes | Voltar ao catálogo |
| Play/Pause durante o vídeo | Controle nativo de reprodução |

A categoria Favoritos aparece depois que um vídeo é adicionado. A lista fica salva entre execuções no mesmo dispositivo.

## Personalizar o catálogo

Edite `data/catalog.json`. Cada entrada usa os campos `id` (único), `title`, `category`, `description`, `poster`, `videoUrl` e `streamFormat`. Todos são strings obrigatórias e não vazias. As categorias são criadas automaticamente na ordem do catálogo; `Favoritos` é um nome reservado. Esta versão aceita `mp4`, vídeos HTTPS e capas locais existentes em `pkg:/images/`.

Use `pkg:/images/arquivo.png` para imagens empacotadas e uma URL HTTPS para vídeos. Cada cartão usa uma capa ilustrada própria em `images/posters/`, armazenada no pacote para abrir sem internet. O catálogo inclui seis vídeos de teste; não há autenticação, DRM ou serviço de streaming próprio.

O ícone tem versões HD e FHD, e a tela de abertura usa 1280 × 720. As artes seguem a paleta azul escuro, violeta e ciano da interface. O processo de criação, os prompts e as dimensões estão documentados em [docs/visual-assets.md](docs/visual-assets.md).

## Verificação no dispositivo

- Abrir o app e navegar entre as duas categorias.
- Selecionar um vídeo e iniciar a reprodução com OK.
- Voltar do player e dos detalhes com BACK.
- Adicionar e remover favoritos usando a estrela.
- Fechar e reabrir o app para verificar a persistência dos favoritos.
- Interromper a conexão e verificar a mensagem de erro ao reproduzir.
- Voltar dos detalhes sem alterar favoritos e conferir que o foco permanece no item.
- Adicionar/remover favoritos e conferir que o retorno preserva o item na categoria de origem; ao remover da linha Favoritos, ele deve ser localizado na categoria original.
- Testar um catálogo inválido e verificar a mensagem de erro, sem abrir a lista.

## Qualidade e decisões técnicas

Execute a verificação offline antes de instalar:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/validate-project.ps1
```

Ela valida campos, IDs duplicados, URLs HTTPS, arquivos das capas e XML/referências de scripts. O empacotamento executa essa verificação automaticamente. O GitHub Actions repete a validação e gera o ZIP como artefato em pushes e pull requests. A checagem de URLs externas continua separada, pois depende de rede e servidores de terceiros.

O catálogo também é validado no dispositivo antes de chegar à cena. Um item inválido interrompe a carga com uma mensagem, evitando exibir um catálogo parcialmente incorreto. IDs são considerados únicos sem distinção de maiúsculas/minúsculas.

A arquitetura continua com três componentes: a Task carrega e valida dados; a cena coordena navegação, favoritos e reprodução; o cartão apresenta conteúdo. O catálogo local mantém a demonstração reproduzível e dispensa um backend. Não foram adicionados autenticação, camadas de serviço ou dependências de Node.js.

A lista só é reconstruída quando os favoritos mudam. Favoritos restaurados são filtrados por tipo e deduplicados; a interface só confirma uma alteração depois de `Write` e `Flush` retornarem sucesso. Falhas do player registram ID, código e mensagem no console de depuração, acessível pela porta 8085 do Roku.

Estas verificações não compilam BrightScript nem comprovam reprodução, foco ou compatibilidade com hardware. Os cenários acima precisam ser conferidos no dispositivo. Para apresentar o portfólio, acrescente uma gravação curta desses fluxos e informe o modelo e a versão do Roku usados na validação.

## Mídias

Os vídeos de Big Buck Bunny (curta e trailer) e Sintel (trailer) usam cópias de teste hospedadas pelo W3C. Os três clipes curtos de demonstração vêm do [Samplelib](https://samplelib.com/sample-mp4.html). Os arquivos de vídeo não são distribuídos neste repositório. As capas são ilustrações geradas para este app, não cartazes oficiais nem frames dos vídeos.

As URLs anteriores do bucket `gtv-videos-bucket` foram substituídas após retornarem HTTP 403. As seis fontes atuais foram verificadas em 1º de outubro de 2026 com requisições GET e leitura do cabeçalho MP4. Isso confirma o acesso ao arquivo, mas a compatibilidade de reprodução deve ser conferida no dispositivo Roku.

Para verificar novamente as URLs do catálogo, execute:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check-catalog.ps1
```

As URLs externas podem ficar indisponíveis; o catálogo e as capas locais continuam funcionando. Este é um app de teste e não é afiliado à Roku.

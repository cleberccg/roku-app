' MainScene coordena os três estados da interface: catalog, details e video.
' O XML define a árvore visual; este arquivo define dados, eventos e navegação.
' m é o contexto persistente desta instância do componente, compartilhado entre
' seus callbacks. m.top é o node MainScene que está executando este script.
sub init()
    ' Guardar referências evita buscar os mesmos nodes a cada tecla pressionada.
    ' findNode procura o id declarado no XML, e não o tipo do componente.
    m.catalog = m.top.findNode("catalog")
    m.status = m.top.findNode("status")
    m.details = m.top.findNode("details")
    m.detailPoster = m.top.findNode("detailPoster")
    m.detailTitle = m.top.findNode("detailTitle")
    m.detailDescription = m.top.findNode("detailDescription")
    m.detailHint = m.top.findNode("detailHint")
    m.video = m.top.findNode("video")
    ' Visibilidade e foco são independentes: esconder um node não transfere foco.
    ' m.screen indica qual tela deve interpretar as teclas e os eventos do player.
    m.screen = "catalog"
    m.favorites = []
    m.catalogDirty = false
    ' O registry guarda strings no dispositivo. FormatJson/ParseJson fazem a
    ' conversão entre uma lista BrightScript e o texto salvo na chave favorites.
    ' A seção separa nossas preferências de outras configurações do canal.
    m.registry = CreateObject("roRegistrySection", "RokuShowcase")
    saved = ParseJson(m.registry.Read("favorites"))
    ' Na primeira execução ou se o valor estiver inválido, usamos a lista vazia.
    if type(saved) = "roArray"
        for each id in saved
            if type(id) = "roString" or type(id) = "String"
                if id.trim() <> "" and not isFavorite(id) then m.favorites.push(id)
            end if
        end for
    end if
    ' observeField registra callbacks; não executa a função imediatamente.
    ' A RowList entrega [índice da linha, índice do item] quando o usuário dá OK.
    m.catalog.observeField("rowItemSelected", "onItemSelected")
    m.video.observeField("state", "onVideoStateChanged")
    m.top.setFocus(true)
    ' A Task lê e converte o arquivo de dados fora da thread de renderização.
    ' Os observers precisam existir ANTES de RUN, para não perder o resultado.
    m.apiTask = CreateObject("roSGNode", "ApiTask")
    m.apiTask.observeField("content", "onCatalogLoaded")
    m.apiTask.observeField("error", "onCatalogError")
    m.apiTask.control = "RUN"
end sub

' Este callback roda na cena quando a Task publica seu field content.
' m.items guarda o catálogo original; favoritos alteram só a representação visual.
sub onCatalogLoaded()
    m.items = m.apiTask.content
    if m.items = invalid then return
    buildCatalog()
    m.status.text = "OK: detalhes   |   Nos detalhes, *: favoritos   |   BACK: voltar"
    m.catalog.visible = true
    m.catalog.setFocus(true)
end sub

' A busca compara IDs estáveis, não títulos. Assim, renomear um vídeo no JSON
' não perde seu favorito. A busca linear é suficiente para este catálogo pequeno.
function isFavorite(id as String) as Boolean
    for each savedId in m.favorites
        if savedId = id then return true
    end for
    return false
end function

' A RowList não recebe o array JSON diretamente. Sua estrutura de conteúdo é:
' ContentNode raiz -> ContentNode por categoria -> ContentNode por vídeo.
' Os fields padrão title, description, hdPosterUrl, url e streamFormat permitem
' compartilhar os mesmos dados entre os cartões, os detalhes e o player.
sub buildCatalog()
    root = CreateObject("roSGNode", "ContentNode")
    categories = ["Favoritos"]
    seen = {}
    for each item in m.items
        if not seen.doesExist(item.category)
            categories.push(item.category)
            seen[item.category] = true
        end if
    end for
    for each category in categories
        row = CreateObject("roSGNode", "ContentNode")
        row.title = category
        for each item in m.items
            ' Favoritos é uma categoria virtual: referencia vídeos existentes,
            ' enquanto as demais categorias vêm do campo category no JSON.
            include = item.category = category
            if category = "Favoritos" then include = isFavorite(item.id)
            if include
                child = row.CreateChild("ContentNode")
                child.id = item.id
                child.title = item.title
                child.description = item.description
                child.hdPosterUrl = item.poster
                child.url = item.videoUrl
                child.streamFormat = item.streamFormat
            end if
        end for
        ' Não anexar linhas vazias evita categorias sem itens navegáveis.
        if row.getChildCount() > 0 then root.appendChild(row)
    end for
    m.catalog.content = root
    m.catalogDirty = false
end sub

' Após uma mudança nos favoritos, restaura o item na categoria de origem.
' Se ele foi removido da linha Favoritos, usa a categoria real como alternativa.
sub restoreSelection()
    root = m.catalog.content
    fallback = [0, 0]
    for rowIndex = 0 to root.getChildCount() - 1
        row = root.getChild(rowIndex)
        for itemIndex = 0 to row.getChildCount() - 1
            if row.getChild(itemIndex).id = m.selectedItem.id
                fallback = [rowIndex, itemIndex]
                if row.title = m.selectedCategory
                    m.catalog.jumpToRowItem = fallback
                    return
                end if
            end if
        end for
    end for
    m.catalog.jumpToRowItem = fallback
end sub

' Uma falha de leitura fica na tela de catálogo, onde não existe item selecionado.
sub onCatalogError()
    m.status.text = m.apiTask.error
end sub

' Os índices são baseados em zero. As verificações de invalid protegem o código
' enquanto o conteúdo está sendo criado ou substituído na RowList.
sub onItemSelected()
    indexes = m.catalog.rowItemSelected
    if indexes = invalid then return
    if indexes.count() < 2 then return
    if m.catalog.content = invalid then return
    row = m.catalog.content.getChild(indexes[0])
    if row = invalid then return
    m.selectedItem = row.getChild(indexes[1])
    if m.selectedItem = invalid then return
    m.selectedCategory = row.title
    m.detailPoster.uri = m.selectedItem.hdPosterUrl
    m.detailTitle.text = m.selectedItem.title
    m.detailDescription.text = m.selectedItem.description
    updateHint()
    m.catalog.visible = false
    m.status.visible = false
    m.details.visible = true
    m.screen = "details"
    ' Os detalhes são um Group, sem controles focáveis próprios. Focamos a cena
    ' para que onKeyEvent receba OK, BACK e a estrela nesta tela.
    m.top.setFocus(true)
end sub

' A instrução é calculada a partir do estado real, após abrir detalhes ou mudar
' favoritos. Não precisamos guardar uma segunda variável para o texto do botão.
sub updateHint()
    action = "Adicionar aos favoritos"
    if isFavorite(m.selectedItem.id) then action = "Remover dos favoritos"
    m.detailHint.text = "OK: reproduzir | *: " + action + " | BACK: voltar"
end sub

' Reconstruímos o array, removendo o ID selecionado; se ele ainda não era
' favorito, adicionamos uma única ocorrência ao final. Depois persistimos.
sub toggleFavorite()
    updated = []
    exists = isFavorite(m.selectedItem.id)
    for each id in m.favorites
        if id <> m.selectedItem.id then updated.push(id)
    end for
    if not exists then updated.push(m.selectedItem.id)
    previous = FormatJson(m.favorites)
    if not m.registry.Write("favorites", FormatJson(updated))
        m.detailHint.text = "Não foi possível salvar os favoritos. *: tentar novamente | BACK: voltar"
        return
    end if
    ' Write altera o valor da seção; Flush solicita que seja gravado no storage.
    if not m.registry.Flush()
        ' Restaura também o valor em memória do registry para uma próxima tentativa.
        m.registry.Write("favorites", previous)
        m.detailHint.text = "Não foi possível salvar os favoritos. *: tentar novamente | BACK: voltar"
        return
    end if
    m.favorites = updated
    m.catalogDirty = true
    updateHint()
end sub

' O Video recebe seu próprio ContentNode. O campo content define a mídia;
' o campo control dispara a ação. Configuramos conteúdo e foco antes de play.
sub playSelected()
    if m.selectedItem = invalid then return
    content = CreateObject("roSGNode", "ContentNode")
    content.title = m.selectedItem.title
    content.url = m.selectedItem.url
    content.streamFormat = m.selectedItem.streamFormat
    m.video.content = content
    m.details.visible = false
    m.screen = "video"
    m.video.visible = true
    m.video.setFocus(true)
    m.video.control = "play"
end sub

' Eventos de state são assíncronos. Ignorar eventos fora de video evita que
' um evento atrasado de stop abra detalhes depois de voltar ao catálogo.
sub onVideoStateChanged()
    if m.screen <> "video" then return
    if m.video.state = "error"
        print "[player] id="; m.selectedItem.id; " code="; m.video.errorCode; " message="; m.video.errorMsg
        closeVideo()
        m.detailHint.text = "Vídeo indisponível. Verifique a conexão. OK: tentar novamente | BACK: voltar"
    else if m.video.state = "finished"
        closeVideo()
    end if
end sub

' Mudar o estado lógico ANTES de stop protege contra callbacks do próprio stop.
' Parar a mídia libera a reprodução; só esconder o Video deixaria o áudio ativo.
sub closeVideo()
    m.screen = "details"
    m.video.control = "stop"
    m.video.visible = false
    m.details.visible = true
    updateHint()
    m.top.setFocus(true)
end sub

' As teclas começam no node com foco e sobem na árvore quando não são tratadas.
' true consome o evento; false deixa o sistema ou outro ancestral tratá-lo.
' press=false é a soltura da tecla: ignorá-la evita executar uma ação duas vezes.
' O player mantém seus controles nativos; aqui interceptamos apenas seu BACK.
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.screen = "video" and key = "back"
        closeVideo()
        return true
    else if m.screen = "details"
        if key = "OK"
            playSelected()
            return true
        ' A tecla estrela do controle Roku chega ao código com o nome options.
        else if key = "options"
            toggleFavorite()
            return true
        else if key = "back"
            ' Aplicamos as alterações de favoritos ao voltar, sem reconstruir a
            ' lista enquanto o usuário ainda está interagindo com os detalhes.
            if m.catalogDirty
                buildCatalog()
                restoreSelection()
            end if
            m.screen = "catalog"
            m.details.visible = false
            m.status.visible = true
            m.catalog.visible = true
            m.catalog.setFocus(true)
            return true
        end if
    end if
    return false
end function

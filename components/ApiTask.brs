' Uma Task tem seu próprio contexto m. A comunicação com a cena acontece pelos
' fields de interface declarados em ApiTask.xml, e não por variáveis compartilhadas.
sub init()
    ' functionName aponta para a função executada quando control recebe RUN.
    m.top.functionName = "execute"
end sub

sub execute()
    ' pkg:/ é a raiz do pacote instalado no Roku, independente da pasta no PC.
    ' ReadAsciiFile lê o texto e ParseJson transforma o JSON em valores BrightScript.
    ' Arquivo ausente ou JSON malformado não deve ser tratado como um array válido.
    catalog = ParseJson(ReadAsciiFile("pkg:/data/catalog.json"))
    if type(catalog) <> "roArray"
        m.top.error = "Não foi possível ler o catálogo."
        return
    end if
    ' Validar o tipo antes de count evita invocar um método num valor invalid.
    if catalog.count() = 0
        m.top.error = "O catálogo está vazio."
        return
    end if
    ids = {}
    fileSystem = CreateObject("roFileSystem")
    for each item in catalog
        if type(item) <> "roAssociativeArray"
            m.top.error = "O catálogo contém um item inválido."
            return
        end if
        for each field in ["id", "title", "category", "description", "poster", "videoUrl", "streamFormat"]
            value = item[field]
            if type(value) <> "roString" and type(value) <> "String"
                m.top.error = "Campo inválido no catálogo: " + field
                return
            end if
            if value.trim() = ""
                m.top.error = "Campo vazio no catálogo: " + field
                return
            end if
        end for
        idKey = lcase(item.id)
        if ids.doesExist(idKey)
            m.top.error = "ID duplicado no catálogo: " + item.id
            return
        end if
        ids[idKey] = true
        if item.category = "Favoritos" or item.streamFormat <> "mp4"
            m.top.error = "Categoria ou formato inválido: " + item.id
            return
        end if
        if left(item.videoUrl, 8) <> "https://" or left(item.poster, 12) <> "pkg:/images/"
            m.top.error = "Endereço inválido no catálogo: " + item.id
            return
        end if
        if instr(1, item.poster, "..") > 0 or instr(1, item.poster, chr(92)) > 0
            m.top.error = "Caminho de capa inválido: " + item.id
            return
        end if
        if not fileSystem.exists(item.poster)
            m.top.error = "Capa não encontrada: " + item.id
            return
        end if
    end for
    ' Publicar o resultado dispara o observer onCatalogLoaded da MainScene.
    ' A Task prepara dados; apenas a cena monta os nodes visuais e atribui foco.
    m.top.content = catalog
end sub

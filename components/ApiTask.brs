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
    ' Publicar o resultado dispara o observer onCatalogLoaded da MainScene.
    ' A Task prepara dados; apenas a cena monta os nodes visuais e atribui foco.
    m.top.content = catalog
end sub

' Main é o ponto de entrada chamado pelo Roku ao abrir o canal.
' Este código gerencia o ciclo de vida da tela. A interface e suas interações
' ficam nos componentes SceneGraph, que possuem seus próprios scripts.
sub Main()
    ' roSGScreen hospeda a árvore SceneGraph; roMessagePort recebe seus eventos.
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    ' CreateScene usa o name do componente XML. Show torna a tela visível;
    ' o método init da MainScene cuida do carregamento inicial do catálogo.
    scene = screen.CreateScene("MainScene")
    screen.Show()

    ' wait(0, port) aguarda indefinidamente sem manter um loop consumindo CPU.
    ' Eventos de teclas são tratados pela cena; aqui só encerramos quando a tela
    ' fecha. Retornar de Main encerra a execução do canal.
    while true
        msg = wait(0, port)
        ' Verificar o tipo antes de chamar IsScreenClosed evita usar o método
        ' em um evento de outra classe. Os ifs separados tornam essa ordem explícita.
        if type(msg) = "roSGScreenEvent"
            if msg.IsScreenClosed() then return
        end if
    end while
end sub

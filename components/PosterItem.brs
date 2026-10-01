' A RowList cria instâncias deste componente para renderizar os cartões.
' O cartão só apresenta dados: selecionar e reproduzir são tarefas da MainScene.
sub init()
    m.poster = m.top.findNode("poster")
    m.label = m.top.findNode("label")
    m.focusBorder = m.top.findNode("focusBorder")
end sub

' A RowList preenche itemContent com o ContentNode do vídeo. Como os cartões
' podem ser reutilizados, este callback atualiza imagem e título a cada mudança.
sub showContent()
    item = m.top.itemContent
    if item = invalid then return
    m.poster.uri = item.hdPosterUrl
    m.label.text = item.title
end sub

' focusPercent mede o foco horizontal do item; rowFocusPercent mede o foco
' vertical da linha. Ambos variam de 0 a 1 durante as transições da RowList.
' Conferir os dois evita destacar o primeiro cartão de uma linha sem foco.
sub showFocus()
    m.focusBorder.visible = (m.top.focusPercent > 0 and m.top.rowFocusPercent > 0)
end sub

class ChatConversationListItem extends KDListItemView

  constructor:(options = {}, data)->

    options.tagName   = "li"
    options.cssClass  = "person"
    data.invitees    ?= data.conversation.invitees

    super options, data

    {conversation, @invitees} = data
    {nickname} = KD.whoami().profile

  viewAppended:->

    @title = new ChatConversationListItemTitle null, @invitees
    @title.on 'click', @bound 'toggleConversation'
    @addSubView @title

    @addSubView @menu = new ConversationMenuButton {}, @getData()
    @menu.on 'DestroyConversation', => @getDelegate().removeItem @

    @setDragHandlers()

    @conversation = new ChatConversationWidget @
    @conversation.on 'click', @conversation.bound 'takeFocus'
    @conversation.on 'NewMessageReceived', @bound 'expandConversation'

    @conversation.messageInput.on 'moveUpRequested', =>
      itemIndex = @getDelegate().getItemIndex @
      @getDelegate().emit 'moveToIndexRequested', @, itemIndex - 1
      @conversation.messageInput.setFocus()

    @conversation.messageInput.on 'moveDownRequested', =>
      itemIndex = @getDelegate().getItemIndex @
      @getDelegate().emit 'moveToIndexRequested', @, itemIndex + 1
      @conversation.messageInput.setFocus()

    @conversationWasOpen = no
    @addSubView @conversation

  setDragHandlers:->

    @on 'DragStarted', (e, state)->
      @conversationWasOpen = @conversation.isVisible()
      @_dragStarted = yes

    @on 'DragInAction', _.throttle (x, y)->
      if y isnt 0 and @_dragStarted
        @conversation.collapse()
        @setClass 'ondrag'
    , 300

    @on 'DragFinished', (event)->

      @unsetClass 'ondrag'
      @_dragStarted = no

      height = $(event.target).closest('.kdlistitemview').height() or 33
      distance = Math.round(@dragState.position.relative.y / height)

      unless distance is 0
        itemIndex = @getDelegate().getItemIndex @
        newIndex  = itemIndex + distance
        @getDelegate().emit 'moveToIndexRequested', @, newIndex

      @setEmptyDragState yes
      @conversation.expand()  if @conversationWasOpen

    @setDraggable
      handle : @title
      axis   : "y"

  toggleConversation:->
    @toggleClass 'ready'
    @conversation.toggle()
    @conversation.takeFocus()  if @conversation.isVisible()

  expandConversation:->
    @setClass 'ready'
    @conversation.expand()
    @conversation.takeFocus()

  collapseConversation:->
    @unsetClass 'ready'
    @conversation.collapse()

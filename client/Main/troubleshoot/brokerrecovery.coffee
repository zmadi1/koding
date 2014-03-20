class BrokerRecovery extends KDObject

  constructor: (options = {}, data) ->
    options.timeout ?= 10000
    super options, data

    @unsuccessfulAttempt = 0
    @broker = KD.remote.mq
    KD.utils.repeat options.timeout, @checkStatus.bind(this)

    @on "brokerNotResponding", =>
      if @unsuccessfulAttempt > 2
        @changeBroker()


  checkStatus: ->
    {timeout} = @getOptions()
    if @broker.lastTo < Date.now() - timeout
      timeout = setTimeout =>
        @unsuccessfulAttempt += 1
        @emit "brokerNotResponding"
        console.warn 'broker not responding'
      , 3000

      @broker.ping =>
        @unsuccessfulAttempt = 0
        clearTimeout timeout
        timeout = null


  changeBroker: ->
    # every time it will try to connect another broker, but here we are not
    # checking for the previous unsuccessful attempts
    @unsuccessfulAttempt = 0
    broker = @getData()
    broker.disconnect no
    brokerURL = broker.sockURL.replace("/subscribe", "")
    broker.selectAndConnect [brokerURL]
    # log while changing and send alert
    KD.logToExternal "broker connection error", broker : brokerURL


  recover: (callback) ->
    @broker.off "ready"
    @broker.once "ready", ->
      callback null

    @changeBroker()
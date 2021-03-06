utils = require('./utils')
inet = require('./inet')

inetNtoa = (buf) ->
  buf[0] + "." + buf[1] + "." + buf[2] + "." + buf[3]

inetAton = (ipStr) ->
  parts = ipStr.split(".")
  unless parts.length is 4
    null
  else
    buf = new Buffer(4)
    i = 0

    while i < 4
      buf[i] = +parts[i]
      i++
    buf
  
dgram = require 'dgram'

class LRUCache
  constructor: (@timeout, sweepInterval) ->
    that = this
    sweepFun = ->
      that.sweep()
    
    @interval = setInterval(sweepFun, sweepInterval)
    @dict = {}
    
  setItem: (key, value) ->
    cur = process.hrtime()
    @dict[key] = [value, cur]
  
  getItem: (key) ->
    v = @dict[key]
    if v
      v[1] = process.hrtime()
      return v[0]
    return null
  
  delItem: (key) ->
    delete @dict[key]
  
  sweep: ->
    utils.debug "sweeping"
    dict = @dict
    keys = Object.keys(dict)
    swept = 0
    for k in keys
      v = dict[k]
      diff = process.hrtime(v[1])
      if diff[0] > @timeout * 0.001
        swept += 1
        v0 = v[0]
        v0.close()
        delete dict[k]
    utils.debug "#{swept} keys swept"

# +----+------+------+----------+----------+----------+
# |RSV | FRAG | ATYP | DST.ADDR | DST.PORT |   DATA   |
# +----+------+------+----------+----------+----------+
# | 2  |  1   |  1   | Variable |    2     | Variable |
# +----+------+------+----------+----------+----------+

exports.createServer = (port, timeout) ->
  server = dgram.createSocket("udp4")
  clients = new LRUCache(timeout, 10 * 1000)
  
  clientKey = (localAddr, localPort, remoteAddr, remotePort) ->
    return "#{localAddr}:#{localPort}:#{remoteAddr}:#{remotePort}"

  server.on("message", (data, rinfo) ->
    console.error("server got: " + data + " from " + rinfo.address + ":" + rinfo.port)
    frag = data[2]
    utils.debug "frag:#{frag}"
    if frag != 0
      utils.wran "drop a message since frag is not 0"
      return
    addrtype = data[3]
    if addrtype is 3
      addrLen = data[4]
    else unless addrtype in [1, 4]
      utils.error "unsupported addrtype: " + addrtype
      connection.destroy()
      return
    # read address and port
    if addrtype is 1
      remoteAddr = inetNtoa(data.slice(4, 8))
      remotePort = data.readUInt16BE(8)
      headerLength = 10
    else if addrtype is 4
      remoteAddr = inet.inet_ntop(data.slice(4, 20))
      remotePort = data.readUInt16BE(20)
      headerLength = 22
    else
      remoteAddr = data.slice(5, 5 + addrLen).toString("binary")
      remotePort = data.readUInt16BE(5 + addrLen)
      headerLength = 5 + addrLen + 2
    utils.debug "UDP send to #{remoteAddr}:#{remotePort}"
    
    key = clientKey(rinfo.address, rinfo.port, remoteAddr, remotePort)
    client = clients.getItem(key)
    if not client?
      client = dgram.createSocket("udp4")
      clients.setItem(key, client)
    
      client.on "message", (data1, rinfo1) ->
        utils.debug "client got #{data1} from #{rinfo1.address}:#{rinfo1.port}"
        ipBuf = inetAton(rinfo1.address)
        header = new Buffer(10)
        header.write('\x00\x00\x00\x01', 0)
        ipBuf.copy(header, 4, 0, 4)
        header.writeUInt16BE(rinfo1.port, 8)
#        data2 = Buffer.concat([data.slice(0, headerLength), data1])
        data2 = Buffer.concat([header, data1])
        server.send data2, 0, data2.length, rinfo.port, rinfo.address, (err, bytes) ->
          utils.debug "remote to client sent"
  
      client.on "error", (err) ->
        utils.debug "error: #{err}"
      
      client.on "close", ->
        utils.debug "close"
        clients.delItem(key)

    utils.debug "pairs: #{Object.keys(clients.dict).length}"

    client.send data, headerLength, data.length - headerLength, remotePort, remoteAddr, (err, bytes) ->
      utils.debug "client to remote sent"

  )
  
  server.on("listening", ->
    address = server.address()
    console.error("server listening " + address.address + ":" + address.port)
  ) 
  
  server.bind(port)
  
  return server

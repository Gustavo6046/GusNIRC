##
# GusNIRC
#
# Gustavo6046's Node IRC (client).
##

net = require("net")
fs = require("fs")
objpath = require("object-path")

messageMatchers = [
    ["privmsg", "(([^\!]+)\!([^@]+)@([^ ]+)) PRIVMSG ([^ ]+) :(.+)", ["host", "nickname", "ident", "hostname", "channel", "message"]]
    ["join", "(([^\!]+)\!([^@]+)@([^ ]+)) JOIN (#[^ ]+).+", ["host", "nickname", "ident", "hostname", "channel"]]
    ["part", "(([^\!]+)\!([^@]+)@([^ ]+)) PART (#[^ ]+) :(.+)", ["host", "nickname", "ident", "hostname", "channel", "reason"]]
    ["notice", "(([^\!]+)\!([^@]+)@([^ ]+)) NOTICE (#[^ ]+) :(.+)", ["host", "nickname", "ident", "hostname", "channel", "message"]]
    ["quit", "(([^\!]+)\!([^@]+)@([^ ]+)) QUIT :(.+)", ["host", "nickname", "ident", "hostname", "reason"]]
    ["ping", "PING :(.+)", ["server"]]
]

class IRCMessage
    constructor: (@conn, @raw) ->
        @data = {}
        @kinds = []

        for kind in messageMatchers
            r = RegExp(kind[1], "i")

            if @raw.match(r)?
                @kinds.push(kind[0])

                groups = r.exec(@raw)
                i = 0

                for g in groups.slice(1)
                    objpath.set(@data, [kind[0], kind[2][i]], g)
                    i++

    reply: (message) =>
        if not (@data.privmsg? and @data.privmsg.channel?)
            return false

        for l in (message + '').split("\n")
            if @data.privmsg.channel is @conn.bot.nick
                @conn.send("PRIVMSG #{@data.privmsg.nickname} :#{l}")

            else
                @conn.send("PRIVMSG #{@data.privmsg.channel} :#{l}")

        return true

class CommandMatcher
    constructor: (@regexStr, @regexFlags) ->
        @exp = RegExp(@regexStr, (if @regexFlags? then @regexFlags else "i"))

    match: (raw, command, connection) =>
        if raw.match(@exp)?
            return @exp.exec(raw).slice(1)

        else
            return null

class MessageMatcher extends CommandMatcher
    constructor: (@regexStr, @regexFlags) ->
        @exp = RegExp("[^\\!]+![^@]+@[^ ]+ PRIVMSG #[^ ]+ :#{@regexStr}", (if @regexFlags? then @regexFlags else "i"))

class PrefixedMatcher extends MessageMatcher
    constructor: (@regexStr, @regexFlags) ->
        @prefix = ""

    setPrefix: (@prefix) =>

    match: (raw, command, connection) =>
        matchstr = "[^\\!]+![^@]+@[^ ]+ PRIVMSG [^ ]+ :#{(@prefix+'').replace(/[.?*+^$[\]\\(){}|-]/g, "\\$&")}#{@regexStr}"
        @exp = RegExp(matchstr, (if @regexFlags? then @regexFlags else "i"))

        m = raw.match(@exp)

        if m?
            groups = @exp.exec(raw)
            return groups

        else
            return null

class Command
    constructor: (@name, @matcher, @perform) ->
        if typeof @matcher == "string"
            @matcher = new CommandMatcher(@matcher, "i")

    receive: (raw, message, connection) =>
        @lastParsed = raw
        m = @matcher.match(raw, @, connection)

        if m?
            return @perform(message, m.slice(1), connection)

        else
            return null

class IRCConnection
    constructor: (@id, @bot, @server, @port, @account, @password, @queueTime, @autojoin) ->
        @status = "disconnected"
        @users = {}
        @logfiles = ["global.log", "logs/#{@id}.log"]
        @_buffer = ""
        @queue = []

    log: (logstring, relevant) =>
        if relevant
            for f in @logfiles
                fs.writeFileSync(f, "[#{@id} #{new Date().toISOString()}] #{logstring}\n", { flag: "a" })

        console.log("[#{@id} #{new Date().toISOString()}] #{logstring}")

    connect: =>
        @status = "connecting"
        
        @socket = new net.Socket()
        @socket.setEncoding("utf-8")

        @socket.on("end", @disconnected)
        @socket.on("data", @received)

        @socket.connect(@port, @server, @connected)

    disconnected: =>
        @status = "disconnected"
        
        @log("Disconnected.")

    connected: =>
        @log("Connected to socket.")
        @status = "initializing"

        @_mainLoop()

        @send("PASS #{@account}:#{@password}")
        @send("NICK #{@bot.nick}")
        @send("USER #{@account} +b * :#{@bot.realname}")

        @status = "motd"

    _mainLoop: =>
        if @queue.length > 0
            data = @queue.splice(0, 1)

            if data? and data isnt ""
                @socket.write(data + "\r\n")
                @log(">>> #{data}")

        setTimeout(@_mainLoop, @queueTime)

    send: (data) =>
        if data is "" or not data.match(/[^\s]/)
            return

        @queue.push(data)

    ready: =>
        @send("PRIVMSG NickServ :IDENTIFY #{@account} #{@password}")
        @send("PRIVMSG Q@CServe.quakenet.org :IDENTIFY #{@account} #{@password}")

        for c in @autojoin
            @send("JOIN #{c}")

    parse: (line) =>
        if "ping" in line.kinds
            @send("PONG :#{line.data["ping"].server}")

        if @status == "ready"
            for c in @bot.commands
                c.receive(line.raw, line, @)

        if @status == "motd"
            if line.raw.match(/[^ ]+ 376/i)?
                @status = "ready"

                @ready()

    received: (data) =>
        lines = data.split("\r\n")
        @_buffer += lines[lines.length - 1]

        for l in lines.slice(0, lines.length - 1)
            @log("<<< #{l}")

            @parse(new IRCMessage(@, if l.startsWith(":") then l.slice(1) else l))

    joinChannel: (channel, keyword) =>
        @channels.push(channel)

        if keyword?
            @send("JOIN #{channel} :#{keyword}")

        else
            @send("JOIN #{channel}")

class IRCBot
    constructor: (@nick, @ident, @realname, @queueTime, @commands) ->
        if not @ident? then @ident = "GusNIRC"
        if not @nick? then @nick = "GusNIRC"
        if not @commands? then @commands = []
        if not @realname? then @realname = "A GusNIRC Bot."

        @connections = {}

    @parseConfig: (config, commandModules) ->
        cmds = []

        for c in commandModules
            mod = require(c)

            for mc in mod
                com = new Command(mc.name, mc.matcher, mc.perform)

                if com.matcher instanceof PrefixedMatcher
                    com.matcher.setPrefix(config.global.prefix)

                cmds.push(com)

        bot = new IRCBot(config.global.nick, config.global.ident, config.global.realname, config.global.queueTime * 1000, cmds)

        for c in config.networks
            bot.addConnection(c.id, c.server, c.port, c.account, c.password, c.channels)

        return bot

    addConnection: (id, server, port, account, password, channels) =>
        if not account?
            password = null

        @connections[id] = new IRCConnection(id, @, server, port, account, password, @queueTime, channels)

    start: =>
        for _, c of @connections
            c.connect()

module.exports = {
    IRCBot: IRCBot
    IRCConnection: IRCConnection,
    Command: Command,
    CommandMatcher: CommandMatcher,
    MessageMatcher: MessageMatcher,
    PrefixedMatcher: PrefixedMatcher,
    IRCMessage: IRCMessage
}
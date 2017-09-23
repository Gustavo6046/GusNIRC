if require.resolve('../lib/markov.js') in Object.keys(require.cache)
    delete require.cache[require.resolve('../lib/markov.js')]

markov = require('../lib/markov.js')
irc = require("../irc.js")
fs = require("fs")
fr = require('follow-redirects')
h2p = require('html2plaintext')

try
    data = JSON.parse(fs.readFileSync("markov.json", { encoding: "utf-8" }))

    _mkgroups = data[0]
    mkgroups = {}

    for k, m of _mkgroups
        mkgroups[k] = markov(1).fromJSON(m)
    
    mkglisten = data[1]

catch err
    console.log("Markov loading skipped:")
    console.log(err)
    mkgroups = {}
    mkglisten = {}

saveMarkov = ->
    mkgdata = {}

    for k, v of mkgroups
        mkgdata[k] = v.getDB()

    fs.writeFileSync("markov.json", JSON.stringify([mkgdata, mkglisten]))

module.exports = [
    {
        name: "markov.mkgroup"
        matcher: new irc.PrefixedMatcher("markov mkgroup ([^ ]+)")
        perform: (msg, custom, conn) ->
            mkgroups[custom[0]] = markov(1)

            if mkglisten[msg.data.privmsg.channel]?
                mkglisten[msg.data.privmsg.channel].push(custom[0])

            else
                mkglisten[msg.data.privmsg.channel] = [custom[0]]

            msg.reply("Made Markov group #{custom[0]} succesfully. Listening for it on #{msg.data.privmsg.channel} by default...")
    }

    {
        name: "markov.train"
        matcher: new irc.MessageMatcher("((?!]=).+)")
        perform: (msg, custom, conn) ->
            if msg.data.privmsg.channel in Object.keys(mkglisten)
                for m in mkglisten[msg.data.privmsg.channel]
                    if mkgroups[m]?
                        mkgroups[m].seed(custom[0])

                    saveMarkov()
    }

    {
        name: "markov.flush"
        matcher: new irc.PrefixedMatcher("markov (?:flush|clear) ([^ ]+)")
        perform: (msg, custom, conn) ->
            if custom[0] not in Object.keys(mkgroups)
                msg.reply("No such Markov group '#{custom[0]}'!")

            else
                mkgroups[custom[0]] = markov(1)
                msg.reply("Markov group '#{custom[0]}' flushed successfully.")

                saveMarkov()
    }

    {
        name: "markov.filetrain"
        matcher: new irc.PrefixedMatcher("markov fromfile ([^ ]+) (.+)")
        perform: (msg, custom, conn) ->
            files = custom[1].split(" ")
            mk = mkgroups[custom[0]]

            if not mk?
                msg.reply("No such Markov group '#{custom[0]}'!")

            for f in files
                if not fs.exists(f)
                    msg.reply("No such file '#{f}'!")

                else
                    mk.seed(fs.readFileSync(f))

                    msg.reply("File trained to Markov successfully.")
    }

    {
        name: "markov.webtrain"
        matcher: new irc.PrefixedMatcher("markov webp ([^ ]+) (.+)")
        perform: (msg, custom, conn) ->
            sites = custom[1].split(" ")
            mk = mkgroups[custom[0]]
            msg.reply("Extracting Markov from webpages.")

            for s in sites
                if s.startsWith("https://")
                    prot = fr.https

                else
                    prot = fr.http

                    if not s.startsWith("http://")
                        m = s.match(/^(([a-z][a-z1-9\-\+\.]+\:\/\/)?)(.+)/i).slice(1)

                        if m? and m[0] not in ["http", ""]
                            msg.reply("[ERR] [markov.webtrain] #{s} - Invalid protocol: #{m[0]} (expected 'http', 'https' or default 'http')")
                            continue

                        s = "http://" + m[2]

                prot.get(s, (response) ->
                    if response.statusCode isnt 200
                        msg.reply("[ERR] [markov.webtrain] #{s} - Status #{response.statusCode}")
                        return

                    data = ""

                    response.on("data", (chunk) ->
                        data += '' + chunk
                    )

                    response.on("end", ->
                        msg.reply("[INFO] [markov.webtrain] #{s} - Request successful.")

                        try
                            txt = h2p(data)

                            try
                                mk.seed(txt)

                            catch e
                                msg.reply("[ERR] [markov.webtrain] #{s} - Error training Markov with text: #{e}")

                            msg.reply("[INFO] [markov.webtrain] #{s} - Parsed succesfully.")
                        
                        catch err
                            msg.reply("[ERR] [markov.webtrain] #{s} - Error parsing: #{err}")
                    )
                ).on("error", (e) ->
                    msg.reply("[ERR] [markov.webtrain] #{s} - #{e}")
                )
    }

    {
        name: "markov.get"
        matcher: new irc.PrefixedMatcher("markov get ([^ ]+) (.+)")
        perform: (msg, custom, conn) ->
            if custom[0] not in Object.keys(mkgroups)
                msg.reply("No such Markov group yet!")

            else
                data = "#{custom[1]} #{mkgroups[custom[0]].forward(custom[1], 80).join(" ")}"

                if data is ""
                    msg.reply("[Key not found.]")

                else
                    msg.reply(data)
    }

    {
        name: "markov.list"
        matcher: new irc.PrefixedMatcher("markov list$")
        perform: (msg, custom, conn) ->
            console.dir(mkgroups)

            msg.reply("Available Markov groups: #{Object.keys(mkgroups).join(", ")}")
    }

    {
        name: "markov.listen"
        matcher: new irc.PrefixedMatcher("markov listen ([^ ]+)")
        perform: (msg, custom, conn) ->
            if custom[0] not in Object.keys(mkgroups)
                msg.reply("No such Markov group #{custom[0]} to listen for here!")
            
            else
                if mkglisten[msg.data.privmsg.channel]?
                    mkglisten[msg.data.privmsg.channel].push(custom[0])

                else
                    mkglisten[msg.data.privmsg.channel] = [custom[0]]

                msg.reply("Now listening on #{msg.data.privmsg.channel} for Markov group #{custom[0]}.")
    }

    {
        name: "markov.deafen"
        matcher: new irc.PrefixedMatcher("markov (deafen|ignore) ([^ ]+)")
        perform: (msg, custom, conn) ->
            if mkglisten[msg.data.privmsg.channel]? and custom[1] in mkglisten[msg.data.privmsg.channel]
                mkglisten[msg.data.privmsg.channel] = mkglisten[msg.data.privmsg.channel].splice(mkglisten[msg.data.privmsg.channel].indexOf(custom[1]), 1)

                if mkglisten[msg.data.privmsg.channel] is []
                    delete mkglisten[msg.data.privmsg.channel]

                saveMarkov()

                msg.reply("Now not listening on #{msg.data.privmsg.channel} for Markov group #{custom[1]}.")

            else
                msg.reply("No such Markov group listener for this channel!")
    }

    {
        name: "markov.pick"
        matcher: new irc.PrefixedMatcher("markov (pick|random) ([^ ]+)")
        perform: (msg, custom, conn) ->
            inner = ->
                if custom[1] not in Object.keys(mkgroups)
                    msg.reply("No such Markov group yet!")

                else
                    key = mkgroups[custom[1]].pick()

                    if not key?
                        msg.reply("[Empty Markov chain...]")

                    else
                        data = mkgroups[custom[1]].forward(key, 80)

                        if (not data?)
                            msg.reply("[Empty result text... try again?]")

                        data = data.join(" ")

                        if (data.match(/^\s*$/))
                            inner()

                        else
                            msg.reply("#{msg.data.privmsg.nickname}: #{key} #{data}")

            inner()
    }
]
irc = require("../irc.js")
Crawler = require("crawler")

module.exports = [
    {
        name: "pipecrawl"
        matcher: new irc.PrefixedMatcher("pipecrawl (\\d+) (.+)") # timeout - URLs - piped command (%u = URL)

        perform: (msg, custom, conn) ->
            maxconn = Math.min(+custom[0], 35)
            urls = custom[1].split("|")[0].split(" ").filter((x) -> x != "")
            pipeCmd = custom[1].split("|")[1].split(" ").filter((x) -> x != "").join(" ")

            console.log("Crawling for websites: #{urls.join(", ")}")

            msg.reply("Crawling for websites: #{urls.join(", ")}")

            numConn = 0

            c = new Crawler({
                maxConnections: 5
                retries: 0

                callback: (error, res, done) ->
                    try
                        if error
                            msg.reply("[ERR] [pipecrawl] #{res.request.uri.href} - #{error}")
                            console.log(error)

                        else if res.statusCode isnt 200
                            msg.reply("[ERR] [pipecrawl] #{res.request.uri.href} - Status code #{res.statusCode}.")
                            console.log(error)

                        else
                            process.stdout.write("(EMULATED) ")
                            conn.received(":#{msg.data.privmsg.host} PRIVMSG #{msg.data.privmsg.channel} :]=#{pipeCmd.replace("%u", res.request.uri.href)}\r\n")

                        res.$("a").each((_, u) ->
                            u = u.attribs.href

                            if not u?
                                return

                            if not u.startsWith("http://") and not u.startsWith("http://")
                                m = u.match(/^(([a-z][a-z1-9\-\+\.]+\:\/\/)?)(.+)/i).slice(1)

                                if m?
                                    if m[0] not in ["http://", "https://", ""]
                                        msg.reply("[ERR] [pipecrawl] #{u} - Invalid protocol: #{m[0]} (expected 'http://', 'https://' or default 'http://')")
                                        return

                                    if m[0] == ""
                                        u = "#{res.request.uri.href}/#{m[2]}"

                            if numConn < maxconn
                                c.queue(u)

                            console.log(numConn, maxconn)

                            numConn++
                        )

                    catch err
                        msg.reply("[ERR] [pipecrawl] #{res.options.uri} - #{err}")

                    done()
            })

            for u in urls
                if not u.startsWith("http://") and not u.startsWith("http://")
                    m = u.match(/^(([a-z][a-z1-9\-\+\.]+\:\/\/)?)(.+)/i).slice(1)

                    if m? and m[0] not in ["http", ""]
                        msg.reply("[ERR] [pipecrawl] #{u} - Invalid protocol: #{m[0]} (expected 'http', 'https' or default 'http')")
                        continue

                    u = "http://" + m[2]

                c.queue(u)
    }
]
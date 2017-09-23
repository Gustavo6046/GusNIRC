title = require('url-to-title')
irc = require("../irc.js")
botlist = [
    "bannon3001"
    "PlotTwist"
    "asdfbot"
]

module.exports = [#{
    # name: "linkttl"
    # perform: (msg, custom, conn) ->
    #     if "bot" in msg.data.privmsg.host or msg.data.privmsg.nick in botlist then return

    #     links = msg.data.privmsg.message.match(new RegExp("(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w\\.-]*)*\\/?", "gi"))

    #     if links?
    #         conn.log("Links found: #{links.join(", ")}")

    #         parsed = []
    #         nondup = []

    #         for l in links
    #             if l not in nondup
    #                 nondup.push(l)

    #         for l in links
    #             if l in parsed
    #                 continue

    #             parsed.push(l)

    #             (() ->
    #                 m = l
    #                 n = m

    #                 if n.length > 27
    #                     n = n.slice(0, 25) + "..."

    #                 title((if m.startsWith("http") then m else "http://#{m}"), (err, title) ->
    #                     if not title?
    #                         return

    #                     title = title.replace(/[\x00-\x19]/g, '')

    #                     if title.length > 382
    #                         title = title.slice(0, 380) + "..."

    #                     if not err
    #                         msg.reply("[ #{title} ]#{if nondup.length > 1 then " - #{n}" else ""}")

    #                     else
    #                         console.log(err)
    #                 )
    #             )()

    # matcher: new irc.MessageMatcher(".*")
#}
]
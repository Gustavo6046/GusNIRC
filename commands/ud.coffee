urban = require("urban")
irc = require("../irc.js")

module.exports = [{
    name: "udict"
    perform: (msg, custom, conn) ->
        if not custom[0].startsWith(" ")
            return

        if custom[1] is ""
            query = urban.random()

        else
            query = urban(custom[1])

        query.first((data) ->
            if data?
                msg.reply("[##{data.defid}] '#{data.word}' by #{data.author} (+#{data.thumbs_up} -#{data.thumbs_down}): #{data.definition.replace("\n", "   ").slice(0, 120)} | e.g. #{data.example.replace("\n", "   ").slice(0, 95)} - #{data.permalink}")

            else
                msg.reply("Definition not found.")
        )

    matcher: new irc.PrefixedMatcher("ud( (.*))?")
}]
irc = require("../irc.js")

module.exports = [
    {
        name: "cmdlist"
        matcher: new irc.PrefixedMatcher("(list|help)")
        perform: (msg, custom, conn) ->
            msg.reply("Commands available: #{ conn.bot.cmdNames.join(', ') }. Use the 'syntax' command to learn how to invoke them!")
    }

    {
        name: "cmdsyntax"
        matcher: new irc.PrefixedMatcher("syntax (.+)")
        perform: (msg, custom, conn) ->
            for c in conn.bot.commands
                if c.name.toUpperCase() == custom[0].toUpperCase()
                    msg.reply("Regex syntax for #{custom[0]}: '#{c.matcher.regexStr}' | Matcher type: #{c.matcher.constructor.name}")

                    return

            msg.reply("No such command!")
    }

    {
        name: "flushq"
        matcher: new irc.PrefixedMatcher("flushq$")
        perform: (msg, custom, conn) ->
            conn.queue = []

            msg.reply(".")
    }
]
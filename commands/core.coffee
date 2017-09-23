irc = require("../irc.js")

module.exports = [
    {
        name: "RELOAD" # core functions are majuscule
        matcher: new irc.PrefixedMatcher("reload( (.*))?")
        perform: (msg, custom, conn) ->
            if custom[1]? and custom[1]
                conn.bot.reloadCommandsFolder(custom[1])

            else
                conn.bot.reloadCommands()

            msg.reply("Commands reloaded successfully.")
    }
]
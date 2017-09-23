irc = require("../irc.js")

ping = (msg, custom, conn) ->
    if custom[1] is "" or not custom[0]?
        msg.reply("PONG!")

    else
        msg.reply("PONG! @ #{custom[1]}")

module.exports = [{
    name: "status"
    perform: ping
    matcher: new irc.PrefixedMatcher("ping( (.*))?")
}]
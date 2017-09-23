irc = require("../irc.js")

module.exports = [{
    name: "um"
    matcher: new irc.PrefixedMatcher("um (.+)")
    perform: (msg, custom, conn) ->
        msg.reply(custom[0].split(" ").join(", um, ") + "...")
}]
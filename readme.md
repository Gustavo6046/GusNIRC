# GusNIRC
**The Node IRC**

I had a project to port the GusBot series, running on the
GusPIRC (Gustavo's Python IRC) library to Node.JS. And I
was going to use `node-irc`. Until a day...

People (rather experienced people) have told me not to use
it, because it had bugs.

So the GusNIRC experiment has born to see how far it could
get, in terms of stability, flexibility and ease of use.

# How to Install
Simply run the following command:
`npm i --save gusnirc`
Then you should be able to either use the IRC module or
run `main.js` once you got the commands and configuration.

# FAQ
## How do I add commands?
You must do a file inside the `commands` folder (or load it
manually on `new gusnirc.IRCBot(..., ["myCommands.js"])`) and
exporting like this:

    module.exports = [{
        "name": "status",
        "perform": function(msg, custom, conn) {
            conn.send("PRIVMSG "+msg.data.privmsg.channel+" :PONG @ "+custom[0]);
        },
        "matcher": new gusnirc.PrefixedMatcher("ping (.+)", "i")
    }];

The command interface can change, to get simpler. Meanwhile
resort to this :)

## How do I do the config for use with `main.js`?
Check config.example.json :)
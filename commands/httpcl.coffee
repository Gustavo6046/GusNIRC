irc = require('../irc.js')
request = require('request')

postAliases = {}

module.exports = [
    {
        name: "http.request"
        matcher: new irc.PrefixedMatcher("http req(?:uest)? ([^ ]+) ([^ ]+) (.+)")

        perform: (msg, custom, conn) ->
            request({
                method: custom[0],
                uri: custom[1],
                body: custom[2]
            }, (error, response, body) ->
                if response.statusCode == 200
                    error = new Error("Status code #{response.statusCode}")

                if error
                    msg.reply("[http.request] [#{custom[1]}] #{error.toString()}")
                    console.log(error)

                else
                    msg.reply("#[http.request] [#{custom[1]}] #{body}")
            )
    }

    {
        name: "http.execalias"
        matcher: new irc.PrefixedMatcher("http exec ([^ ]+) (.+)")

        perform: (msg, custom, conn) ->
            inp = postAliases[custom[0]].inputKey

            if inp not in ["-", "", " "] and custom[1] not in ["-", "", " "]
                bodyData = { inp: custom[1] }

            for k, v of postAliases[custom[0]].extraData
                bodyData[k] = v

            request({
                method: postAliases[custom[0]].method
                uri: postAliases[custom[0]].url
                body: bodyData
            }, (error, response, body) ->
                if response.statusCode == 200
                    error = new Error("Status code #{response.statusCode}")

                if error
                    msg.reply("[http.request] [#{custom[1]}] #{error.toString()}")
                    console.log(error)

                else
                    if postAliases[custom[0]].responseKey not in ["-", "", " "]
                        msg.reply("#[http.request] [BODY] #{custom[1]} - #{body}")

                    else
                        msg.reply("#[http.request] [INFO] #{custom[1]} - #{postAliases[custom[0]].method}ed successfully. ")
            )
    }

    {
        name: "http.alias"
        matcher: new irc.PrefixedMatcher("http (?:add|alias|addalias) ([^ ]+) ([^ ]+) ([^ ]+) (.+)")

        perform: (msg, custom, conn) ->
            data = custom[3].split("|").trim()

            if custom[0] in Object.prototype.keys(postAliases)
                msg.reply("HTTP alias already exists!")

            else
                postAliases[custom[0]] = {
                    method: custom[1]
                    uri: custom[2]
                    inputKey: data.slice(0, -1)
                    responseKey: data.slice(-1)[0]
                    extraData: {}
                }

                msg.reply("HTTP alias added.")
    }
]
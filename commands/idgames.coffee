request = require("request")
irc = require("../irc.js")
ArgParse = require("argparse").ArgumentParser

BSTAR = "\u2605"
WSTAR = "\u2606"

formatRating = (rating, max, maxStars) ->
    realRating = Math.round(rating / max * maxStars)
    res = ""

    for n in [1..maxStars]
        if n <= realRating
            res += BSTAR

        else
            res += WSTAR

    return res

idgamesData = (id) ->
    return new Promise((resolve, reject) ->
        request("https://www.doomworld.com/idgames/api/api.php?action=get&id=#{id}&out=json", (error, response, body) ->
            if error
                reject(error)

            else
                resolve(JSON.parse(body))
        )
    )

idgamesFilename = (filename) ->
    return new Promise((resolve, reject) ->
        url = "https://www.doomworld.com/idgames/api/api.php?action=get&file=#{filename}&out=json"

        request(url, (error, response, body) ->
            if error
                reject(error)

            else
                resolve(JSON.parse(body))
        )
    )

idgamesSearch = (filename, type, sort, descOrder) ->
    return new Promise((resolve, reject) ->
        url = "https://www.doomworld.com/idgames/api/api.php?action=search&query=#{filename}&dir=#{if descOrder then "desc" else "asc"}&type=#{if type? then type else "title"}&sort=#{if sort? then sort else "rating"}&out=json"
        console.log(url)

        request(url, (error, response, body) ->
            if error
                reject(error)

            else
                resolve(JSON.parse(body))
        )
    )

module.exports = [
    {
        name: "idgames.data"
        matcher: new irc.PrefixedMatcher("idg id (\\d+)")
        perform: (msg, custom, conn) ->
            idgamesData(custom[0]).then(
                ((data) ->
                    data = data.content

                    if not data?
                        msg.reply("File not found from /idgames!")

                    else
                        msg.reply("File ##{data.id} | #{data.title} | #{data.filename} weighting #{data.size}b | Added #{data.date} by #{data.author} | Rating: #{formatRating(data.rating, 5, 5)} | Download at #{data.url}".replace("\n", "   "))
                ),
                ((error) ->
                    msg.reply("Error grabbing file from idgames! (#{error})")
                )
            )
    }

    {
        name: "idgames.filename"
        matcher: new irc.PrefixedMatcher("idg fn (.+)")
        perform: (msg, custom, conn) ->
            idgamesFilename(custom[0]).then(
                ((data) ->
                    data = data.content

                    if not data?
                        msg.reply("File not found from /idgames!")

                    else
                        msg.reply("File ##{data.id} | #{data.title} | #{data.filename} weighting #{data.size}b | Added #{data.date} by #{data.author} | Rating: #{formatRating(data.rating, 5, 5)} | Download at #{data.url}".replace("\n", "   ")  )
                ),
                ((error) ->
                    msg.reply("Error grabbing file from idgames! (#{error})")
                )
            )
    }

    {
        name: "idgames.search"
        matcher: new irc.PrefixedMatcher("idg sch (.+)")
        perform: (msg, custom, conn) ->
            parser = new ArgParse({
                addHelp: true   
                version: '0.1'
                prog: "IDgames IRC Frontend"
                description: 'search function help'
            })

            parser.error = (m) ->
                throw new Error(m)

            parser.addArgument(
                ["-t", "--type"],
                {
                    help: "Search Type - What kind of search to perform. (values: filename, title, author, email, description, credits, editors, textfile) Defaults to title."
                    nargs: 1
                    required: false
                    defaultValue: 'title'
                }
            )

            parser.addArgument(
                ["-s", "--sort"],
                {
                    help: "Sort - What kind of sort to perform on the results. (values: date, filename, size, rating) Defaults to rating."
                    nargs: 1
                    required: false
                    defaultValue: "rating"
                }
            )

            parser.addArgument(
                ["-o", "--offset"],
                {
                    help: "Offset - Offset of the first result. Other results come after. Use an integer value!"
                    nargs: 1
                    required: false
                    defaultValue: 0
                }
            )

            parser.addArgument(
                ["-d", "--dir", "--order"],
                {
                    help: "'asc'endant or 'desc'endant order of queries (from sort)."
                    required: false
                    defaultValue: 'asc'
                }
            )

            parser.addArgument(
                "query",
                {
                    help: "The query on which to perform the search."
                    nargs: 1
                }
            )

            parser.addAction()

            keywords = custom[0].match(/[^\s"]+|"(?:\\"|[^"])+"/g).map((a) -> if a.match(/".+"/g) then a.slice(1, -1) else a)
            args = parser.parseArgs(keywords)

            if args.dir? and args.dir.toUpperCase() not in ["DESC", "ASC", "D", "A"]
                msg.reply("Order must be either 'desc', 'asc', 'd' or 'a'!")
                return

            bDesc = false

            if args.dir?
                bDesc = args.dir.toUpperCase() in ["D", "DESC"]

            idgamesSearch(args.query, args.type, args.sort, bDesc).then(
                ((data) ->
                    data = data.content

                    if not data?
                        msg.reply("No results found.")
                        return

                    data = data.file

                    i = 1

                    for d in data.slice(parseInt(args.offset), 3)
                        msg.reply("Result ##{i} | File ##{d.id} | #{d.title} | '#{if d.description.length <= 183 then d.description else d.description.slice(0, 180) + "..."}' | #{d.filename} weighting #{d.size}b | Added #{d.date} by #{d.author} | Rating: #{formatRating(d.rating, 5, 5)} | Download at #{d.url}".replace("\n", "   "))
                        i++

                    if data.length <= 0
                        msg.reply("No results found for that query.")
                ),
                ((error) ->
                    msg.reply("Error grabbing file from idgames! (#{error})")

                    throw error
                )
            )
    }
]
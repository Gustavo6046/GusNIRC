// Generated by CoffeeScript 1.12.6
var ArgParse, BSTAR, WSTAR, formatRating, idgamesData, idgamesFilename, idgamesSearch, irc, request;

request = require("request");

irc = require("../irc.js");

ArgParse = require("argparse").ArgumentParser;

BSTAR = "\u2605";

WSTAR = "\u2606";

formatRating = function(rating, max, maxStars) {
  var j, n, realRating, ref, res;
  realRating = Math.round(rating / max * maxStars);
  res = "";
  for (n = j = 1, ref = maxStars; 1 <= ref ? j <= ref : j >= ref; n = 1 <= ref ? ++j : --j) {
    if (n <= realRating) {
      res += BSTAR;
    } else {
      res += WSTAR;
    }
  }
  return res;
};

idgamesData = function(id) {
  return new Promise(function(resolve, reject) {
    return request("https://www.doomworld.com/idgames/api/api.php?action=get&id=" + id + "&out=json", function(error, response, body) {
      if (error) {
        return reject(error);
      } else {
        return resolve(JSON.parse(body));
      }
    });
  });
};

idgamesFilename = function(filename) {
  return new Promise(function(resolve, reject) {
    var url;
    url = "https://www.doomworld.com/idgames/api/api.php?action=get&file=" + filename + "&out=json";
    return request(url, function(error, response, body) {
      if (error) {
        return reject(error);
      } else {
        return resolve(JSON.parse(body));
      }
    });
  });
};

idgamesSearch = function(filename, type, sort, descOrder) {
  return new Promise(function(resolve, reject) {
    var url;
    url = "https://www.doomworld.com/idgames/api/api.php?action=search&query=" + filename + "&dir=" + (descOrder ? "desc" : "asc") + "&type=" + (type != null ? type : "title") + "&sort=" + (sort != null ? sort : "rating") + "&out=json";
    console.log(url);
    return request(url, function(error, response, body) {
      if (error) {
        return reject(error);
      } else {
        return resolve(JSON.parse(body));
      }
    });
  });
};

module.exports = [
  {
    name: "idgames.data",
    matcher: new irc.PrefixedMatcher("idg id (\\d+)"),
    perform: function(msg, custom, conn) {
      return idgamesData(custom[0]).then((function(data) {
        data = data.content;
        if (data == null) {
          return msg.reply("File not found from /idgames!");
        } else {
          return msg.reply(("File #" + data.id + " | " + data.title + " | " + data.filename + " weighting " + data.size + "b | Added " + data.date + " by " + data.author + " | Rating: " + (formatRating(data.rating, 5, 5)) + " | Download at " + data.url).replace("\n", "   "));
        }
      }), (function(error) {
        return msg.reply("Error grabbing file from idgames! (" + error + ")");
      }));
    }
  }, {
    name: "idgames.filename",
    matcher: new irc.PrefixedMatcher("idg fn (.+)"),
    perform: function(msg, custom, conn) {
      return idgamesFilename(custom[0]).then((function(data) {
        data = data.content;
        if (data == null) {
          return msg.reply("File not found from /idgames!");
        } else {
          return msg.reply(("File #" + data.id + " | " + data.title + " | " + data.filename + " weighting " + data.size + "b | Added " + data.date + " by " + data.author + " | Rating: " + (formatRating(data.rating, 5, 5)) + " | Download at " + data.url).replace("\n", "   "));
        }
      }), (function(error) {
        return msg.reply("Error grabbing file from idgames! (" + error + ")");
      }));
    }
  }, {
    name: "idgames.search",
    matcher: new irc.PrefixedMatcher("idg sch (.+)"),
    perform: function(msg, custom, conn) {
      var args, bDesc, keywords, parser, ref, ref1;
      parser = new ArgParse({
        addHelp: true,
        version: '0.1',
        prog: "IDgames IRC Frontend",
        description: 'search function help'
      });
      parser.error = function(m) {
        throw new Error(m);
      };
      parser.addArgument(["-t", "--type"], {
        help: "Search Type - What kind of search to perform. (values: filename, title, author, email, description, credits, editors, textfile) Defaults to title.",
        nargs: 1,
        required: false,
        defaultValue: 'title'
      });
      parser.addArgument(["-s", "--sort"], {
        help: "Sort - What kind of sort to perform on the results. (values: date, filename, size, rating) Defaults to rating.",
        nargs: 1,
        required: false,
        defaultValue: "rating"
      });
      parser.addArgument(["-o", "--offset"], {
        help: "Offset - Offset of the first result. Other results come after. Use an integer value!",
        nargs: 1,
        required: false,
        defaultValue: 0
      });
      parser.addArgument(["-d", "--dir", "--order"], {
        help: "'asc'endant or 'desc'endant order of queries (from sort).",
        required: false,
        defaultValue: 'asc'
      });
      parser.addArgument("query", {
        help: "The query on which to perform the search.",
        nargs: 1
      });
      parser.addAction();
      keywords = custom[0].match(/[^\s"]+|"(?:\\"|[^"])+"/g).map(function(a) {
        if (a.match(/".+"/g)) {
          return a.slice(1, -1);
        } else {
          return a;
        }
      });
      args = parser.parseArgs(keywords);
      if ((args.dir != null) && ((ref = args.dir.toUpperCase()) !== "DESC" && ref !== "ASC" && ref !== "D" && ref !== "A")) {
        msg.reply("Order must be either 'desc', 'asc', 'd' or 'a'!");
        return;
      }
      bDesc = false;
      if (args.dir != null) {
        bDesc = (ref1 = args.dir.toUpperCase()) === "D" || ref1 === "DESC";
      }
      return idgamesSearch(args.query, args.type, args.sort, bDesc).then((function(data) {
        var d, i, j, len, ref2;
        data = data.content;
        if (data == null) {
          msg.reply("No results found.");
          return;
        }
        data = data.file;
        i = 1;
        ref2 = data.slice(parseInt(args.offset), 3);
        for (j = 0, len = ref2.length; j < len; j++) {
          d = ref2[j];
          msg.reply(("Result #" + i + " | File #" + d.id + " | " + d.title + " | '" + (d.description.length <= 183 ? d.description : d.description.slice(0, 180) + "...") + "' | " + d.filename + " weighting " + d.size + "b | Added " + d.date + " by " + d.author + " | Rating: " + (formatRating(d.rating, 5, 5)) + " | Download at " + d.url).replace("\n", "   "));
          i++;
        }
        if (data.length <= 0) {
          return msg.reply("No results found for that query.");
        }
      }), (function(error) {
        msg.reply("Error grabbing file from idgames! (" + error + ")");
        throw error;
      }));
    }
  }
];

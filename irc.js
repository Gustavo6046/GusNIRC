// Generated by CoffeeScript 1.12.6
var Command, CommandMatcher, IRCBot, IRCConnection, IRCMessage, MessageMatcher, PrefixedMatcher, fs, messageMatchers, net, objpath,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

net = require("net");

fs = require("fs");

objpath = require("object-path");

messageMatchers = [["privmsg", "(([^\!]+)\!([^@]+)@([^ ]+)) PRIVMSG (#[^ ]+) :(.+)", ["host", "nickname", "ident", "hostname", "channel", "message"]], ["join", "(([^\!]+)\!([^@]+)@([^ ]+)) JOIN (#[^ ]+).+", ["host", "nickname", "ident", "hostname", "channel"]], ["part", "(([^\!]+)\!([^@]+)@([^ ]+)) PART (#[^ ]+) :(.+)", ["host", "nickname", "ident", "hostname", "channel", "reason"]], ["notice", "(([^\!]+)\!([^@]+)@([^ ]+)) NOTICE (#[^ ]+) :(.+)", ["host", "nickname", "ident", "hostname", "channel", "message"]], ["quit", "(([^\!]+)\!([^@]+)@([^ ]+)) QUIT :(.+)", ["host", "nickname", "ident", "hostname", "reason"]], ["ping", "PING :(.+)", ["server"]]];

IRCMessage = (function() {
  function IRCMessage(conn, raw1) {
    var g, groups, i, j, k, kind, len, len1, r, ref;
    this.conn = conn;
    this.raw = raw1;
    this.reply = bind(this.reply, this);
    this.data = {};
    this.kinds = [];
    for (j = 0, len = messageMatchers.length; j < len; j++) {
      kind = messageMatchers[j];
      r = RegExp(kind[1], "i");
      if (this.raw.match(r) != null) {
        this.kinds.push(kind[0]);
        groups = r.exec(this.raw);
        i = 0;
        ref = groups.slice(1);
        for (k = 0, len1 = ref.length; k < len1; k++) {
          g = ref[k];
          objpath.set(this.data, [kind[0], kind[2][i]], g);
          i++;
        }
      }
    }
  }

  IRCMessage.prototype.reply = function(message) {
    var j, l, len, ref;
    if (!((this.data.privmsg != null) && (this.data.privmsg.channel != null))) {
      return false;
    }
    ref = (message + '').split("\n");
    for (j = 0, len = ref.length; j < len; j++) {
      l = ref[j];
      this.conn.send("PRIVMSG " + this.data.privmsg.channel + " :" + l);
    }
    return true;
  };

  return IRCMessage;

})();

CommandMatcher = (function() {
  function CommandMatcher(regexStr, regexFlags) {
    this.regexStr = regexStr;
    this.regexFlags = regexFlags;
    this.match = bind(this.match, this);
    this.exp = RegExp(this.regexStr, (this.regexFlags != null ? this.regexFlags : "i"));
  }

  CommandMatcher.prototype.match = function(raw, command, connection) {
    if (raw.match(this.exp) != null) {
      return this.exp.exec(raw).slice(1);
    } else {
      return null;
    }
  };

  return CommandMatcher;

})();

MessageMatcher = (function(superClass) {
  extend(MessageMatcher, superClass);

  function MessageMatcher(regexStr, regexFlags) {
    this.regexStr = regexStr;
    this.regexFlags = regexFlags;
    this.exp = RegExp("[^\\!]+![^@]+@[^ ]+ PRIVMSG #[^ ]+ :" + this.regexStr, (this.regexFlags != null ? this.regexFlags : "i"));
  }

  return MessageMatcher;

})(CommandMatcher);

PrefixedMatcher = (function(superClass) {
  extend(PrefixedMatcher, superClass);

  function PrefixedMatcher(regexStr, regexFlags) {
    this.regexStr = regexStr;
    this.regexFlags = regexFlags;
    this.match = bind(this.match, this);
    this.setPrefix = bind(this.setPrefix, this);
    this.prefix = "";
  }

  PrefixedMatcher.prototype.setPrefix = function(prefix) {
    this.prefix = prefix;
  };

  PrefixedMatcher.prototype.match = function(raw, command, connection) {
    var groups, m, matchstr;
    matchstr = "[^\\!]+![^@]+@[^ ]+ PRIVMSG #[^ ]+ :" + ((this.prefix + '').replace(/[.?*+^$[\]\\(){}|-]/g, "\\$&")) + this.regexStr;
    this.exp = RegExp(matchstr, (this.regexFlags != null ? this.regexFlags : "i"));
    m = raw.match(this.exp);
    if (m != null) {
      groups = this.exp.exec(raw);
      return groups;
    } else {
      return null;
    }
  };

  return PrefixedMatcher;

})(MessageMatcher);

Command = (function() {
  function Command(name, matcher, perform) {
    this.name = name;
    this.matcher = matcher;
    this.perform = perform;
    this.receive = bind(this.receive, this);
    if (typeof this.matcher === "string") {
      this.matcher = new CommandMatcher(this.matcher, "i");
    }
  }

  Command.prototype.receive = function(raw, message, connection) {
    var m;
    this.lastParsed = raw;
    m = this.matcher.match(raw, this, connection);
    if (m != null) {
      connection.log("Executing " + this.name);
      return this.perform(message, m.slice(1), connection);
    } else {
      return null;
    }
  };

  return Command;

})();

IRCConnection = (function() {
  function IRCConnection(id1, bot1, server1, port1, account1, password1, queueTime, autojoin) {
    this.id = id1;
    this.bot = bot1;
    this.server = server1;
    this.port = port1;
    this.account = account1;
    this.password = password1;
    this.queueTime = queueTime;
    this.autojoin = autojoin;
    this.joinChannel = bind(this.joinChannel, this);
    this.received = bind(this.received, this);
    this.parse = bind(this.parse, this);
    this.ready = bind(this.ready, this);
    this.send = bind(this.send, this);
    this._mainLoop = bind(this._mainLoop, this);
    this.connected = bind(this.connected, this);
    this.disconnected = bind(this.disconnected, this);
    this.connect = bind(this.connect, this);
    this.log = bind(this.log, this);
    this.status = "disconnected";
    this.users = {};
    this.logfiles = ["global.log", "logs/" + this.id + ".log"];
    this._buffer = "";
    this.queue = [];
  }

  IRCConnection.prototype.log = function(logstring, relevant) {
    var f, j, len, ref;
    if (relevant) {
      ref = this.logfiles;
      for (j = 0, len = ref.length; j < len; j++) {
        f = ref[j];
        fs.writeFileSync(f, "[" + this.id + " " + (new Date().toISOString()) + "] " + logstring + "\n", {
          flag: "a"
        });
      }
    }
    return console.log("[" + this.id + " " + (new Date().toISOString()) + "] " + logstring);
  };

  IRCConnection.prototype.connect = function() {
    this.status = "connecting";
    this.socket = new net.Socket();
    this.socket.setEncoding("utf-8");
    this.socket.on("end", this.disconnected);
    this.socket.on("data", this.received);
    return this.socket.connect(this.port, this.server, this.connected);
  };

  IRCConnection.prototype.disconnected = function() {
    this.status = "disconnected";
    return this.log("Disconnected.");
  };

  IRCConnection.prototype.connected = function() {
    this.log("Connected to socket.");
    this.status = "initializing";
    this._mainLoop();
    this.send("PASS " + this.account + ":" + this.password);
    this.send("NICK " + this.bot.nick);
    this.send("USER " + this.account + " +b * :" + this.bot.realname);
    return this.status = "motd";
  };

  IRCConnection.prototype._mainLoop = function() {
    var data;
    if (this.queue.length > 0) {
      data = this.queue.splice(0, 1);
      if ((data != null) && data !== "") {
        this.socket.write(data + "\r\n");
        this.log(">>> " + data);
      }
    }
    return setTimeout(this._mainLoop, this.queueTime);
  };

  IRCConnection.prototype.send = function(data) {
    if (data === "" || !data.match(/[^\s]/)) {
      return;
    }
    return this.queue.push(data);
  };

  IRCConnection.prototype.ready = function() {
    var c, j, len, ref, results;
    this.send("PRIVMSG NickServ :IDENTIFY " + this.account + " " + this.password);
    this.send("PRIVMSG Q@CServe.quakenet.org :IDENTIFY " + this.account + " " + this.password);
    ref = this.autojoin;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      c = ref[j];
      results.push(this.send("JOIN " + c));
    }
    return results;
  };

  IRCConnection.prototype.parse = function(line) {
    var c, j, len, ref;
    if (indexOf.call(line.kinds, "ping") >= 0) {
      this.send("PONG :" + line.data["ping"].server);
    }
    if (this.status === "ready") {
      ref = this.bot.commands;
      for (j = 0, len = ref.length; j < len; j++) {
        c = ref[j];
        c.receive(line.raw, line, this);
      }
    }
    if (this.status === "motd") {
      if (line.raw.match(/[^ ]+ 376/i) != null) {
        this.status = "ready";
        return this.ready();
      }
    }
  };

  IRCConnection.prototype.received = function(data) {
    var j, l, len, lines, ref, results;
    lines = data.split("\r\n");
    this._buffer += lines[lines.length - 1];
    ref = lines.slice(0, lines.length - 1);
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      l = ref[j];
      this.log("<<< " + l);
      results.push(this.parse(new IRCMessage(this, l.startsWith(":") ? l.slice(1) : l)));
    }
    return results;
  };

  IRCConnection.prototype.joinChannel = function(channel, keyword) {
    this.channels.push(channel);
    if (keyword != null) {
      return this.send("JOIN " + channel + " :" + keyword);
    } else {
      return this.send("JOIN " + channel);
    }
  };

  return IRCConnection;

})();

IRCBot = (function() {
  function IRCBot(nick, ident, realname, queueTime, commands) {
    this.nick = nick;
    this.ident = ident;
    this.realname = realname;
    this.queueTime = queueTime;
    this.commands = commands;
    this.start = bind(this.start, this);
    this.addConnection = bind(this.addConnection, this);
    if (this.ident == null) {
      this.ident = "GusNIRC";
    }
    if (this.nick == null) {
      this.nick = "GusNIRC";
    }
    if (this.commands == null) {
      this.commands = [];
    }
    if (this.realname == null) {
      this.realname = "A GusNIRC Bot.";
    }
    this.connections = {};
  }

  IRCBot.parseConfig = function(config, commandModules) {
    var bot, c, cmds, com, j, k, len, len1, len2, mc, mod, n, ref;
    cmds = [];
    for (j = 0, len = commandModules.length; j < len; j++) {
      c = commandModules[j];
      mod = require(c);
      for (k = 0, len1 = mod.length; k < len1; k++) {
        mc = mod[k];
        com = new Command(mc.name, mc.matcher, mc.perform);
        if (com.matcher instanceof PrefixedMatcher) {
          com.matcher.setPrefix(config.global.prefix);
        }
        cmds.push(com);
      }
    }
    bot = new IRCBot(config.global.nick, config.global.ident, config.global.realname, config.global.queueTime * 1000, cmds);
    ref = config.networks;
    for (n = 0, len2 = ref.length; n < len2; n++) {
      c = ref[n];
      bot.addConnection(c.id, c.server, c.port, c.account, c.password, c.channels);
    }
    return bot;
  };

  IRCBot.prototype.addConnection = function(id, server, port, account, password, channels) {
    if (account == null) {
      password = null;
    }
    return this.connections[id] = new IRCConnection(id, this, server, port, account, password, this.queueTime, channels);
  };

  IRCBot.prototype.start = function() {
    var _, c, ref, results;
    ref = this.connections;
    results = [];
    for (_ in ref) {
      c = ref[_];
      results.push(c.connect());
    }
    return results;
  };

  return IRCBot;

})();

module.exports = {
  IRCBot: IRCBot,
  IRCConnection: IRCConnection,
  Command: Command,
  CommandMatcher: CommandMatcher,
  MessageMatcher: MessageMatcher,
  PrefixedMatcher: PrefixedMatcher,
  IRCMessage: IRCMessage
};
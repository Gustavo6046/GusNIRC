// Generated by CoffeeScript 1.12.6
var EventEmitter, MushMatch, SMWBot, SMWDamageType, SMWGame, SMWGametype, SMWPlayer, SMWWeapon, botNames, fs, games, gametypeOf, gametypes, irc, moreOrLess, randomChance, subclasses,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

irc = require("../irc.js");

EventEmitter = require("events");

fs = require("fs");

botNames = (fs.readFileSync("etc/botnames.txt") + '').split("\n");

moreOrLess = function(num) {
  return (Math.random() * 2 - 1) * num;
};

randomChance = function(percent) {
  if (percent === 0) {
    return false;
  }
  if (percent === 100) {
    return true;
  }
  return Math.random() <= percent / 100;
};

subclasses = function(a, b) {
  return (a === b) || (a.prototype(instaneOf(b)));
};

gametypes = {};

games = {};

SMWDamageType = (function() {
  function SMWDamageType(message1) {
    this.message = message1;
    this.obituary = bind(this.obituary, this);
  }

  SMWDamageType.prototype.obituary = function(weapon, other, damage) {
    return this.message.replace("%w", weapon.name).replace("%o", other.name).replace("%k", weapon.owner.name).replace("%d", damage).replace("%%", "%");
  };

  return SMWDamageType;

})();

SMWWeapon = (function() {
  function SMWWeapon(game, owner) {
    this.game = game;
    this.owner = owner;
    this.useAmmo = bind(this.useAmmo, this);
    this.altShoot = bind(this.altShoot, this);
    this.shoot = bind(this.shoot, this);
    this.sendDamage = bind(this.sendDamage, this);
    this.accuracy = 100;
    this.numAmmo = 15;
    this.damage = 25;
    this.damageRand = 9;
    this.altDamage = 40;
    this.altDamageRand = 18;
    this.ammoUse = 1;
    this.altAmmoUse = 2;
    this.name = "Standard Gun";
    this.properties = {};
    this.cost = 20;
    this.damageType = new SMWDamageType("%k shot %o down generically!");
    this.altDamageType = new SMWDamageType("%k shot %o down quickier!");
  }

  SMWWeapon.prototype.sendDamage = function(other, instigator, damage, dtype) {
    this.game.reply(instigator.name + " shot " + other.name + " with a(n) " + this.name + "!");
    return this.game.gametype.gameEvent("takeDamage", [other, instigator, damage, dtype]);
  };

  SMWWeapon.prototype.shoot = function(other) {
    if (!this.canHit(other) || !this.useAmmo(this.ammoUse)) {
      return false;
    }
    this.sendDamage(other, this.owner, damage + moreOrLess(damageRand), this.myDamageType);
    return true;
  };

  SMWWeapon.prototype.altShoot = function(other) {
    if (!this.canHit(other) || !this.useAmmo(this.altAmmoUse)) {
      return false;
    }
    this.sendDamage(other, this.owner, altDamage + moreOrLess(altDamageRand), this.altDamageType);
    return true;
  };

  SMWWeapon.prototype.canHit = function(other) {
    var b;
    b = randomChance(accuracy);
    if (b == null) {
      this.game.reply(this.owner.name + "'s " + this.name + " misses " + other.name + "!");
    }
    return b;
  };

  SMWWeapon.prototype.rateSelf = function(other) {
    return moreOrLess(50);
  };

  SMWWeapon.prototype.useAmmo = function(amount) {
    if (this.numAmmo < amount) {
      this.game.reply(ownwer + "'s " + name + " does not have enough ammo (" + this.numAmmo + "/" + amount + ") to fire!");
      return false;
    }
    this.numAmmo -= amount;
    return true;
  };

  return SMWWeapon;

})();

SMWGametype = (function() {
  SMWGametype.keyName = "default";

  SMWGametype.prototype.initName = function() {
    return "default";
  };

  SMWGametype.prototype.initProps = function() {};

  function SMWGametype(game) {
    this.game = game;
    this.gameEvent = bind(this.gameEvent, this);
    this.initProps();
    this.gameName = this.initName();
    this.events = {};
  }

  SMWGametype.prototype.initPlayer = function(player) {};

  SMWGametype.prototype.initRatedGame = function() {
    return this.game.deadPlayers = [];
  };

  SMWGametype.prototype.gameEvent = function(event, args) {
    if (this.events[event] != null) {
      return this.events[event](this, args);
    }
  };

  SMWGametype.prototype.onDeath = function(player) {};

  SMWGametype.prototype.scoreKill = function(player, killer) {};

  SMWGametype.prototype.attitudeTo = function(from, other) {
    return 0;
  };

  return SMWGametype;

})();

MushMatch = (function(superClass) {
  extend(MushMatch, superClass);

  function MushMatch() {
    this.onDeath = bind(this.onDeath, this);
    this.checkWinCondition = bind(this.checkWinCondition, this);
    this.initProps = bind(this.initProps, this);
    return MushMatch.__super__.constructor.apply(this, arguments);
  }

  MushMatch.keyName = "Warzone";

  MushMatch.prototype.initProps = function() {
    this.allWeapons = [SMWWeapon];
    this.defaultWeapons = [];
    return this.events = {
      takeDamage: (function(gametype, other, instigator, damage, dtype) {
        other.attributes.health -= damage;
        if (other.attributes.health < 0) {
          gametype.game.reply(dtype.obituary(this, other, damage));
          gametype.scoreKill(other, instigator);
          return gametype.game.killPlayer(other.name);
        }
      }),
      infect: (function(gametype, other, target) {
        target.attributes["bMush"] = true;
        other.attributes.money += 10;
        return gametype.game.reply(target.name + " was infected by " + other.name + "! They are now mush! +10$");
      }),
      aids: (function(gametype, other, target, weapon) {
        var immuneDmg;
        immuneDmg = weapon.properties.aidsPower + moreOrless(weapon.properties.aidsMutation);
        target.attributes["immune"] -= immuneDmg;
        gametype.game.reply(other.name + " shot an AIDS BIC (Ballistic Injection Container) into " + target.name + "! It took " + immuneDmg + " immune damage! They now has a quantified immune level of " + target.attributes["immune"] + " in the classic Rehermann scale!");
        if (target.attributes["immune"] <= 0) {
          gametype.game.reply(target.name + " received an AIDS overdose!");
          return target.kill();
        }
      }),
      spike: (function(gametype, other, target) {
        var immuneDmg;
        if (!other.bIsMush) {
          return gametype.game.reply(other.name + " forgot they are a human!");
        } else if (randomChance(20)) {
          return gametype.game.reply(other.name + " fails to extract a spore for infection!");
        } else {
          immuneDmg = 1.5 + moreOrLess(0.75);
          gametype.game.reply(other.name + " extracts a spore and spikes " + target.name + " discreetly! They receive " + immuneDmg + " damage!");
          target.attributes["immune"] -= immuneDmg;
          if (target.attributes["immune"] <= 0) {
            return gametype.gameEvent("infect", [other, target]);
          }
        }
      })
    };
  };

  MushMatch.prototype.checkWinCondition = function() {
    var hasHuman, hasMush, i, len, p, ref;
    hasMush = hasHuman = false;
    ref = this.game.alivePlayers();
    for (i = 0, len = ref.length; i < len; i++) {
      p = ref[i];
      if (p.attributes.bMush) {
        hasMush = true;
      }
      if (!p.attributes.bMush) {
        hasHuman = true;
      }
    }
    if (!(hasMush || hasHuman)) {
      return this.game.reply("Everyone is dead or otherwise out of the game! It's a tie!");
    } else if (!hasMush) {
      return this.game.reply("Humans win!!");
    } else if (!hasHuman) {
      return this.game.reply("Mushes win!");
    }
  };

  MushMatch.prototype.onDeath = function(player) {
    return this.checkWinCondition();
  };

  MushMatch.prototype.scoreKill = function(player, killer) {
    return killer.attributes.money += 8;
  };

  MushMatch.prototype.attitudeTo = function(from, other) {
    if (other.attributes.bMush === from.attributes.bMush) {
      return 1;
    } else {
      return 2;
    }
  };

  MushMatch.prototype.initPlayer = function(player) {
    return {
      bMush: randomChance(30),
      weapons: (function() {
        var k, ref, res, v;
        res = {};
        ref = this.defaultWeapons;
        for (k in ref) {
          v = ref[k];
          res[k] = new v(this.game, player);
        }
        return res;
      })(),
      health: 100,
      maxHealth: 100,
      immune: 10,
      money: 35
    };
  };

  return MushMatch;

})(SMWGametype);

SMWGame = (function() {
  function SMWGame(conn1, channel1, gametype1, reply) {
    this.conn = conn1;
    this.channel = channel1;
    this.gametype = gametype1;
    this.reply = reply;
    this.initPlayer = bind(this.initPlayer, this);
    this.killPlayer = bind(this.killPlayer, this);
    this.addPlayer = bind(this.addPlayer, this);
    this.getPlayer = bind(this.getPlayer, this);
    this.sendMessage = bind(this.sendMessage, this);
    this.passTurn = bind(this.passTurn, this);
    this.startGame = bind(this.startGame, this);
    this.joinMsg = bind(this.joinMsg, this);
    this.addBot = bind(this.addBot, this);
    this.onDeath = bind(this.onDeath, this);
    this.alivePlayers = bind(this.alivePlayers, this);
    this.stopGame = bind(this.stopGame, this);
    if (games[this.conn][this.channel] != null) {
      this.sendMessage("Error: Game already running on this channel! (" + games[this.channel].gametype.gameName + ")");
      return;
    }
    games[this.conn][this.channel] = this;
    this.players = {};
    this.turns = [];
    this.deadPlayers = [];
    this.currentTurn = 0;
  }

  SMWGame.prototype.stopGame = function() {
    games[this.conn][this.channel] = void 0;
    if (games[this.conn] === {}) {
      return games[this.conn] = void 0;
    }
  };

  SMWGame.prototype.alivePlayers = function() {
    var _, p;
    return [
      (function() {
        var ref, results;
        ref = this.players;
        results = [];
        for (_ in ref) {
          p = ref[_];
          results.push(indexOf.call(this.deadPlayers, p) < 0 ? p : null);
        }
        return results;
      }).call(this)
    ].filter(function(x) {
      return x != null;
    });
  };

  SMWGame.prototype.onDeath = function(player) {
    return this.gametype.onDeath(player);
  };

  SMWGame.prototype.addBot = function(name) {
    this.players[name.toLowerCase()] = new SMWBot(this, playerName);
    return this.turns.push(this.players[name.toLowerCase()]);
  };

  SMWGame.prototype.addBots = function(many) {
    var _, i, ref, results;
    results = [];
    for (_ = i = 1, ref = many; 1 <= ref ? i <= ref : i >= ref; _ = 1 <= ref ? ++i : --i) {
      results.push(addbot(botNames[Math.floor(Math.random() * (botNames.length - 1))]));
    }
    return results;
  };

  SMWGame.prototype.joinMsg = function(player) {
    return this.gametype.joinMessage(player);
  };

  SMWGame.prototype.startGame = function() {
    this.gametype.initRatedGame();
    this.deadPlayers = [];
    return this.currentTurn = 0;
  };

  SMWGame.prototype.passTurn = function() {
    var ref;
    while (ref = turns[this.currentTurn], indexOf.call(this.deadPlayers, ref) < 0) {
      this.currentTurn++;
    }
    if (this.currentTurn >= this.turns.length) {
      this.currentTurn = 0;
    }
    return this.turns[this.currentTurn].onTurn();
  };

  SMWGame.prototype.sendMessage = function(message) {
    return this.conn.send("PRIVMSG " + this.channel + " :" + message);
  };

  SMWGame.prototype.getPlayer = function(playerName) {
    var p;
    p = this.players[playerName.toLowerCase()];
    if (indexOf.call(this.deadPlayers, p) >= 0) {
      return null;
    } else {
      return p;
    }
  };

  SMWGame.prototype.addPlayer = function(playerName) {
    var ref, x;
    if ((ref = playerName.toLowerCase()) === (function() {
      var i, len, ref1, results;
      ref1 = this.deadPlayers;
      results = [];
      for (i = 0, len = ref1.length; i < len; i++) {
        x = ref1[i];
        results.push(x.name.toLowerCase());
      }
      return results;
    }).call(this)) {
      msg.reply("You can't join: you're dead or otherwise excluded until game restarts!");
    }
    this.players[playerName.toLowerCase()] = new SMWPlayer(this, playerName);
    return this.turns.push(this.players[playerName.toLowerCase()]);
  };

  SMWGame.prototype.killPlayer = function(playername) {
    return this.players[playerName.toLowerCase()].kill();
  };

  SMWGame.prototype.initPlayer = function(player) {
    return this.gametype.initPlayer(player);
  };

  SMWGame.findGame = function(conn, channel) {
    return games[conn][channel];
  };

  return SMWGame;

})();

SMWPlayer = (function() {
  function SMWPlayer(game, name1) {
    this.game = game;
    this.name = name1;
    this.kill = bind(this.kill, this);
    this.ready = false;
    this.attributes = this.game.initPlayer(this);
    if (this.attributes == null) {
      this.attributes = {};
    }
    this.game.sendMessage("Welcome to the " + this.game.gametype.gameName + " game, " + this.name + "! " + (this.game.joinMsg(this)));
  }

  SMWPlayer.prototype.kill = function() {
    this.game.sendMessage(this.name + " is out of the game!");
    this.game.deadPlayers.push(this.name.toLowerCase);
    return this.game.onDeath(this);
  };

  SMWPlayer.prototype.onTurn = function() {};

  return SMWPlayer;

})();

SMWBot = (function(superClass) {
  extend(SMWBot, superClass);

  function SMWBot() {
    return SMWBot.__super__.constructor.apply(this, arguments);
  }

  SMWBot.prototype.onTurn = function() {
    return this.game.passTurn();
  };

  return SMWBot;

})(SMWPlayer);

gametypeOf = function(name) {
  console.dir(gametypes);
  return gametypes[name.toLowerCase()];
};

module.exports = {
  SMWPlayer: SMWPlayer,
  SMWGame: SMWGame,
  SMWGametype: SMWGametype,
  SMWBot: SMWBot,
  SMWWeapon: SMWWeapon,
  SMWDamageType: SMWDamageType,
  gametypeOf: gametypeOf
};
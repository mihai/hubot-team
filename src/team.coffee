# Description:
#   Create a team using hubot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_TEAM_ADMIN - A comma separate list of user names
#
# Commands:
#   hubot create <team_name> team - create team called <team_name>
#   hubot (delete|remove) <team_name> team - delete team called <team_name>
#   hubot list teams - list all existing teams
#   hubot <team_name> team +1 - add me to the team
#   hubot <team_name> team -1 - remove me from the team
#   hubot <team_name> team add (me|<user>) - add me or <user> to team
#   hubot <team_name> team remove (me|<user>) - remove me or <user> from team
#   hubot <team_name> team count - list the current size of the team
#   hubot <team_name> team (list|show) - list the people in the team
#   hubot <team_name> team (empty|clear) - clear team list
#
# Author:
#   mihai

config =
  admin_list: process.env.HUBOT_TEAM_ADMIN,
  default_team_label: '__default__'

module.exports = (robot) ->
  robot.brain.data.teams ||= {}

  unless config.admin_list?
    robot.logger.warning 'The HUBOT_TEAM_ADMIN environment variable not set'

  if config.admin_list?
    admins = config.admin_list.split ','
  else
    admins = []

  teamSize = (team_name, msg) ->
    return false unless teamExists(team_name, msg)
    robot.brain.data.teams[team_name].length

  teamLabel = (team_name) ->
    label = team_name unless team_name is config.default_team_label
    message = if label then "`#{label}` team" else "team"
    return message

  addUserToTeam = (user, team_name, msg) ->
    if not team_name
      robot.brain.data['teams'][config.default_team_label] ||= []
      team_name = config.default_team_label
    else
      return unless teamExists(team_name, msg)

    if user in robot.brain.data.teams[team_name]
      msg.send "#{user} already in the #{teamLabel(team_name)}"
    else
      count = teamSize(team_name, msg)
      if count > 0
        countMessage = ", " + count
        countMessage += " others are in" if count > 1
        countMessage += " other is in" if count == 1

      robot.brain.data.teams[team_name].push(user)

      message = "#{user} added to the #{teamLabel(team_name)}"
      message += countMessage if countMessage
      msg.send message

  addTeam = (team_name, msg) ->
    if robot.brain.data.teams[team_name]
      msg.send "#{teamLabel(team_name)} already exists"
    else
      robot.brain.data['teams'][team_name] = []
      msg.send "#{teamLabel(team_name)} created, add some people to it"

  removeUserFromTeam = (user, team_name, msg) ->
    team_name = config.default_team_label unless team_name
    return unless teamExists(team_name, msg)

    if user not in robot.brain.data.teams[team_name]
      msg.send "#{user} already out of the #{teamLabel(team_name)}"
    else
      user_index = robot.brain.data.teams[team_name].indexOf(user)
      robot.brain.data.teams[team_name].splice(user_index, 1)
      count = teamSize(team_name, msg)
      countMessage = ", " + count + " remaining" if count > 0
      message = "#{user} removed from the #{teamLabel(team_name)}"
      message += countMessage if countMessage
      msg.send message

  teamExists = (team_name, msg) ->
    return true if team_name is config.default_team_label

    if robot.brain.data.teams[team_name]
      true
    else
      msg.send "#{teamLabel(team_name)} does not exist"
      false

  ##
  ## hubot create <team_name> team - create team called <team_name>
  ##
  robot.respond /create (\S*) team ?.*/i, (msg) ->
    team_name = msg.match[1]
    addTeam(team_name, msg)

  ##
  ## hubot (delete|remove) <team_name> team - delete team called <team_name>
  ##
  robot.respond /(delete|remove) (\S*) team ?.*/i, (msg) ->
    team_name = msg.match[2]
    return unless teamExists(team_name, msg)

    if msg.message.user.name in admins
      unless team_name is config.default_team_label
        delete robot.brain.data.teams[team_name]
        msg.send "Team `#{team_name}` removed"
    else
      msg.reply "Sorry, only admins can remove teams"

  ##
  ## hubot list teams - list all existing teams
  ##
  robot.respond /list teams ?.*/i, (msg) ->
    team_count = Object.keys(robot.brain.data.teams).length
    team_count = team_count - 1 if robot.brain.data.teams[config.default_team_label]

    if team_count > 0
      message = "Teams:\n"

      for team of robot.brain.data.teams
        continue if team is config.default_team_label
        size = teamSize(team)
        if size > 0
          message += "`#{team}` (#{size} total)\n"
          for user in robot.brain.data.teams[team]
            message += "- #{user}\n"
          message += "\n"
        else
          message += "`#{team}` (empty)\n"

    else
      message = "No team was created so far"

    msg.send message

  ##
  ## hubot <team_name> team add (me|<user>) - add me or <user> to team
  ##
  robot.respond /(\S*)? team add (\S*) ?.*/i, (msg) ->
    team_name = msg.match[1]
    user = msg.match[2]
    if user.toLocaleLowerCase() == "me"
      user = msg.message.user.name
    addUserToTeam(user, team_name, msg)

  ##
  ## hubot <team_name> team +1 - add me to the team
  ##
  robot.respond /(\S*)? team \+1 ?.*/i, (msg) ->
    team_name = msg.match[1]
    addUserToTeam(msg.message.user.name, team_name, msg)

  ##
  ## hubot <team_name> team remove (me|<user>) - remove me or <user> from team
  ##
  robot.respond /(\S*)? team remove (\S*) ?.*/i, (msg) ->
    team_name = msg.match[1]
    user = msg.match[2]
    if user.toLocaleLowerCase() == "me"
      user = msg.message.user.name
    removeUserFromTeam(user, team_name, msg)

  ##
  ## hubot <team_name> team -1 - remove me from the team
  ##
  robot.respond /(\S*)? team -1/i, (msg) ->
    team_name = msg.match[1]
    removeUserFromTeam(msg.message.user.name, team_name, msg)

  ##
  ## hubot <team_name> team count - list the current size of the team
  ##
  robot.respond /(\S*)? team count$/i, (msg) ->
    team_name = msg.match[1] || config.default_team_label
    return unless teamExists(team_name)
    msg.send "#{teamSize(team_name, msg)} people are currently in the team"

  ##
  ## hubot <team_name> team (list|show) - list the people in the team
  ##
  robot.respond /(\S*)? team (list|show)$/i, (msg) ->
    team_name = msg.match[1] || config.default_team_label
    return unless teamExists(team_name)
    count = teamSize(team_name, msg)
    if count == 0
      msg.send "There is no one in the #{teamLabel(team_name)} currently"
    else
      position = 0
      message = "#{teamLabel(team_name)} (#{count} total):\n"
      for user in robot.brain.data.teams[team_name]
        position += 1
        message += "#{position}. #{user}\n"
      msg.send message

  ##
  ## hubot <team_name> team (empty|clear) - clear team list
  ##
  robot.respond /(\S*)? team (clear|empty)$/i, (msg) ->
    team_name = msg.match[1] || config.default_team_label
    if msg.message.user.name in admins
      robot.brain.data.teams[team_name] = []
      msg.send "#{teamLabel(team_name)} list cleared"
    else
      msg.reply "Sorry, only admins can clear the team members list"

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
  admin_list: process.env.HUBOT_TEAM_ADMIN

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

  addUserToTeam = (user, team_name, msg) ->
    return unless teamExists(team_name, msg)

    if user in robot.brain.data.teams[team_name]
      msg.send "#{user} already in the #{team_name}"
    else
      count = teamSize(team_name, msg)
      if count > 0
        countMessage = ", " + count
        countMessage += " others are in" if count > 1
        countMessage += " other is in" if count == 1

      robot.brain.data.teams[team_name].push(user)

      message = "#{user} added to the team"
      message += countMessage if countMessage
      msg.send message

  addTeam = (team_name, msg) ->
    if robot.brain.data.teams[team_name]
      msg.send "#{team_name} team already exists"
    else
      robot.brain.data['teams'][team_name] = []
      msg.send "#{team_name} team created, add some people to it"

  listTeams = (msg) ->
    team_count = Object.keys(robot.brain.data.teams).length

    if team_count > 0
      message = "Team (#{team_count} total):\n"
      for team of robot.brain.data.teams
        message += "#{team}\n"
        for user in robot.brain.data.teams[team]
          message += "- #{user}\n"
      msg.send message

    else
      msg.send "Oh noes, we gots no teams!"

  removeUserFromTeam = (user, team_name, msg) ->
    return unless teamExists(team_name, msg)

    if user not in robot.brain.data.teams[team_name]
      msg.send "#{user} already out of the team"
    else
      user_index = robot.brain.data.teams[team_name].indexOf(user)
      robot.brain.data.teams[team_name].splice(user_index, 1)
      count = teamSize(team_name, msg)
      countMessage = ", " + count + " remaining" if count > 0
      message = "#{user} removed from #{team_name}"
      message += countMessage if countMessage
      msg.send message

  teamExists = (team_name, msg) ->
    if robot.brain.data.teams[team_name]
      true
    else
      msg.send "#{team_name} does not exist, buddy."
      false

  robot.respond /create (\S*) team ?.*/i, (msg) ->
    team_name = msg.match[1]
    addTeam(team_name, msg)

  robot.respond /list teams ?.*/i, (msg) ->
    listTeams(msg)

  robot.respond /(\S*) team add (\S*) ?.*/i, (msg) ->
    team_name = msg.match[1]
    user = msg.match[2]
    if user.toLocaleLowerCase() == "me"
      user = msg.message.user.name
    addUserToTeam(user, team_name, msg)

  robot.respond /(\S*) team \+1 ?.*/i, (msg) ->
    team_name = msg.match[1]
    addUserToTeam(msg.message.user.name, team_name, msg)

  robot.respond /(\S*) team remove (\S*) ?.*/i, (msg) ->
    team_name = msg.match[1]
    user = msg.match[2]
    if user.toLocaleLowerCase() == "me"
      user = msg.message.user.name
    removeUserFromTeam(user, team_name, msg)

  robot.respond /(\S*) team -1/i, (msg) ->
    team_name = msg.match[1]
    removeUserFromTeam(msg.message.user.name, team_name, msg)

  robot.respond /(\S*) team count$/i, (msg) ->
    team_name = msg.match[1]
    return unless teamExists(team_name)
    msg.send "#{teamSize(team_name, msg)} people are currently in the team"

  robot.respond /(\S*) team (list|show)$/i, (msg) ->
    team_name = msg.match[1]
    return unless teamExists(team_name)
    count = teamSize(team_name, msg)
    if count == 0
      msg.send "There is no one in the team currently"
    else
      position = 0
      message = "Team (#{count} total):\n"
      for user in robot.brain.data.teams[team_name]
        position += 1
        message += "#{position}. #{user}\n"
      msg.send message

  robot.respond /(\S*) team (clear|empty)$/i, (msg) ->
    team_name = msg.match[1]
    if msg.message.user.name in admins
      robot.brain.data.teams[team_name] = []
      msg.send "Team list cleared"
    else
      msg.reply "Sorry, only admins can clear the team members list"

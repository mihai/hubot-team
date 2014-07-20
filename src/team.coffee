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
#   hubot team +1 - add me to the team
#   hubot team -1 - remove me from the team
#   hubot team add (me|<user>) - add me or <user> to team
#   hubot team remove (me|<user>) - remove me or <user> from team
#   hubot team count - list the current size of the team
#   hubot team (list|show) - list the people in the team
#   hubot team (new|empty|clear) - clear team list
#
# Author:
#   mihai

config =
  admin_list: process.env.HUBOT_TEAM_ADMIN

module.exports = (robot) ->
  robot.brain.data.team ||= {}

  unless config.admin_list?
    robot.logger.warning 'The HUBOT_TEAM_ADMIN environment variable not set'

  if config.admin_list?
    admins = config.admin_list.split ','
  else
    admins = []

  teamSize = () ->
    count = 0
    for u, part of robot.brain.data.team
      count += part
    count

  addUserToTeam = (user, msg) ->
    if robot.brain.data.team[user]
      msg.send "#{user} already in the team"
    else
      count = teamSize()
      if count > 0
        countMessage = ", " + count
        countMessage += " others are in" if count > 1
        countMessage += " other is in" if count == 1

      robot.brain.data.team[user] = 1

      message = "#{user} added to the team"
      message += countMessage if countMessage
      msg.send message

  removeUserFromTeam = (user, msg) ->
    if not robot.brain.data.team[user]
      msg.send "#{user} already out of the team"
    else
      robot.brain.data.team[user] = 0
      count = teamSize()
      countMessage = ", " + count + " remaining" if count > 0
      message = "#{user} removed from the team"
      message += countMessage if countMessage
      msg.send message

  robot.respond /team add (\w*) ?.*/i, (msg) ->
    user = msg.match[1]
    if user.toLocaleLowerCase() == "me"
      user = msg.message.user.name
    addUserToTeam(user, msg)

  robot.respond /team \+1 ?.*/i, (msg) ->
    addUserToTeam(msg.message.user.name, msg)

  robot.respond /team remove (\w*) ?.*/i, (msg) ->
    user = msg.match[1]
    if user.toLocaleLowerCase() == "me"
      user = msg.message.user.name
    removeUserFromTeam(user, msg)

  robot.respond /team -1/i, (msg) ->
    removeUserFromTeam(msg.message.user.name, msg)

  robot.respond /team count$/i, (msg) ->
    msg.send "#{teamSize()} people are currently in the team"

  robot.respond /team (list|show)$/i, (msg) ->
    count = teamSize()
    if count == 0
      msg.send "There is no one in the team currently"
    else
      position = 0
      message = "Team (#{count} total):\n"
      for user of robot.brain.data.team
        if robot.brain.data.team[user] != 0
          position += 1
          message += "#{position}. #{user}\n"
      msg.send message

  robot.respond /team (new|clear|empty)$/i, (msg) ->
    if msg.message.user.name in admins
      robot.brain.data.team = {}
      msg.send "Team list cleared"
    else
      msg.reply "Sorry, only admins can clear the team members list"

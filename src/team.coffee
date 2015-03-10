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
#   hubot (<team_name>) team +1 - add me to the team
#   hubot (<team_name>) team -1 - remove me from the team
#   hubot (<team_name>) team add (me|<user>) - add me or <user> to team
#   hubot (<team_name>) team remove (me|<user>) - remove me or <user> from team
#   hubot (<team_name>) team count - list the current size of the team
#   hubot (<team_name>) team (list|show) - list the people in the team
#   hubot (<team_name>) team (empty|clear) - clear team list
#
# Author:
#   mihai

Config          = require './models/config'
Team            = require './models/team'
ResponseMessage = require './helpers/response_message'
UserNormalizer  = require './helpers/user_normalizer'

module.exports = (robot) ->
  robot.brain.data.teams or= {}
  Team.robot = robot

  unless Config.adminList()
    robot.logger.warning 'HUBOT_TEAM_ADMIN environment variable not set'

  ##
  ## hubot create <team_name> team - create team called <team_name>
  ##
  robot.respond /create (\S*) team ?.*/i, (msg) ->
    teamName = msg.match[1]
    if team = Team.get teamName
      message = ResponseMessage.teamAlreadyExists team
    else
      team = Team.create teamName
      message = ResponseMessage.teamCreated team
    msg.send message

  ##
  ## hubot (delete|remove) <team_name> team - delete team called <team_name>
  ##
  robot.respond /(delete|remove) (\S*) team ?.*/i, (msg) ->
    teamName = msg.match[2]
    if Config.isAdmin(msg.message.user.name)
      if team = Team.get teamName
        team.destroy()
        message = ResponseMessage.teamDeleted(team)
      else
        message = ResponseMessage.teamNotFound(teamName)
      msg.send message
    else
      msg.reply ResponseMessage.adminRequired()


  ##
  ## hubot list teams - list all existing teams
  ##
  robot.respond /list teams ?.*/i, (msg) ->
    teams = Team.all()
    msg.send ResponseMessage.listTeams(teams)

  ##
  ## hubot <team_name> team add (me|<user>) - add me or <user> to team
  ##
  robot.respond /(\S*)? team add (\S*) ?.*/i, (msg) ->
    teamName = msg.match[1]
    team = Team.getOrDefault(teamName)
    return msg.send ResponseMessage.teamNotFound(teamName) unless team
    user = UserNormalizer.normalize(msg.message.user.name, msg.match[2])
    isMemberAdded = team.addMember user
    if isMemberAdded
      message = ResponseMessage.memberAddedToTeam(user, team)
    else
      message = ResponseMessage.memberAlreadyAddedToTeam(user, team)
    msg.send message

  ##
  ## hubot <team_name> team +1 - add me to the team
  ##
  robot.respond /(\S*)? team \+1 ?.*/i, (msg) ->
    teamName = msg.match[1]
    team = Team.getOrDefault(teamName)
    return msg.send ResponseMessage.teamNotFound(teamName) unless team
    user = UserNormalizer.normalize(msg.message.user.name)
    isMemberAdded = team.addMember user
    if isMemberAdded
      message = ResponseMessage.memberAddedToTeam(user, team)
    else
      message = ResponseMessage.memberAlreadyAddedToTeam(user, team)
    msg.send message

  ##
  ## hubot <team_name> team remove (me|<user>) - remove me or <user> from team
  ##
  robot.respond /(\S*)? team remove (\S*) ?.*/i, (msg) ->
    teamName = msg.match[1]
    team = Team.getOrDefault(teamName)
    return msg.send ResponseMessage.teamNotFound(teamName) unless team
    user = UserNormalizer.normalize(msg.message.user.name, msg.match[2])
    isMemberRemoved = team.removeMember user
    if isMemberRemoved
      message = ResponseMessage.memberRemovedFromTeam(user, team)
    else
      message = ResponseMessage.memberAlreadyOutOfTeam(user, team)
    msg.send message

  ##
  ## hubot <team_name> team -1 - remove me from the team
  ##
  robot.respond /(\S*)? team -1/i, (msg) ->
    teamName = msg.match[1]
    team = Team.getOrDefault(teamName)
    return msg.send ResponseMessage.teamNotFound(teamName) unless team
    user = UserNormalizer.normalize(msg.message.user.name)
    isMemberRemoved = team.removeMember user
    if isMemberRemoved
      message = ResponseMessage.memberRemovedFromTeam(user, team)
    else
      message = ResponseMessage.memberAlreadyOutOfTeam(user, team)
    msg.send message

  ##
  ## hubot <team_name> team count - list the current size of the team
  ##
  robot.respond /(\S*)? team count$/i, (msg) ->
    teamName = msg.match[1]
    team = Team.getOrDefault(teamName)
    message = if team then ResponseMessage.teamCount(team) else ResponseMessage.teamNotFound(teamName)
    msg.send message

  ##
  ## hubot <team_name> team (list|show) - list the people in the team
  ##
  robot.respond /(\S*)? team (list|show)$/i, (msg) ->
    teamName = msg.match[1]
    team = Team.getOrDefault(teamName)
    message = if team then ResponseMessage.listTeam(team) else ResponseMessage.teamNotFound(teamName)
    msg.send message

  ##
  ## hubot <team_name> team (empty|clear) - clear team list
  ##
  robot.respond /(\S*)? team (clear|empty)$/i, (msg) ->
    if Config.isAdmin(msg.message.user.name)
      teamName = msg.match[1]
      if team = Team.getOrDefault(teamName)
        team.clear()
        message = ResponseMessage.teamCleared(team)
      else
        message = ResponseMessage.teamNotFound(teamName)
      msg.send message
    else
      msg.reply ResponseMessage.adminRequired()

  ##
  ## hubot upgrade teams - upgrade team for the new structure
  ##
  robot.respond /upgrade teams$/i, (msg) ->
    teams = {}
    for index, team of robot.brain.data.teams
      if team instanceof Array
        teams[index] = new Team(index, team)
      else
        teams[index] = team

    robot.brain.data.teams = teams
    msg.send ResponseMessage.listTeams(Team.all())

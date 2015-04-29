class ResponseMessage

  teamCreated: (team)->
    "#{team.label()} created, add some people to it"

  teamAlreadyExists: (team)->
    "#{team.label()} already exists"

  teamDeleted: (team)->
    "#{team.label()} removed"

  listTeams: (teams)->
    return 'No team was created so far' if teams.length is 0
    message = "Teams:\n"

    for team in teams
      if team.membersCount() > 0
        message += "`#{team.name}` (#{team.membersCount()} total)"

        for user in team.members
          message += "\n- #{user}"
      else
        message += "`#{team.name}` (empty)\n"
    message

  adminRequired: -> "Sorry, only admins can perform this operation"

  memberAddedToTeam: (member, team)->
    count = team.membersCount() - 1
    message = "#{member} added to the #{team.label()}"
    return message if count is 0
    singular_or_plural = if count is 1 then "other is" else "others are"
    "#{message}, #{count} #{singular_or_plural} in"

  memberAlreadyAddedToTeam: (member, team)->
    "#{member} already in the #{team.label()}"

  memberRemovedFromTeam: (member, team)->
    count = team.membersCount()
    message = "#{member} removed from the #{team.label()}"
    return message if count is 0
    "#{message}, #{count} remaining"

  memberAlreadyOutOfTeam: (member, team)->
    "#{member} already out of the #{team.label()}"

  teamCount: (team)->
    "#{team.membersCount()} people are currently in the team"

  teamNotFound: (teamName)->
    "`#{teamName}` team does not exist"

  listTeam: (team)->
    count = team.membersCount()
    if count is 0
      response = "There is no one in the #{team.label()} currently"
    else
      position = 0
      response = "#{team.label()} (#{count} total):\n"
      for member in team.members
        position += 1
        response += "#{position}. #{member}\n"

    response

  teamCleared: (team)->
    "#{team.label()} list cleared"

module.exports = new ResponseMessage

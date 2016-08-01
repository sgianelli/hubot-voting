# Description
#   Vote on stuff!
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot start vote item1, item2, item3, ...
#   hubot vote for N - where N is the choice number or the choice name
#   hubot show choices
#   hubot show votes - shows current votes
#   hubot end vote
#
# Notes:
#   None
#
# Author:
#   antonishen

module.exports = (robot) ->
  robot.voting = {}

  robot.respond /start vote (.+)$/i, (msg) ->
    console.log "User: #{msg.envelope.user.name}"
    if robot.voting[msg.message.room]? and robot.voting[msg.message.room].votes?
      msg.send "A vote is already underway"
      sendChoices (msg)
    else
      if !robot.voting[msg.message.room]?
        robot.voting[msg.message.room] = {}

      robot.voting[msg.message.room][msg.envelope.user.name] = {}
      robot.voting[msg.message.room][msg.envelope.user.name].votes = {}
      createChoices msg, msg.match[1]

      msg.send "Vote started"
      sendChoices(msg)

  robot.respond /end vote/i, (msg) ->
    if robot.voting[msg.message.room][msg.envelope.user.name].votes?
      console.log robot.voting[msg.message.room][msg.envelope.user.name].votes

      results = tallyVotes(msg)

      response = "The results are..."
      for choice, index in robot.voting[msg.message.room][msg.envelope.user.name].choices
        response += "\n#{choice}: #{results[index]}"

      msg.send response

      delete robot.voting[msg.message.room][msg.envelope.user.name].votes
      delete robot.voting[msg.message.room][msg.envelope.user.name].choices
    else
      msg.send "There is not a vote to end"


  robot.respond /show choices/i, (msg) ->
    sendChoices(msg)

  robot.respond /show votes/i, (msg) ->
    results = tallyVotes(msg)
    sendChoices(msg, results)

  robot.respond /vote (for )?(.+)$/i, (msg) ->
    choice = null

    re = /\d{1,2}$/i
    if re.test(msg.match[2])
      choice = parseInt msg.match[2], 10
    else
      choice = robot.voting[msg.message.room][msg.envelope.user.name].choices.indexOf msg.match[2]

    console.log choice

    sender = robot.brain.usersForFuzzyName(msg.message.user['name'])[0].name

    if validChoice msg, choice
      robot.voting[msg.message.room][msg.envelope.user.name].votes[sender] = choice - 1
      msg.send "#{sender} voted for #{robot.voting[msg.message.room][msg.envelope.user.name].choices[choice - 1]}"
    else
      msg.send "#{sender}: That is not a valid choice"

  createChoices = (msg, rawChoices) ->
    robot.voting[msg.message.room][msg.envelope.user.name].choices = rawChoices.split(/, /)

  sendChoices = (msg, results = null) ->

    if robot.voting[msg.message.room][msg.envelope.user.name].choices?
      response = ""
      for choice, index in robot.voting[msg.message.room][msg.envelope.user.name].choices
        response += "#{index + 1}: #{choice}"
        if results?
          response += " -- Total Votes: #{results[index]}"
        response += "\n" unless index == robot.voting[msg.message.room][msg.envelope.user.name].choices.length - 1
    else
      msg.send "There is not a vote going on right now"

    msg.send response

  validChoice = (msg, choice) ->
    numChoices = robot.voting[msg.message.room][msg.envelope.user.name].choices.length
    0 < choice <= numChoices

  tallyVotes = (msg) ->
    results = (0 for choice in robot.voting[msg.message.room][msg.envelope.user.name].choices)

    voters = Object.keys robot.voting[msg.message.room][msg.envelope.user.name].votes
    for voter in voters
      choice = robot.voting[msg.message.room][msg.envelope.user.name].votes[voter]
      results[choice] += 1

    results

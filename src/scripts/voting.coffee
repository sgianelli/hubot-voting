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

  Default = {
    Duration: 3 * 60 * 60 * 1000,
    Locked: false
  }

  robot.respond /start vote (\d+m )?(.+)$/i, (msg) ->
    time = Default.Duration
    options = msg.match[2]

    if msg.match[1] != undefined
      time = 60 * 1000 * msg.match[1].substring(0, msg.match[1].length - 2)

    if robot.voting[msg.message.room]? and robot.voting[msg.message.room].votes?
      msg.send "A vote is already underway"
      sendChoices(msg)
    else
      vote = {}
      vote.start = (new Date()).getTime()
      vote.timeout = time
      vote.owner = msg.envelope.user.name
      vote.votes = {}

      robot.voting[msg.message.room] = vote

      createChoices msg, options

      msg.send "Vote started -- #{Math.ceil(robot.voting[msg.message.room].timeout / 60000)} minutes remaining"
      sendChoices(msg)

  robot.respond /end vote/i, (msg) ->
    vote = robot.voting[msg.message.room]
    currentTime = (new Date()).getTime()
    endTime = vote.timeout + vote.start
    delta = endTime - currentTime
    expired = delta <= 0

    console.log("Current: #{currentTime} end time: #{endTime} delta: #{delta}")

    if vote.owner != msg.envelope.user.name && !expired
      msg.send "User cannot end vote, #{Math.ceil(delta / 60000)} minutes remaining"
    else if robot.voting[msg.message.room].votes?
      console.log robot.voting[msg.message.room].votes

      results = tallyVotes(msg)

      response = "The results are..."
      for choice, index in robot.voting[msg.message.room].choices
        participants = results[index].names.join(', ')
        tail = ""

        if participants.length > 0
            tail = participants

        response += "\n#{choice}: #{results[index].total}" + tail

      msg.send response

      delete robot.voting[msg.message.room].votes
      delete robot.voting[msg.message.room].choices
    else
      msg.send "There is not a vote to end"


  robot.respond /show choices/i, (msg) ->
    sendChoices(msg)

  robot.respond /show votes/i, (msg) ->
    console.log "#{robot.voting[msg.message.room].start} -- #{robot.voting[msg.message.room].timeout}"
    results = tallyVotes(msg)
    sendChoices(msg, results)

  robot.respond /vote (for )?(.+)$/i, (msg) ->
    choice = null

    re = /\d{1,2}$/i
    if re.test(msg.match[2])
      choice = parseInt msg.match[2], 10
    else
      choice = robot.voting[msg.message.room].choices.indexOf msg.match[2]

    console.log choice

    sender = robot.brain.usersForFuzzyName(msg.message.user['name'])[0].name

    if validChoice msg, choice
      robot.voting[msg.message.room].votes[sender] = choice - 1
      msg.send "#{sender} voted for #{robot.voting[msg.message.room].choices[choice - 1]}"
    else
      msg.send "#{sender}: That is not a valid choice"

  createChoices = (msg, rawChoices) ->
    robot.voting[msg.message.room].choices = rawChoices.split(/, /)

  sendChoices = (msg, results = null) ->

    if robot.voting[msg.message.room].choices?
      response = ""
      for choice, index in robot.voting[msg.message.room].choices
        response += "#{index + 1}: #{choice}"
        if results?
          response += " -- Total Votes: #{results[index].total}"
        response += "\n" unless index == robot.voting[msg.message.room].choices.length - 1
    else
      msg.send "There is not a vote going on right now"

    msg.send response

  validChoice = (msg, choice) ->
    numChoices = robot.voting[msg.message.room].choices.length
    0 < choice <= numChoices

  tallyVotes = (msg) ->
    results = ({ total: 0, names: [] } for choice in robot.voting[msg.message.room].choices)
    vote = robot.voting[msg.message.room]
    voters = Object.keys vote.votes

    for voter in voters
      choice = vote.votes[voter]
      results[choice].total += 1
      results[choice].names.push voter

    results

module.exports.Danger = class Danger
  constructor: (line, properties) ->
    @properties = {}
    for i in [line.length..0]
      if line[i] is "}"
        left = i
        break
      else if line[i] isnt " "
        break
    if left
      count = 1
      for i in [left..0]
        if i is 0 or line[i - 1] isnt "\\"
          if line[i] is "}"
            count++
          else if line[i] is "{"
            count--
        if count is 0
          break
      if count
        @message = line
      else
        @message = line.substring(0, i).replace(/\s+^/, "")
        try
          @properties = JSON.parse(line.substring(i))
        catch e
          @message = line
    else
      @message = line
    @extend(properties) if properties
  extend: (properties) ->
    for k, v of properties
      @properties[k] = v
  toString: ->
    if Object.keys(@properties).length
      "#{@message} #{JSON.stringify(@properties)}"
    else
      @message

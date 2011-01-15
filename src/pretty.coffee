spaces = ""

indent = (depth) ->
  spaces += "  " while spaces.length < depth
  spaces.substring 0, depth

module.exports.prettify = prettify = (object, depth) ->
  output = []
  depth or= 0
  switch typeof object
    when "object"
      if object instanceof Array
        prefix = "["
        for item in object
          output.push indent(depth), prefix, " ", prettify(item, depth + 2)
          prefix = ","
        output.push " ]"
      else
        prefix = "{"
        for key, value of object
          if typeof value != "undefined" and typeof value != "function"
            output.push indent(depth), prefix, " ", prettify(key, depth + 2), ": ", prettify(value, depth + 2), "\n"
            prefix = ","
        output.push "}"
    when "number"
      output.push if isFinite(object) then String(object) else "null"
    when "string"
      length = object.length
      output.push '"'
      for i in [0...object.length]
        c = object.charAt(i)
        if c >= ' '
          if c == '\\' or c == '"'
              output.push '\\'
          output.push c
        else
          switch c
            when '\b' then output.push '\\b'
            when '\f' then output.push '\\f'
            when '\n' then output.push '\\n'
            when '\r' then output.push '\\r'
            when '\t' then output.push '\\t'
            else
              c = c.charCodeAt()
              output.push '\\u00', Math.floor(c / 16).toString(16), (c % 16).toString(16)
      output.push '"'
    when "boolean"
      output.push String(object)
    else
      output.push "null"
  if depth is 0
    output.push "\n"
  output.join ""


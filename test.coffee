Q = require 'q'

Q().then(
  -> ['a']
).then(
  (arr) ->
  	console.log(arr)
)
test "one", ->
  expect(1).not_to be 2
test "two", ->
  expect(/abc/ instanceof RegExp).to be true
test "three", ->
  expect(typeof(->)).to be 'function'
test "four", ->
  expect(->
    throw "Hello World!"
  ).to error /^Hello\sWorld!$/
test "five", ->
  expect(->
    expect("123456789").to match /^\d+$/
  ).not_to error
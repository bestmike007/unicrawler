test "one", ->
  expect(1).not_to be 2
test "two", ->
  expect(/abc/).to be_a RegExp
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
test "six", ->
  expect().to be_an 'undefined'
  expect([]).to be_an Array
  expect("").to be_a 'string'
  expect(-> ->).to be_a 'function'
  expect(/123/).to be_a RegExp
test ->
  expect(->
    "AbC"
  ).not_to match /^[a-z]+$/
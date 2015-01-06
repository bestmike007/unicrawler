phantom.injectJs './premise.coffee'
fs = require 'fs'
system = require 'system'

# gloabl function for test cases.
window.expect = (actual) ->
  compare = (op, not_to) ->
    op = op() if op == window.error
    try
      actual = actual() if typeof(actual) == 'function'
      if op.operator == 'error'
        return if not_to
        throw "\tExpected to throw error but nothing raised"
    catch e
      if op.operator == 'error'
        if not_to
          throw "\tExpected:\tnot to throw error\n\tGot:\t#{e.toString()}"
        else if op.expected
          if op.expected instanceof RegExp
            unless e.toString().match(op.expected)
              throw "\tExpected error to match #{op.expected}\n\tGot: #{e.toString()}" 
          else if typeof op.expected == 'function'
            unless op.expected(e)
              throw "\tExpected error `#{e.toString()}` to pass validation #{op.expected.toString()} but failed"
          else
            unless e.toString() == op.expected
              throw "\tExpected error to equal #{op.expected}\n\tGot: #{e.toString()}" 
        return
      throw e
    result =  if typeof(op) == 'function'
                op(actual)
              else
                op.compare(actual)
    result = !result if not_to
    unless result
      if typeof(op) == 'function'
        throw "\tExpected `#{actual}` to pass validation #{op.toString()} but failed"
      else
        throw "\tExpected:\t#{if not_to then 'not ' else ''}to #{op.operator} #{op.expected}\n\tGot:     \t#{actual}"
  return {
    not_to: (op) ->
      compare op, true
    to: (op) ->
      compare op, false
  }

window.be = window.eq = (expected) ->
  return {
    expected: expected
    operator: "=="
    compare: (actual) ->
      expected == actual
  }
window.gt = (expected) ->
  return {
    expected: expected
    operator: ">"
    compare: (actual) ->
      expected > actual
  }
window.ge = (expected) ->
  return {
    expected: expected
    operator: ">="
    compare: (actual) ->
      expected >= actual
  }
window.lt = (expected) ->
  return {
    expected: expected
    operator: "<"
    compare: (actual) ->
      expected < actual
  }
window.le = (expected) ->
  return {
    expected: expected
    operator: "<="
    compare: (actual) ->
      expected <= actual
  }
window.match = (expected) ->
  expected = new RegExp(expected) unless expected instanceof RegExp
  return {
    expected: expected
    operator: "`RegExp Match`"
    compare: (actual) ->
      actual.match(expected)
  }
window.error = (expected) ->
  return {
    expected: expected
    operator: "error"
  }

runTests = ->
  logger.info "Start running all tests..."
  caseCount = 0
  # load all test files and test cases
  suits = fs.list(fs.absolute("#{phantom.libraryPath}/tests/")).filter((v) ->
    v[0] != '.'
  ).map (file) ->
    suit =
      file: file
      cases: []
    window.test = (desc, func) ->
      caseCount++
      suit.cases.push {
        desc: desc
        func: func
      }
    include "tests/#{file}"
    delete window.test
    return suit
  logger.info "#{suits.length} test files loaded, total #{caseCount} test cases."
  # Run all test cases
  failures = []
  suits.map (test_suit) ->
    test_suit.cases.map (test_case) ->
      try
        test_case.func()
        system.stdout.write('.')
      catch e
        system.stdout.write('F')
        failures.push {
          suit: test_suit
          case: test_case
          error: e.toString()
        }
  console.log('\tDONE')
  # Print test failures if any
  failures.map (failure) ->
    console.log "=============================================="
    console.log "Failure (Test suit: `#{failure.suit.file}`, Test case: `#{failure.case.desc}`)"
    console.log failure.error
  # Print summary
  console.log "=============================================="
  console.log "Total: #{caseCount} / Failure: #{failures.length}"
  phantom.exit failures.length

module.exports = run: runTests
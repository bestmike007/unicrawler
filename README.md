Unicrawler Client
======

Several ways to use unicrawler:

+ phantomjs --output-encoding=gbk main.coffee --config=examples/ip138-config --ip=8.8.8.8
+ phantomjs main.coffee --file=examples/run-file.coffee
+ phantomjs main.coffee test

## Task configuration protocol with examples

Task configuration is represented as JSON object/array/function strings:
- JSON array: sequential list of configurations (object/array/function)
- JavaScript function: a function to modify results according to results from previous configurations and task arguments
- JSON Object: single action including extract, fire event, interact, wait for element, raw http get or post, execute script in browser

### JSON object crawler configuration

Types of configuration:
- extract: extract information from current page DOM tree
- event: fire events, e.g. click, type, keypress, etc.
- interact: raw mouse/keyboard interaction
- waitFor: wait for some element present in the DOM tree
- request: open url or submit a form post in the current page
- script: execute javascript in the browser

__Type: extract__

Example & explanations:

``` js
{ 
  type: 'extract', // also the default type, this can be ignored
  selector: '#price', // sizzle selector, refer sizzle.js doc for more information
  elementIndex: 0, // default is 0 when result type is single, ignored when result type is list
  extract: 'text', // extract type for dom element, text: inner text, html: inner html, ownerText: text without children, ownerHtml: outer html, attr: element attribute
  attr: 'src', // required when extract type is attr, represent the name of the attribute to extract
  format: function(v) { return v.substring(1); }, // post processor for the result, use function to do anything you want to and return the result
  name: 'price', // the key to put in the key-value pair result object
  resultType: 'single', // default is single, set to list when multiple data is accepted
  merge: true, // merge into a list when the result data key already exists when this is true, replace when this is false
  ignore_not_found: true // continue to execution even if no element found. default true for list result type, false for single result type.
}
```

__Type: event__

Example & explanations:

``` js
{ 
  type: 'event', // fire events
  action: 'click', // click on an element, available options e.g. click, double click, type, mouseover, mousedown, mouseup, keypress, keydown, keyup, etc.
  value: 'keywords', // some action need a value, e.g. type into a text field, keypress with a key code, etc.
  selector: '#search', // same as the previous configuration, can be replaced with function
  elementIndex: 0 // same as the previous configuration
}
// Utilize task arguments:
{
  type: 'event',
  event: 'enter', // or 'type', they're the same
  selector: '#kw',
  ref: 'kw' // reference 'kw' from task.args along with each task
  }
```

__Type: interact__

Emulate mouse/keyboard. Example & explanations:

``` js
{
  type: 'interact',
  event: 'keypress', // candidates: mouseup, mousedown, mousemove, click, doubleclick, keyup, keypress, keydown.
  modifiers: 'Ctrl', // or 'Alt', 'Shift', 'Ctrl+Shift', and other combinations.
  key: 'Z' // emulate Ctrl+Z
}
{type:'interact', event: 'click', mouseX: 0, mouseY: 0} // emulate mouse
{type:'interact', event: 'keypress', key: 'A', modifiers: 'Ctrl+Shift+Alt'}
```

__Type: sleep__

Example & explanations:

``` js
{
  type: 'sleep',
  ms: 1500 // sleep for 1.5 sec
}
```

__Type: waitFor__

Example & explanations:

``` js
{
  type: 'waitFor',
  selector: '#content_left h3 a', // wait for the element to presents
  tries: 5, // crawler will try to find the specific element in the DOM tree every second for no more than 5 times by default, change this to wait for more seconds
  fallback: [ /*  */ ] // fallbcak configurations here on element not found, or simply true to continue
}
```

__Type: request__

Example & explanations:

``` js
{
  type:"request",
  url: function(args, result) { // url can be generated from the arguments and/or results from previous configurations.
    return "http://www.ip138.com/ips138.asp?ip=" + args.ip + '&action=2';
  }
}
{ type:"request",  url: 'http://www.baidu.com/' } // or static url address
{ type:"request",  url: 'http://www.baidu.com/', data: 'key=value' } // or submit a form post with data
```

__Type: script__

Example & explanations:

``` js
{
  type: "script", // execute script in browser, not in crawler.
  func: function(args, result) {
    // anything here will be executed in the browser javascript engine, args is readonly however things can be written directly into result object.
    result.title = document.title;
    result.body = Sizzle('body')[0].innerHTML; // Sizzle is injected before this script is executed.
  }
}
```

### Function configuration

Accept args and result from previous configurations and return some configuration to execute (array/object/function will be fine). Example & explanations:

``` js
function(args, result) {
  // this one modifies the result
  result.ip = result.ip.substring(result.ip.indexOf('>>') + 3);
}
function(args, result) {
  // execute something according to result
  if (result.nextPageUrl) return [{ type: 'request', url: result.nextPageUrl }, ...];
}
```

### JSON Array & examples

Assembled configurations in sequence, e.g.

__Retrieve IP from ip138__

``` js
[
  {
    type: "request",
    url: function(args) {
      return "http://www.ip138.com/ips138.asp?ip=" + args.ip + "&action=2";
    }
  }, {
    type: 'waitFor',
    selector: 'h1'
  }, {
    selector: 'h1',
    extract: 'text',
    name: 'ip'
  }, {
    selector: '.ul1 li',
    extract: 'text',
    name: 'addr',
    resultType: 'list'
  }, function(args, result) {
    result.ip = result.ip.substring(result.ip.indexOf('>>') + 3);
  }
]
```

__Search in baidu__

``` js
[
  {
    type: 'waitFor',
    selector: '#s_strpx_span3'
  }, {
    type: 'waitFor',
    selector: '#kw'
  }, {
    type: 'event',
    event: 'enter',
    selector: '#kw',
    ref: 'kw'
  }, {
    type: 'event',
    event: 'click',
    selector: '#su'
  }, {
    type: 'waitFor',
    selector: '#foot'
  }, {
    type: 'sleep',
    ms: 500
  }, {
    selector: '#content_left h3 a',
    elementIndex: 0,
    extract: 'text',
    name: 'link'
  }, {
    type: 'script',
    func: function(args, result) {
      return result.title = document.title;
    }
  }
]
```
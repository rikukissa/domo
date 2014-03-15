Route = (path) ->
  keys = []

  if path instanceof RegExp
    return (
      re: path
      src: path.toString()
      keys: keys
    )

  re: pathToRegExp(path, keys)
  src: path.toString()
  keys: keys

pathToRegExp = (path, keys) ->
  path = path.concat('/?')
    .replace(/\/\(/g, '(?:/')
    .replace /(\/)?(\.)?:(\w+)(?:(\(.*?\)))?(\?)?/g, (_, slash, format, key, capture, optional) ->
      keys.push key
      slash = slash or ''

      '' + ((if optional then '' else slash)) +
      '(?:' + ((if optional then slash else '')) +
      (format or '') +
      (capture or '([^/]+?)') + ')' +
      (optional or '')

    .replace(/([\/.])/g, '\\$1')
    .replace(/\*/g, '(.+)')

  new RegExp('^' + path + '$', 'i')

match = (routes, uri) ->
  for route in routes

    re = route.re
    keys = route.keys
    splats = []
    params = {}

    continue unless captures = re.exec(uri)

    for val, j in captures when j > 0
      key = keys[j - 1]
      if key
        params[key] = val
      else
        splats.push val

    return (
      params: params
      splats: splats
      route: route.src
    )

class Router
  constructor: ->
    @routes = []
    @routeMap = {}

  addRoute: (path, fn) ->
    throw new Error(' route requires a path')  unless path
    throw new Error(' route ' + path.toString() + ' requires a callback')  unless fn

    route = Route(path)
    route.fn = fn
    @routes.push route
    @routeMap[path] = fn

  match: (pathname) ->
    route = match(@routes, pathname)
    route.fn = @routeMap[route.route] if route
    route

Router.match = match
module.exports = Router

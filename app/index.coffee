require 'coffee-errors'

util = require 'util'
path = require 'path'
yeoman = require 'yeoman-generator'
GitHubApi = require 'github'

githubUserInfo = (name, cb) ->
  proxy = process.env.http_proxy or process.env.HTTP_PROXY or process.env.https_proxy or process.env.HTTPS_PROXY or null
  githubOptions = version: '3.0.0'

  if proxy
    proxy = url.parse proxy

    githubOptions.proxy =
      host: proxy.hostname
      port: proxy.port

  github = new GitHubApi githubOptions

  github.user.getFrom user: name, (err, res) ->
    throw err  if err
    cb JSON.parse JSON.stringify res

class CoffeeModuleGenerator extends yeoman.generators.Base
  constructor: (args, options, config) ->
    super
    @currentYear = (new Date()).getFullYear()
    @on 'end', => @installDependencies skipInstall: options['skip-install']
    @pkg = JSON.parse @readFileAsString path.join __dirname, '../package.json'

  askFor: ->
    done = @async()

    # have Yeoman greet the user.
    console.log @yeoman

    prompts = [
      name: 'githubUser'
      message: 'Would you mind telling me your username on GitHub?'
      default: 'someuser'
    ,
      name: 'moduleName'
      message: 'What\'s the name of your module?'
      default: @_.slugify(@appname)
    ]

    @prompt prompts, (props) =>
      @githubUser = props.githubUser
      @appname    = props.moduleName
      @slug       = @_.slugify @appname
      done()

  userInfo: ->
    done = @async()

    githubUserInfo @githubUser, (res) =>
      @realname = res.name
      @email = res.email
      @githubUrl = res.html_url
      done()

  projectfiles: ->
    @template '_package.json', 'package.json'
    @template 'README.md'
    @template 'LICENSE'
    @template '_gruntfile.coffee', 'gruntfile.coffee'

  gitfiles: ->
    @copy '_gitignore', '.gitignore'

  app: ->
    @template 'src/coffee/index.coffee', "src/coffee/#{@appname}.coffee"
    @template 'src/coffee/classes/example.coffee', "src/coffee/classes/#{@appname}.coffee"

  tests: ->
    @mkdir 'test'
    @template 'test/coffee/index.test.coffee', "test/coffee/#{@appname}.test.coffee"
    @template 'test/coffee/classes/main.test.coffee', "test/coffee/classes/#{@appname}.test.coffee"

module.exports = CoffeeModuleGenerator
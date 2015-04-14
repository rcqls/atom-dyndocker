spawn = (require 'child_process').spawn
exec = (require 'child_process').exec
path = require 'path'

dyndocker_env = process.env

console.log(dyndocker_env)

module.exports=
class DyndockerRunner

  @dyndocker_server = null
  @dyndocker_client = null
  @dyndocker_run_cmd = 'ruby' #if process.platform == 'win32' then 'rubyw' else 'ruby'

  @start: ->
  	dyndocker_env["DYN_HOME"] =  atom.config.get('dyndocker-viewer.dyndockerHome')
  	## To fix PATH when /usr/local/bin not inside PATH
  	for pa in atom.config.get('dyndocker-viewer.addToPath').split(":")
  	  dyndocker_env["PATH"] += ":" + pa if dyndocker_env["PATH"].split(":").indexOf(pa) < 0
  	    
  	@dyndocker_server = spawn @dyndocker_run_cmd,[path.join atom.config.get('dyndocker-viewer.dyndockerHome'),"bin","dyndoc-server-simple.rb"],{"env": dyndocker_env}
  	
  	@dyndocker_server.stderr.on 'data', (data) ->
  	  console.log 'dyndocker-server stderr: ' + data

  	@dyndocker_server.stdout.on 'data', (data) ->
  	  console.log 'dyndocker-server stdout: ' + data

  @started: ->
  	console.log ["started",@dyndocker_server]
  	if @dyndocker_server == null or @dyndocker_server.killed
  	  @start()

  @stop: ->
    console.log 'DyndockerRunner is leaving...'
    if @dyndocker_client != null
      @dyndocker_client.close
      console.log 'DyndockerRunner client is closed!'
    @dyndocker_server.kill()
    console.log 'DyndockerRunner is killed!'

  @compile: (dyn_file) ->
  	compile_cmd=@dyndocker_run_cmd + " " + path.join(atom.config.get('dyndocker-viewer.dyndockerHome'),"bin","dyndoc-compile.rb") + " \"" + dyn_file + "\""
  	exec compile_cmd, {"env": dyndocker_env}, (error,stdout,stderr) ->
  	  console.log 'dyndoc-compile stdout: ' + stdout
  	  console.log 'dyndoc-compile stderr: ' + stderr
  	  if error != null
  	  	console.log 'dyndoc-compile error: ' + error

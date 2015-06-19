spawn = (require 'child_process').spawn
exec = (require 'child_process').exec
execSync = (require 'child_process').execSync

fs = require 'fs'
path = require 'path'

dyndocker_machine_name="dev"
dyndocker_container = "dyndoc-docker"
dyndocker_env = process.env
dyndocker_env["PATH"] += ":" + '/usr/local/bin:' + path.join(process.env["HOME"],"bin")
console.log "PATH:"+dyndocker_env["PATH"]

dyndocker_pre_path=new RegExp("^"+path.join(process.env["HOME"],"dyndocker")+"/")

module.exports=
class DyndockerRunner

  @dyndocker_machine = (execSync "docker-machine config "+dyndocker_machine_name,{"env": dyndocker_env}).toString("utf-8")
  console.log "docker-machine config "+dyndocker_machine_name+ @dyndocker_machine
  @dyndocker_run_cmd = "docker " + @dyndocker_machine + " "

  @restart: ->
    console.log 'Dyndocker server is restarting...'
    exec @dyndocker_run_cmd + "restart "+dyndocker_container,{"env": dyndocker_env},(error,stdout,stderr) ->
      console.log 'dyndocker-server stdout: ' + stdout
      console.log 'dyndocker-server stderr: ' + stderr
      if error != null
        console.log 'dyndocker-server error: ' + error

  @start: ->
    console.log 'Dyndocker server is starting...'
    exec @dyndocker_run_cmd + "start "+dyndocker_container,{"env": dyndocker_env},(error,stdout,stderr) ->
      console.log 'dyndocker-server stdout: ' + stdout
      console.log 'dyndocker-server stderr: ' + stderr
      if error != null
        console.log 'dyndocker-server error: ' + error

  @stop: ->
    console.log 'Dyndocker server is stopping...'
    exec @dyndocker_run_cmd + "stop "+dyndocker_container,{"env": dyndocker_env},(error,stdout,stderr) ->
      console.log 'dyndocker-server stdout: ' + stdout
      console.log 'dyndocker-server stderr: ' + stderr
      if error != null
        console.log 'dyndocker-server error: ' + error

  @getPort: ->
    out=execSync @dyndocker_run_cmd + "port "+dyndocker_container+" 7777/tcp",{"env": dyndocker_env},(error,stdout,stderr) ->
      console.log 'dyndocker port stdout: ' + stdout
      console.log 'dyndocker port stderr: ' + stderr
      if error != null
        console.log 'dyndocker port error: ' + error
    
    out.toString().split(":")[1]

  @compile: (dyn_file) ->
    if ((dyn_file.match /\/src\//) != null)
      dyn_file_build = dyn_file.replace "/src/","/build/"
      console.log "dyn_file_build:" + dyn_file_build
      console.log "link:"+ (fs.readlinkSync dyn_file_build)
      if fs.existsSync(dyn_file_build) and (fs.lstatSync dyn_file_build).isSymbolicLink() #and (fs.realpathSync(fs.readlinkSync dyn_file_build) == dyn_file) 
        dyn_file = dyn_file_build

    console.log "dyn_file:" + dyn_file
    dyn_file_inside_docker = dyn_file.replace dyndocker_pre_path,""
    console.log "dyndocker compile: "+dyn_file_inside_docker
    if (dyn_file.match dyndocker_pre_path) != null
      compile_cmd=@dyndocker_run_cmd + "exec "+dyndocker_container+" dyn" + " \"" + dyn_file_inside_docker + "\""
      exec compile_cmd, {"env": dyndocker_env}, (error,stdout,stderr) ->
        console.log 'dyndocker-compile stdout: ' + stdout
        console.log 'dyndocker-compile stderr: ' + stderr
        if error != null
          console.log 'dyndocker-compile error: ' + error
    else
      alert "file "+dyn_file_inside_docker+" could not be compiled!"

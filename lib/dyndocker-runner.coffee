spawn = (require 'child_process').spawn
exec = (require 'child_process').exec
spawnSync = (require 'child_process').spawnSync

fs = require 'fs'
path = require 'path'

dyndocker_machine_name = "default"
dyndocker_env = process.env
docker_path='/usr/local/bin'
user_home = process.env[if process.platform == "win32" then "USERPROFILE" else "HOME"]

if process.platform == 'win32'
  paths = (pa for pa in fs.readdirSync path.join(process.env.LOCALAPPDATA,"Kitematic") when pa.split("\-")[0]=="app").sort().reverse()
  docker_path=path.join(process.env.LOCALAPPDATA,"Kitematic",paths[0],"resources","resources")
  dyndocker_env["PATH"] += ';' + docker_path + ';' + path.join(user_home,"bin")
else
  dyndocker_env["PATH"] += ':' + docker_path + ':' + path.join(user_home,"bin")
console.log "PATH("+process.platform+"):"+dyndocker_env["PATH"]


dyndocker_pre_path_reg="^"+path.join(user_home,"dyndocker")+"/"
dyndocker_pre_path_reg = dyndocker_pre_path_reg.replace(new RegExp(path.sep+path.sep,"g"),"/")  if process.platform == "win32"
dyndocker_pre_path=new RegExp(dyndocker_pre_path_reg)

module.exports=
class DyndockerRunner

  if process.platform == "linux"
    @dyndocker_machine = ""
  else 
    @dyndocker_machine = (spawnSync "docker-machine",("config "+dyndocker_machine_name).split(" "),{"env": dyndocker_env})
    @dyndocker_machine = @dyndocker_machine.stdout.toString("utf-8")

  console.log "docker-machine config "+dyndocker_machine_name+ " -> " +@dyndocker_machine
  @dyndocker_run_cmd = "docker " + @dyndocker_machine + " "

  @restart: ->
    console.log 'Dyndocker server is restarting...'
    exec @dyndocker_run_cmd + "restart "+atom.config.get("dyndocker.containerName"),{"env": dyndocker_env},(error,stdout,stderr) ->
      console.log 'dyndocker-server stdout: ' + stdout
      console.log 'dyndocker-server stderr: ' + stderr
      if error != null
        console.log 'dyndocker-server error: ' + error

  @start: ->
    console.log 'Dyndocker server is starting...'
    exec @dyndocker_run_cmd + "start "+atom.config.get("dyndocker.containerName"),{"env": dyndocker_env},(error,stdout,stderr) ->
      console.log 'dyndocker-server stdout: ' + stdout
      console.log 'dyndocker-server stderr: ' + stderr
      if error != null
        console.log 'dyndocker-server error: ' + error

  @stop: ->
    console.log 'Dyndocker server is stopping...'
    exec @dyndocker_run_cmd + "stop "+atom.config.get("dyndocker.containerName"),{"env": dyndocker_env},(error,stdout,stderr) ->
      console.log 'dyndocker-server stdout: ' + stdout
      console.log 'dyndocker-server stderr: ' + stderr
      if error != null
        console.log 'dyndocker-server error: ' + error

  @getPort: ->
    if process.platform == "linux"
      "7777"
    else
      out=spawnSync "docker", (@dyndocker_machine+" port "+atom.config.get("dyndocker.containerName")+" 7777/tcp").split(" "),{"env": dyndocker_env} 
      console.log("get Port:"+out.stdout.toString())
      out.stdout.toString().split(":")[1] ? "7777"

  @compile: (dyn_file) ->
    if ((dyn_file.match /\/src\//) != null)
      dyn_file_build = dyn_file.replace "/src/","/build/"
      console.log "dyn_file_build:" + dyn_file_build
      console.log "link:"+ (fs.readlinkSync dyn_file_build)
      if fs.existsSync(dyn_file_build) and (fs.lstatSync dyn_file_build).isSymbolicLink() #and (fs.realpathSync(fs.readlinkSync dyn_file_build) == dyn_file) 
        dyn_file = dyn_file_build

    dyn_file = dyn_file.replace(new RegExp(path.sep+path.sep,"g"),"/")
    console.log "dyn_file:" + dyn_file
    dyn_file_inside_docker = dyn_file.replace dyndocker_pre_path,""
    console.log "dyndocker compile: "+dyn_file_inside_docker
    if (dyn_file.match dyndocker_pre_path) != null
      compile_cmd=@dyndocker_run_cmd + "exec "+atom.config.get("dyndocker.containerName")+" dyn" + " \"" + dyn_file_inside_docker + "\""
      exec compile_cmd, {"env": dyndocker_env}, (error,stdout,stderr) ->
        console.log 'dyndocker-compile stdout: ' + stdout
        console.log 'dyndocker-compile stderr: ' + stderr
        if error != null
          console.log 'dyndocker-compile error: ' + error
    else
      alert "file "+dyn_file_inside_docker+" could not be compiled!"

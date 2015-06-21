execSync = (require 'child_process').execSync

fs = require 'fs'
path = require 'path'

dyndocker_env = process.env

if process.platform == 'win32'
  paths = (pa for pa in fs.readdirSync path.join(process.env.LOCALAPPDATA,"Kitematic") when pa.split("\-")[0]=="app").sort().reverse()
  docker_path=path.join(process.env.LOCALAPPDATA,"Kitematic",paths[0],"resources","resources")
  dyndocker_env["PATH"] += ';' + docker_path +';' + path.join(process.env["HOME"],"bin")
else
  docker_path='/usr/local/bin'
  #console.log "PATH("+process.platform+"):"+dyndocker_env["PATH"]
  dyndocker_env["PATH"] += ':' + docker_path + ':' + path.join(process.env["HOME"],"bin")

console.log "PATH("+process.platform+"):"+dyndocker_env["PATH"]

DyndockerRunner = require './dyndocker-runner'

exports.eval = (text='', filePath, callback) ->

	decode_cmd = (cmd) ->
	  regexp = /^__send_cmd__\[\[([a-zA-Z0-9_]*)\]\]__([\s\S]*)/m
	  res = cmd.match(regexp)
	  {"cmd": res[1], "content": res[2]}

	end_token = "__[[END_TOKEN]]__"

	#text=text.replace /\#\{/g,"__AROBAS_ATOM__{"

	net = require 'net'
	#util = require 'util'
	dyndocker_machine_name = if process.platform == 'win32' then "kitematic" else "dev" #for windows kitematic!
	console.log("dyndoc-machine="+dyndocker_machine_name)
	host = (execSync "docker-machine ip "+dyndocker_machine_name,{"env": dyndocker_env}).toString("utf-8").trim() #atom.config.get 'dyndocker.dockerServerUrl'
	port = DyndockerRunner.getPort() # instead of 7777 (beacause of kitematic)
	console.log("Host:Port="+host+":"+port)

	client = net.connect {port: port, host: host}, () ->
		#console.log (util.inspect '__send_cmd__[[dyndoc]]__' + text + end_token)
		client.write '__send_cmd__[[dyndoc]]__' + text + end_token + '\n'

		client.on 'data', (data) ->
			#console.log "data:" + data.toString()
			data.toString().split(end_token).slice(0,-1).map (cmd) ->
				#console.log("<<"+cmd+">>")
				resCmd = decode_cmd(cmd)
				if resCmd["cmd"] != "windows_platform"
						#console.log("data: "+resCmd["content"])
						callback(null, resCmd["content"])
						client.end()
				resCmd

	  	client.on 'error', (err) ->
	    	#console.log('error:', err.message)
	    	callback error,err.message

	DyndockerRunner.dyndocker_client = client 
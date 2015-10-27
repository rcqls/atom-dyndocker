path = require 'path'
fs = require 'fs'

module.exports =

  task_type: (code) ->
    re = /(?:\:cmd\s*\=\>|cmd\:)\s*\:([^\s,]*)\s*\,/
    res = re.exec code
    return if res then res[1].replace /\ /,"" else null

  write_task_from_default: (filename) ->
  	ext = path.extname filename
  	dir = path.dirname filename
  	base = path.basename filename,ext
  	default_file = path.join(process.env["HOME"],".dyntask","share","default.task_dyn.rb")
  	content = fs.readFileSync(default_file).toString('utf-8')
  	task = @task_type(content)
  	if task
  		task_filename = path.join(dir,base+".task_"+task)
  		content = content.replace /\%basename\%/g,"%"+base
  		fs.writeFileSync task_filename, content
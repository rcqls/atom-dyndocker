url = require 'url'
path = require 'path'
fs = require 'fs'

dyndocker_viewer = null
DyndockerViewer = require './dyndocker-viewer' #null # Defer until used
rendererCoffee = require './render-coffee'
rendererDyndocker = require './render-dyndocker'
DyndockerRunner = require './dyndocker-runner'

#rendererDyndocker = null # Defer until user choose mode local or server

createDyndockerViewer = (state) ->
  DyndockerViewer ?= require './dyndocker-viewer'
  dyndocker_viewer = new DyndockerViewer(state)

isDyndockerViewer = (object) ->
  DyndockerViewer ?= require './dyndocker-viewer'
  object instanceof DyndockerViewer

atom.deserializers.add
  name: 'DyndockerViewer'
  deserialize: (state) ->
    createDyndockerViewer(state) if state.constructor is Object

user_home=process.env[if process.platform=="win32" then "USERPROFILE" else "HOME"]

module.exports =
  config:
    containerName:
      type: 'string'
      default: 'dyndoc-docker'
    dyndockerHome:
      type: 'string'
      default: if fs.existsSync(path.join user_home,".dyndocker_home") then String(fs.readFileSync(path.join user_home,".dyndocker_home")).trim() else path.join user_home,"dyndocker" 
    addToPath: 
      type: 'string'
      default: '/usr/local/bin:' + path.join(user_home,"bin") # you can add anoter path with ":"
    breakOnSingleNewline:
      type: 'boolean' 
      default: false
    liveUpdate:
      type: 'boolean' 
      default: true
    grammars:
      type: 'array'
      default: [
        'source.dyndoc'
        'source.gfm'
        'text.html.basic'
        'text.html.textile'
      ]

  activate: (state) ->
    atom.commands.add 'atom-workspace', 
      'dyndocker:eval': =>
        @eval()
      'dyndocker:compile': =>
        @compile()
      'dyndocker:atom-dyndoc': =>
        @atomDyndoc()
      'dyndocker:coffee': =>
        @coffee()
      'dyndocker:toggle': =>
        @toggle()
      'dyndocker:restart': =>
        @restartServer()
      'dyndocker:toggle-break-on-single-newline': ->
        keyPath = 'dyndocker.breakOnSingleNewline'
        atom.config.set(keyPath,!atom.config.get(keyPath))


    #atom.workspaceView.on 'dyndocker:preview-file', (event) =>
    #  @previewFile(event)
 
    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'dyndocker:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        createDyndockerViewer(editorId: pathname.substring(1))
      else
        createDyndockerViewer(filePath: pathname)

  coffee: ->
    text = atom.workspace.getActiveTextEditor().getSelectedText()
    console.log rendererCoffee.eval text

  atomDyndoc: ->
    text = atom.workspace.getActiveTextEditor().getSelectedText()
    if text == ""
      text = atom.workspace.getActiveTextEditor().getText()
    #util = require 'util'

    text='[#require]Tools/AtomDyndocker\n[#main][#>]{#atomInit#}\n'+text
    ##console.log "text:  "+text
    text=text.replace /\#\{/g,"__AROBAS_ATOM__{"
    rendererDyndocker.eval text, atom.workspace.getActiveTextEditor().getPath(), (error, content) ->
      if error
        console.log "err: "+content
      else
        #console.log "before:" + content
        content=content.replace /__DIESE_ATOM__/g, '#'
        content=content.replace /__AROBAS_ATOM__\{/g, '#{'

        #
        console.log "echo:" + content
        #fs = require "fs"
        #fs.writeFile "/Users/remy/test_atom.coffee", content, (error) ->
        #  console.error("Error writing file", error) if error
        rendererCoffee.eval content

  eval: ->
    return unless dyndocker_viewer
    text = atom.workspace.getActiveTextEditor().getSelectedText()
    if text == ""
      text = atom.workspace.getActiveTextEditor().getText()
    dyndocker_viewer.render(text)
    #res = renderer.toText text, "toto", (error, content) ->
    #  if error
    #    console.log "err: "+content
    #  else
    #   console.log "echo:" + content

  compile: -> 
    dyn_file = atom.workspace.getActivePaneItem().getPath()
    console.log("compile dyn_file:"+dyn_file)
    DyndockerRunner.compile dyn_file

  restartServer: ->
    DyndockerRunner.restart()

  toggle: ->
    console.log("dyndocker:toggle")
    if isDyndockerViewer(atom.workspace.activePaneItem)
      atom.workspace.destroyActivePaneItem()
      return

    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    console.log("dyndocker:toggle")
    #grammars = atom.config.get('dyndocker-viewer.grammars') ? []
    #return unless editor.getGrammar().scopeName in grammars

    @addDyndockerViewerForEditor(editor) unless @removeDyndockerViewerForEditor(editor)

  uriForEditor: (editor) ->
    "dyndocker://editor/#{editor.id}"

  removeDyndockerViewerForEditor: (editor) ->
    uri = @uriForEditor(editor)
    console.log(uri)
    previewPane = atom.workspace.paneForURI(uri)
    console.log("preview-pane: "+previewPane)
    if previewPane?
      previewPane.destroyItem(previewPane.itemForURI(uri))
      true
    else
      false

  addDyndockerViewerForEditor: (editor) ->
    uri = @uriForEditor(editor)
    console.log "uri:"+uri
    previousActivePane = atom.workspace.getActivePane()
    atom.workspace.open(uri, split: 'right', searchAllPanes: true).done (DyndockerViewer) ->
      if isDyndockerViewer(DyndockerViewer)
        #DyndockerViewer.renderDyndoc()
        previousActivePane.activate()


  # previewFile: ({target}) ->
  #   filePath = $(target).view()?.getPath?() #Maybe to replace with: filePath = target.dataset.path
  #   return unless filePath

  #   for editor in atom.workspace.getEditors() when editor.getPath() is filePath
  #     @addPreviewForEditor(editor)
  #     return

  #   atom.workspace.open "dyndocker://#{encodeURI(filePath)}", searchAllPanes: true

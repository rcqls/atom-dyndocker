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

module.exports =
  config:
    dyndockerHome:
      type: 'string'
      default: if fs.existsSync(path.join process.env["HOME"],".dyndoc_home") then String(fs.readFileSync(path.join process.env["HOME"],".dyndoc_home")).trim() else path.join process.env["HOME"],"dyndoc" 
    addToPath: 
      type: 'string'
      default: '/usr/local/bin:' + path.join(process.env["HOME"],"bin") # you can add anoter path with ":"
    dockerServerUrl:
      type: 'string'
      default: '192.168.99.100'
    dockerServerPort: 
      type: 'integer'
      default: 49153
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

  activate: ->
    atom.commands.add 'atom-workspace', 
      'dyndocker-viewer:eval': =>
        @eval()
      'dyndocker-viewer:compile': =>
        @compile()
      'dyndocker-viewer:atom-dyndoc': =>
        @atomDyndoc()
      'dyndocker-viewer:coffee': =>
        @coffee()
      'dyndocker-viewer:toggle': =>
        @toggle()
      'dyndocker-viewer:start': =>
        @startServer()
      'dyndocker-viewer:kill': =>
        @killServer()
      'dyndocker-viewer:toggle-break-on-single-newline': ->
        keyPath = 'dyndocker-viewer.breakOnSingleNewline'
        atom.config.set(keyPath,!atom.config.get(keyPath))


    #atom.workspaceView.on 'dyndocker-viewer:preview-file', (event) =>
    #  @previewFile(event)
 
    atom.workspace.registerOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return

      return unless protocol is 'dyndocker-viewer:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        createDyndockerViewer(editorId: pathname.substring(1))
      else
        createDyndockerViewer(filePath: pathname)

    DyndockerRunner.start()

  deactivate: ->
    DyndockerRunner.stop()

  coffee: ->
    selection = atom.workspace.getActiveEditor().getSelection()
    text = selection.getText()
    console.log rendererCoffee.eval text

  atomDyndoc: ->
    selection = atom.workspace.getActiveEditor().getSelection()
    text = selection.getText()
    if text == ""
      text = atom.workspace.getActiveEditor().getText()
    #util = require 'util'

    text='[#require]Tools/Atom\n[#main][#>]{#atomInit#}\n'+text
    ##console.log "text:  "+text
    text=text.replace /\#\{/g,"__AROBAS_ATOM__{"
    rendererDyndocker.eval text, atom.workspace.getActiveEditor().getPath(), (error, content) ->
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
    selection = atom.workspace.getActiveEditor().getSelection()
    text = selection.getText()
    if text == ""
      text = atom.workspace.getActiveEditor().getText()
    dyndocker_viewer.render(text)
    #res = renderer.toText text, "toto", (error, content) ->
    #  if error
    #    console.log "err: "+content
    #  else
    #   console.log "echo:" + content

  compile: -> 
    dyn_file = atom.workspace.activePaneItem.getPath()
    console.log("compile dyn_file:"+dyn_file)
    DyndockerRunner.compile dyn_file

  startServer: ->
    DyndockerRunner.start()

  killServer: ->
    DyndockerRunner.stop()

  toggle: ->
    if isDyndockerViewer(atom.workspace.activePaneItem)
      atom.workspace.destroyActivePaneItem()
      return

    editor = atom.workspace.getActiveEditor()
    return unless editor?

    #grammars = atom.config.get('dyndocker-viewer.grammars') ? []
    #return unless editor.getGrammar().scopeName in grammars

    @addPreviewForEditor(editor) unless @removePreviewForEditor(editor)

  uriForEditor: (editor) ->
    "dyndocker-viewer://editor/#{editor.id}"

  removePreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
    console.log(uri)
    previewPane = atom.workspace.paneForUri(uri)
    console.log("preview-pane: "+previewPane)
    if previewPane?
      previewPane.destroyItem(previewPane.itemForUri(uri))
      true
    else
      false

  addPreviewForEditor: (editor) ->
    uri = @uriForEditor(editor)
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

  #   atom.workspace.open "dyndocker-viewer://#{encodeURI(filePath)}", searchAllPanes: true

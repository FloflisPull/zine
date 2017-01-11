# TODO: Move handlers out
AudioBro = require "../apps/audio-bro"
Filter = require "../apps/filter"
TextEditor = require "../apps/text-editor"
Spreadsheet = require "../apps/spreadsheet"
PixelEditor = require "../apps/pixel"
Markdown = require "../apps/markdown"

openWith = (App) ->
  (file) ->
    app = App()
    app.loadFile(file.blob)
    document.body.appendChild app.element

module.exports = (I, self) ->
  # TODO: Handlers that can use combined type, extension, and contents info
  # to do the right thing
  # Prioritize handlers falling back to others
  handlers = [{
    # JavaScript
    name: "Execute"
    filter: (file) ->
      file.type is "application/javascript" or
      file.path.match /\.js$/
    fn: (file) ->
      self.include([file.path])
      .then ([moduleExports]) ->
        moduleExports
  }, {
    # CoffeeScript
    name: "Execute"
    filter: (file) ->
      file.path.match /\.coffee$/
    fn: (file) ->
      file.blob.readAsText()
      .then (coffeeSource) ->
        sourceProgram = CoffeeScript.compile coffeeSource, bare: true

        system.loadModule sourceProgram, file.path
  }, {
    name: "Markdown"
    filter: (file) ->
      file.path.match /\.md$/
    fn: openWith(Markdown)
  }, {
    name: "Text Editor"
    filter: (file) ->
      file.type.match(/^text\//) or
      file.type is "application/javascript"
    fn: openWith(TextEditor)
  }, {
    name: "Spreadsheet"
    filter: (file) ->
      # TODO: This actually only handles JSON arrays
      file.type is "application/json"
    fn: openWith(Spreadsheet)
  }, {
    name: "Image Viewer"
    filter: (file) ->
      file.type.match /^image\//
    fn: openWith(Filter)
  }, {
    name: "Pixel Editor"
    filter: (file) ->
      file.type.match /^image\//
    fn: openWith(PixelEditor)
  }, {
    name: "Audio Bro"
    filter: (file) ->
      file.type.match /^audio\//
    fn: openWith(AudioBro)
  }]

  # Open JSON arrays in spreadsheet
  # Open text in notepad
  handle = (file) ->
    handler = handlers.find ({filter}) ->
      filter(file)

    if handler
      handler.fn(file)
    else
      throw new Error "No handler for files of type #{file.type}"

  Object.assign self,
    # Open a file
    # TODO: Pass arguments
    # TODO: Drop files on an app to open them in that app
    open: (file) ->
      handle(file)

    openersFor: (file) ->
      handlers.filter (handler) ->
        handler.filter(file)

  return self
uuid = require 'uuid/v4'
unless window?.Vue? # Vue is loaded in <SCRIPT> tag; don't try 'require' it
  Vue = require 'vue'
hs = require './helpers'

class DMStore
  constructor: (@name) ->

  attach: (@state) ->

  _get_deep: (object, keypath) ->
    keys = keypath.split '.'
    sub = object
    for key, index in keys
      if index is keys.length-1 # last keypath key; return value
        return sub[key]
      else # recurse another level
        if sub[key]?
          sub = sub[key]
        else
          return

  _set_deep: (object, keypath, value) ->
    keys = keypath.split '.'
    sub = object
    for key, index in keys
      if index is keys.length-1 # last keypath key; set value
        sub[key] = value
        return true
      else # recurse another level
        if sub[key]?
          sub = sub[key]
        else
          return false

  _mutate: (selector, value, track_changes) => # SELECTOR may be simple string or dot-notation keypath
    set = @_set_deep @state, selector, value
    if set
      @state._dirty = if hs.typeof(track_changes) is 'boolean' then track_changes else true
    else
      throw new Error "No such property '#{selector}' in <#{@name}> component state object"

  init_collection: (selector, data, key='_id') =>
    @mutate_collection selector, data, key, false

  init_value: (selector, data) =>
    @mutate_value selector, data, false

  mutate_collection: (selector, data, key='_id', track_changes) =>
    m = new Map
    m.set item[key], item for item in data
    @_mutate selector, m, track_changes

  mutate_value: (selector, data, track_changes) => # apply mutations to state
    @_mutate selector, data, track_changes


class VuePlugin
  constructor: ->

  install: (Vue, options) ->
    Vue.mixin
      data: () ->
        _dmstate: {}
        store: {}
        dmstore_uuid: uuid()

      directives:
        'state-model': # provide attribute directive to replace V-MODEL
          bind: (el, binding, vnode) ->
            keypath = binding.expression
            store = vnode.context.store.app # bind to component DMStore instance
            state = vnode.context._dmstate
            component_state = vnode.context.state
            if el.tagName.toLowerCase() is 'input' and el.type.toLowerCase() is 'text'
              event_type = 'input'
              value_key = 'value'
            else # radio/checkbox
              event_type = 'change'
              value_key = 'checked'
            el[value_key] = store._get_deep vnode.context, keypath # set <INPUT> initial value

            el.addEventListener event_type, (event) ->
              # update component state with changed <INPUT> value
              value = event.target[value_key]
              dot = keypath.indexOf '.'
              keypath = keypath.substring(dot+1) if dot > -1 # trim leading 'property.'
              store.mutate_value keypath, value # update central state
              store._set_deep component_state, keypath, value # update component STATE


      methods:
        clean: -> # skip if element has already been removed from DOM
          @$root.store.state[@dmstore_uuid]?._dirty = false


      created: ->
        if @$parent? and @state? # Vue component with defined STATE data property
          name = @$options.name or 'unnamed'
          dm = new DMStore name
          @$root.store.state[@dmstore_uuid] = { _dirty: false }
          dm.attach @$root.store.state[@dmstore_uuid]
          Vue.set @store, 'app', dm
        else # root Vue instance
          Vue.set @store, 'state', {}


      destroyed: ->
        return unless @$parent? # skip for root Vue instance
        delete @$root.store.state[@dmstore_uuid]


      mounted: ->
        return unless @$parent? # skip for root Vue instance
        return unless @state? # skip if component has no STATE property
        for own k,v of @state
          @$root.store.state[@dmstore_uuid][k] = v
          @$root.store.state[@dmstore_uuid]._dirty = false
        @_dmstate = @$root.store.state[@dmstore_uuid]


module.exports = VuePlugin

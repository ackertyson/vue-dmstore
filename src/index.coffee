unless window?.Vue? # Vue is loaded in <SCRIPT> tag; don't try 'require' it
  Vue = require 'vue'
hs = require './helpers'

class DMStore
  @state: {} # static property shared between all instances

  constructor: (state, @name) ->
    @c = @constructor
    if @name? # child store (from Vue component)
      if @c.state[@name]?
        @c.state[@name] = state # mount child state on root
      else
        throw new Error "No state found for <#{@name}> component; did you forget to add the '#{@name}' key to the Vue instance DATA property?"
    else # root store (from Vue instance)
      @c.state = state # initialize root state object

  _mutate: (selector, state, value, track_changes) => # SELECTOR may be simple string or dot-notation keypath
    substate = state
    selector_array = selector.split '.'
    selector_array.forEach (key, index) =>
      if index is selector_array.length-1 # last keypath key; set value
        substate[key] = value
        state._dirty = if hs.typeof(track_changes) is 'boolean' then track_changes else true
      else # recurse another level into STATE
        if substate[key]?
          substate = substate[key]
        else
          throw new Error "No such property '#{selector}' in <#{@name}> component state object"

  init_collection: (selector, data, key='_id') =>
    @mutate_collection selector, data, key, false

  init_value: (selector, data) =>
    @mutate_value selector, data, false

  mutate_collection: (selector, data, key='_id', track_changes) =>
    m = new Map
    m.set item[key], item for item in data
    @_mutate selector, @c.state[@name], m, track_changes

  mutate_value: (selector, data, track_changes) => # apply mutations to state
    @_mutate selector, @c.state[@name], data, track_changes


class VuePlugin
  constructor: ->

  attach: (name, state) -> # instantiate child DMStore (from Vue component)
    child = new DMStore state, name
    child

  install: (Vue, options) ->
    Vue.mixin
      data: () ->
        dmstate: {} # initialize root state object on Vue instance
      directives:
        'state-model': # provide attribute directive to replace V-MODEL
          update: (el, binding, vnode) ->
            el.value = binding.value # set initial <INPUT> value
            # remove leading 'state.' from keypath (if it exists)
            keypath = binding.expression.substring binding.expression.indexOf('.')+1 if /^state\./.test binding.expression
            store = vnode.context.store # bind to component DMStore instance
            el.addEventListener 'input', (event) ->
              # update component state with changed <INPUT> value
              store.mutate_value keypath, event.target.value
      created: () ->
        state = @$options.store # root state object is passed in via STORE option on Vue instance
        if state?
          store = new DMStore state # instantiate root DMStore
          Vue.set @, 'dmstate', DMStore.state # mount the (static!) state object and make it reactive
    Vue::$dmstore = @


module.exports = VuePlugin

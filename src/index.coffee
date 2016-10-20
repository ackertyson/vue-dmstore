###
APP NAME: DM Store
DESCRIPTION: Vue plugin providing simple centralized state management.
USAGE:

DMStore = require './store'
Vue.use new DMStore

component_names = ['ticket', 'work_order']
state = {}
components = {}
for name in component_names
  state[name] = {} # add child branch for each component
  components[name] = require "./components/#{name}"

new Vue
  el: '#app'
  components: components
  store: state # initialize DMStore with skeleton state object

Vue.extend # TICKET component...
  template: '.ticket'
  computed:
    count: () -> @state.items.size
  data: () ->
    store: {} # DMStore instance will be mounted here
    state: # initial values for DMStore component state
      _dirty: false
      items: []
      selected: {}
  created: () ->
    @store = @$dm_store.attach 'ticket', @state
  mounted: () ->
    Ticket.fetch_all().then (tickets) =>
      # 'init' methods skip change detection...
      @store.init_collection 'items', tickets
      @store.init_value 'selected', @state.items.get(1000001)
    .catch (err) ->
      console.log err

...and in the template (notice the custom MODEL attribute!)....

.ticket
  p Records found: {{ count }}
  input(type="text", v-state-model="state.selected.location")
###

unless window.Vue? # Vue is loaded in <SCRIPT> tag; don't try 'require' it
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

  init_array: (selector, data) =>
    @mutate_array selector, data, false

  init_collection: (selector, data, key='_id') =>
    @mutate_collection selector, data, key, false

  init_value: (selector, data) =>
    @mutate_value selector, data, false

  _mutate: (selector, state, value) => # SELECTOR may be simple string or dot-notation keypath
    substate = state
    selector_array = selector.split '.'
    selector_array.forEach (key, index) =>
      if index is selector_array.length-1 # last keypath key; set value
        substate[key] = value
      else # recurse another level into STATE
        if substate[key]?
          substate = substate[key]
        else
          throw new Error "No such property '#{selector}' in <#{@name}> component state object"

  mutate_array: (selector, data, track_changes) =>
    arr = (item for item in data)
    @_mutate selector, @c.state[@name], arr
    @c.state[@name]._dirty = if hs.typeof(track_changes) is 'boolean' then track_changes else true

  mutate_collection: (selector, data, key='_id', track_changes) =>
    m = new Map
    m.set item[key], item for item in data
    @_mutate selector, @c.state[@name], m
    @c.state[@name]._dirty = if hs.typeof(track_changes) is 'boolean' then track_changes else true

  mutate_value: (selector, data, track_changes) => # apply mutations to state
    @_mutate selector, @c.state[@name], data
    @c.state[@name]._dirty = if hs.typeof(track_changes) is 'boolean' then track_changes else true


class VuePlugin
  constructor: ->

  attach: (name, state) -> # instantiate child DMStore (from Vue component)
    child = new DMStore state, name
    child

  install: (Vue, options) ->
    Vue.mixin
      data: () ->
        dm_state: {} # initialize root state object on Vue instance
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
          Vue.set @, 'dm_state', DMStore.state # mount the (static!) state object and make it reactive
    Vue::$dm_store = @


module.exports = VuePlugin

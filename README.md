#DM Store

Vue plugin providing simple centralized state management

##INSTALLATION

`npm i --save vue-dmstore`

##USAGE
```
DMStore = require 'vue-dmstore'
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
```

...and in the template (notice the custom MODEL attribute!)....
```
.ticket
  p Records found: {{ count }}
  input(type="text", v-state-model="state.selected.location")
```

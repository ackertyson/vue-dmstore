# DM Store

Vue plugin providing simple centralized state management

## INSTALLATION

`npm i --save vue-dmstore`

## USAGE
```
DMStore = require 'vue-dmstore'
Vue.use new DMStore

new Vue().$mount('#app')

Vue.extend # TICKET component...
  name: 'Ticket'
  template: '.ticket'
  data: ->
    state: {} # placeholder for DMStore component state
  mounted: ->
    Ticket.fetch_by_id(1234).then (ticket) =>
      @state = ticket # set initial component state from data
    .catch (err) ->
      console.log err
```

...and in the template (notice the custom MODEL attribute!)....
```
.ticket
  label Date
  input(type="text", v-state-model="state.date")
  label Location
  input(type="text", v-state-model="state.location")
```

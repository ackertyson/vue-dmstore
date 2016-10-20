module.exports =

  canDeactivate: (to, from, next) ->
    if @state._dirty
      next confirm "Abandon changes?"
    else
      next()
      
  clone_obj: (obj) ->
    clone = {}
    for own k,v of obj
      clone[k] = v
    clone

  no_empties: (element) -> # discard empty strings from array (use in Array::filter())
    element.trim().length > 0

  typeof: (subject) ->
    # typeof that actually works!
    Object::toString.call(subject).toLowerCase().slice(8, -1)

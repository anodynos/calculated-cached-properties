(urequire: rootExports: 'CalculatedCachedProperties')

_ = # a poor man's dummy underscore / lodash
  extend: (target, source)-> target[key] = source[key] for key of source; return
  defaults: (target, source)-> target[key] = source[key] for key of source when not target.hasOwnProperty key; return
  keys: (obj)-> key for key of obj
  isFunction: (f)-> typeof f is "function"

# TODO: add documentation, readme.md & examples

# Instances have calculated *cached* properties.
# Properties are calculated on 1st use, use the cache thereafter.
# Properties can be cleaned with cleanProp (String|Function)...
class CalculatedCachedProperties

  @VERSION: VERSION # injected by urequire-inject-version

  prefix = (prop)-> '__$$_CCP_' + prop
  cacheKey = prefix 'cache'
  cUndefined = {'CalculatedCachedProperties Undefined': true} # allow undefined as a valid cached value - store this instead of deleting key

  # register simple pojsos or constructor functions
  @register: (pojsoOrConstructor, calcProperties, options=CalculatedCachedProperties.optionsDefaults)->

    if options isnt CalculatedCachedProperties.optionsDefaults
      _.defaults (options or= {}), CalculatedCachedProperties.optionsDefaults

    if _.isFunction pojsoOrConstructor
      classConstructor = pojsoOrConstructor
      _.extend classConstructor.prototype, CalculatedCachedProperties.prototype
      _.extend (classConstructor.CCP_calcProperties or= {}), calcProperties
      classConstructor.prototype._CCP_defineCalcProperties options # does not initialize the cache yet
    else
      pojso = pojsoOrConstructor
      # TODO: check these are optimal & correct at all cases
      _.extend pojso.__proto__ = {}, CalculatedCachedProperties.prototype
      pojso.constructor = ctor = ->
      ctor.prototype = pojso.__proto__
      _.extend ctor.prototype, CalculatedCachedProperties.prototype
      _.extend (ctor.CCP_calcProperties or= {}), calcProperties

      pojso._CCP_defineCalcProperties options

    pojsoOrConstructor

  # Gets all coffeescript classes (i.e constructors linked via __super__) of given obj, constructor or target instance.
  # If called on an instance without params, it gets all inherited classes for this instance (including its own class).
  #
  # @param instOrClass {Object|class} optional
  #   If an object instance is passed, we get all the classes that its constructor is extending (including its own class)
  #   If a constructor Function (i.e coffeeScript class) is passed, we again get all classes it is extending.
  #
  #   It can be called without `instOrClass` param, in which case it is initialized to `this`, which means:
  #     * the instance if the target is an instance (i.e `myinstance.CCP_getClasses()`
  #     * the class if its called statically on the class (i.e `MyClass.CCP_getClasses()`)
  #
  # @return Array<Function> of coffeescript classes (i.e `constructor`s) of given object or class/constuctor.
  #    Order is descending i.e Base class is first, followed by all subclasses, the last one being the given constructor / current instance's class.
  CCP_getClasses: (instOrClass, _classes=[])->
    instOrClass = @ if not instOrClass

    if not _.isFunction instOrClass
      instOrClass = instOrClass.constructor

    _classes.unshift instOrClass

    if instOrClass.__super__
      @CCP_getClasses instOrClass.__super__.constructor, _classes
    else
      _classes

  @CCP_getClasses: @::CCP_getClasses

  # @return Object with {calcPropertyName:calcPropertyFunction} of all (inherited) CCP_calcProperties.
  # Properties in subclasses override (overwrite) those os super classes.
  CCP_getAllCalcProperties: (instOrClass=@)->
    calcProps = {}
    for aClass in @CCP_getClasses(instOrClass)
      for cProp, cFunct of aClass.CCP_calcProperties
        calcProps[cProp] = cFunct # overwrite inherited properties with subclass's properties
    calcProps

  @CCP_getAllCalcProperties: @::CCP_getAllCalcProperties

  Object.defineProperties @::,

    CCP_allCalcProperties: get:->
      if not @constructor::hasOwnProperty '_allCalcProperties' # use cached result, shared by all instances
        Object.defineProperty @constructor::, '_allCalcProperties', value: @CCP_getAllCalcProperties(), enumerable: false
      @constructor::_allCalcProperties

    CCP_classes: get:->
      if not @constructor::hasOwnProperty '_classes' # use cached result, shared by all instances
        Object.defineProperty @constructor::, '_classes', value: @CCP_getClasses(), enumerable: false
      @constructor::_classes

  # TODO: how to pass options from subclasses 
  constructor: (options)-> @_CCP_defineCalcProperties options or {}

  ###
  # Creates the cache {} held in `cacheKey` as a non enumerable field (i.e hidden)
  # and initializes each property value to `cUndefined`
  ###
  _CCP_initCache: ->
    if @constructor.isDebug(30)
      console.log "CalculatedCachedProperties: Initializing cache for calculated properties of constructor named `#{@constructor.name or 'UNNAMED'}`"

    # TODO: check if exists & just reset ?
    Object.defineProperty @, cacheKey, value: {}, enumerable: true, configurable: false, writeable: false

    for cPropName, cPropFn of @CCP_allCalcProperties or @CCP_getAllCalcProperties()
      @[cacheKey][cPropName] = cUndefined

    return

  _CCP_defineCalcProperties: (options)->
    @constructor.isDebug = (lev)-> options.debugLevel >= lev

    console.log "CalculatedCachedProperties: options {} for #{@constructor.name or 'UNNAMED'}", options if @constructor.isDebug(10)

    for cPropName, cPropFn of @CCP_allCalcProperties or @CCP_getAllCalcProperties()
      if not @constructor::hasOwnProperty(cPropName) or options.isOverwrite
        do (cPropName, cPropFn)=>
          console.log "CalculatedCachedProperties: DEFINE calculated property #{@constructor.name or 'UNNAMED'}.#{cPropName}" if @constructor.isDebug(20)
          Object.defineProperty @constructor::, cPropName, # @todo: allow instance properties to be added dynamically
            enumerable: true
            configurable: true # @todo: check if its not same class and redefine ?
            get:->
              @_CCP_initCache() if not @[cacheKey] # make sure it runs on the instance

              # do we have a cached value ?
              if @[cacheKey][cPropName] is cUndefined
                console.log "CalculatedCachedProperties: CALCULATING & CACHING property #{@constructor.name or 'UNNAMED'}.#{cPropName}" if @constructor.isDebug(40)
                result = cPropFn.call @

                if @constructor.isDebug(80)
                  if not @constructor.isDebug(1000)
                    console.log "CalculatedCachedProperties: calculated value of #{@constructor.name or 'UNNAMED'}.#{cPropName} :", result

                @[cacheKey][cPropName] = result

              if @constructor.isDebug(100)
                console.log "CalculatedCachedProperties: GET value of calculated property #{@constructor.name or 'UNNAMED'}.#{cPropName}",
                if @constructor.isDebug(1000) then @[cacheKey][cPropName] else ""

              return @[cacheKey][cPropName]

            set: (v)->
              @_CCP_initCache() if not @[cacheKey] # make sure it runs on the instance
              if @constructor.isDebug(50)
                console.log "CalculatedCachedProperties: SET value of property #{@constructor.name or 'UNNAMED'}.#{cPropName}"
              @[cacheKey][cPropName] = v
    return

  # use as CCP_clean 'propName1', ((p)-> p is 'propName2'), undefined, 'propName3'
  # or CCP_clean() to clear them all
  # undefined args are ignored
  CCP_clean: (cleanArgs...)->
    cleanArgs = _.keys(@CCP_allCalcProperties or @CCP_getAllCalcProperties()) if cleanArgs.length is 0
    cleaned = []
    for ca in cleanArgs when ca
      if _.isFunction ca
        propKeys = _.keys(@CCP_allCalcProperties or @CCP_getAllCalcProperties()) if not propKeys # `propKeys or=` can't be assigned with ||= because it has not been declared before
        for p in propKeys when ca(p)
          if @constructor.isDebug(60)
            console.log "CalculatedCachedProperties: CLEAN (via function) value of property #{@constructor.name or 'UNNAMED'}.#{p}"
          if not @[cacheKey]
            @_CCP_initCache() # init cache sets all to cUndefined
          else
            @[cacheKey][p] = cUndefined
          cleaned.push p
      else # should be string-able
        if @constructor.isDebug(60)
          console.log "CalculatedCachedProperties: CLEAN value of property #{@constructor.name or 'UNNAMED'}.#{ca}"
        if not @[cacheKey]
          @_CCP_initCache() # init cache sets all to cUndefined
        else
          @[cacheKey][ca] = cUndefined
        cleaned.push ca

    return cleaned # return names of cleaned props

CalculatedCachedProperties.optionsDefaults =

  isOverwrite: false # with `true`, overwrites properties that already exist on the instance's prototype

  debugLevel: 0      # an int level of 0 - 1000 (NOTE: works only in dev build), min version removes debuging logs.
                     # It `console.log`s what is happening, with levels:
                     #    10 - prints options, as stored in instance's constructor
                     #    20 - a calcProperty's defined
                     #    30 - a calcProperty's cache initialized
                     #    40 - a calcProperty calculated (i.e refreshed)
                     #    50 - calcProperty value is set (manually)
                     #    60 - calcProperty deleted
                     #    80 - calcProperty calculated, its new cached value is printed.
                     #    100 - calcProperty is read (cache hit)
                     #    1000 - calcProperty is read (cache hit) insane mode: its value is printed!

module.exports = CalculatedCachedProperties

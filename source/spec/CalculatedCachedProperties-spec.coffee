describe "CalculatedCachedProperties:", ->

  class CalculatedCachedProperties2 extends CalculatedCachedProperties

  class SelfishNumber extends CalculatedCachedProperties2
    constructor: ->
      super
      @setNums.apply @, arguments

    setNums: (@x, @y)->
      @calcHits = {}

    @calcProperties =
      doubled: ->
        @calcHits.doubled = (@calcHits.doubled or 0) + 1
        if @x < 1000
          @x + @x
        else
          undefined # a valid cached result

      added: -> throw new Error('Abstract method')

  class DirtyNumbers extends SelfishNumber

    @calcProperties =
      added: ->
        @calcHits.added = (@calcHits.added or 0) + 1
        @x + @y

      multiplied: ->
        @calcHits.multiplied = (@calcHits.multiplied or 0) + 1
        @x * @y

  allDnProperties =
    doubled: SelfishNumber.calcProperties.doubled
    added: DirtyNumbers.calcProperties.added # overriden
    multiplied: DirtyNumbers.calcProperties.multiplied

  describe "Get classes & calcProperties of inherited classes", ->
    dn = new DirtyNumbers
    sn = new SelfishNumber

    describe "called on target instance:", ->
      it "#1", ->
        deepEqual dn.classes, [CalculatedCachedProperties, CalculatedCachedProperties2, SelfishNumber, DirtyNumbers ]

      it "#2", ->
        deepEqual sn.classes, [CalculatedCachedProperties, CalculatedCachedProperties2, SelfishNumber]

    describe "Get all calculated properties, overriding properties in parent classes:", ->

      describe "without params:", ->
        describe "called on instance:", ->
          it "#1", ->
            deepEqual dn.getAllCalcProperties(), allDnProperties
            deepEqual dn.allCalcProperties, allDnProperties

          it "#2", ->
            deepEqual sn.getAllCalcProperties(), SelfishNumber.calcProperties
            deepEqual sn.allCalcProperties, SelfishNumber.calcProperties

        describe "called statically:", ->
          it "#1", -> deepEqual DirtyNumbers.getAllCalcProperties(), allDnProperties
          it "#2", -> deepEqual SelfishNumber.getAllCalcProperties(), SelfishNumber.calcProperties

      describe "with instance as param:", ->

        describe "called on (any) instance:", ->
          it "#1", -> deepEqual sn.getAllCalcProperties(dn), allDnProperties
          it "#2", -> deepEqual dn.getAllCalcProperties(sn), SelfishNumber.calcProperties

        describe "called statically (on any class):", ->
          it "#1", ->
            deepEqual DirtyNumbers.getAllCalcProperties(dn), allDnProperties
            deepEqual SelfishNumber.getAllCalcProperties(dn), allDnProperties
            deepEqual CalculatedCachedProperties.getAllCalcProperties(dn), allDnProperties
          it "#2", ->
            deepEqual DirtyNumbers.getAllCalcProperties(sn), SelfishNumber.calcProperties
            deepEqual SelfishNumber.getAllCalcProperties(sn), SelfishNumber.calcProperties
            deepEqual CalculatedCachedProperties.getAllCalcProperties(sn), SelfishNumber.calcProperties

      describe "with class as param:", ->

        describe "called on (any) instance:", ->
          it "#1", -> deepEqual sn.getAllCalcProperties(DirtyNumbers), allDnProperties
          it "#2", -> deepEqual dn.getAllCalcProperties(SelfishNumber), SelfishNumber.calcProperties

      describe "called statically (on any class):", ->
        it "#1", ->
          deepEqual CalculatedCachedProperties.getAllCalcProperties(DirtyNumbers), allDnProperties
          deepEqual SelfishNumber.getAllCalcProperties(DirtyNumbers), allDnProperties
        it "#2", ->
          deepEqual CalculatedCachedProperties.getAllCalcProperties(SelfishNumber), SelfishNumber.calcProperties
          deepEqual DirtyNumbers.getAllCalcProperties(SelfishNumber), SelfishNumber.calcProperties

  describe "POJSO's prototype registering:", ->
    ObjectDotPrototype = _.clone Object.prototype, true

    calcValue = { some: 'value' }

    obj = CalculatedCachedProperties.register { someProp: 5 }, someCalcProperty: -> calcValue

    it "does not alter the Object prototype", ->
      deepEqual ObjectDotPrototype, Object.prototype

    it "alters the registered instance's prototype", ->
      notDeepEqual obj.__proto__, Object.prototype
      like CalculatedCachedProperties::, obj.__proto__
      ok _.has obj.__proto__, 'someCalcProperty'

    it "instance is still an Object instance ", ->
      tru _.isObject obj
      tru _B.isHash obj

    it "calulated property has the correct value", ->
      equal obj.someCalcProperty, calcValue

    it.skip "object instance is correctly identified as such", ->
      tru _.isPlainObject obj       # fails
      tru obj.constructor is Object # fails

  describe "calculating & caching properties:", ->

    DirtyNumbersJSConstructor = ->
      @setNums.apply @, arguments
      @

    _.extend DirtyNumbersJSConstructor.prototype,
        setNums: (@x, @y)->
          @calcHits = {}

    CalculatedCachedProperties.register DirtyNumbersJSConstructor, allDnProperties

    for dirtyNums in [
        title: "Coffeescript class instances"

        dn: new DirtyNumbers 3, 4

        dn2: new DirtyNumbers 5, 6

        dn3: new DirtyNumbers 1001
      ,
        title: "Javascript instances (via constructor function)"

        dn: new DirtyNumbersJSConstructor 3, 4

        dn2: new DirtyNumbersJSConstructor 5, 6

        dn3: new DirtyNumbersJSConstructor 1001
      ,
        title: "POJSO instances"

        dn: (CalculatedCachedProperties.register {
          setNums: (@x, @y)-> @calcHits = {}; @
        }, allDnProperties).setNums 3, 4

        dn2: (CalculatedCachedProperties.register {
          setNums: (@x, @y)-> @calcHits = {}; @
        }, allDnProperties).setNums 5, 6

        dn3: (CalculatedCachedProperties.register {
          setNums: (@x, @y)-> @calcHits = {}; @
        }, allDnProperties).setNums 1001
    ]
      {title, dn, dn2, dn3} = dirtyNums
      do (dn, dn2, dn3)->

        describe "calculates calcProperties once: for `#{title}`: ", ->

          it "#1", ->
            equal dn.doubled, 6
            equal dn.doubled, 6
            equal dn.calcHits.doubled, 1

            equal dn.added, 7
            equal dn.added, 7
            equal dn.calcHits.added, 1

            equal dn.multiplied, 12
            equal dn.multiplied, 12
            equal dn.calcHits.multiplied, 1

          it "#2", ->
            equal dn2.doubled, 10
            equal dn2.doubled, 10
            equal dn2.calcHits.doubled, 1

            equal dn2.added, 11
            equal dn2.added, 11
            equal dn2.calcHits.added, 1

            equal dn2.multiplied, 30
            equal dn2.multiplied, 30
            equal dn2.calcHits.multiplied, 1

        describe "remembers cached result, without calculating", ->

          it "#1", ->
            dn.x = 55; dn.y = 44;
            equal dn.added, 7
            equal dn.added, 7
            equal dn.calcHits.added, 1

            equal dn.multiplied, 12
            equal dn.multiplied, 12
            equal dn.calcHits.multiplied, 1

          it "#2", ->
            dn2.x = 22; dn2.y = 33;
            equal dn2.added, 11
            equal dn2.added, 11
            equal dn2.calcHits.added, 1

            equal dn2.multiplied, 30
            equal dn2.multiplied, 30
            equal dn2.calcHits.multiplied, 1

        describe "setting value of property manually becomes the cached result", ->

          it "#1", ->
            dn.added = 333
            equal dn.added, 333
            equal dn.added, 333
            equal dn.calcHits.added, 1

            dn.multiplied = 555
            equal dn.multiplied, 555
            equal dn.multiplied, 555
            equal dn.calcHits.multiplied, 1

          it "#2", ->
            dn2.added = 444
            equal dn2.added, 444
            equal dn2.added, 444
            equal dn2.calcHits.added, 1

            dn2.multiplied = 777
            equal dn2.multiplied, 777
            equal dn2.multiplied, 777
            equal dn2.calcHits.multiplied, 1

        describe "clearing cached property value & recalculate 'em:", ->

          it "clears cached properties by name & recalculates them on demand", ->

            deepEqual dn.cleanProps('added'), ['added']

            dn.x = 6; dn.y = 3
            equal dn.calcHits.added, 1

            equal dn.added, 9
            equal dn.calcHits.added, 2

            equal dn.added, 9
            equal dn.added, 9
            equal dn.calcHits.added, 2

            equal dn.calcHits.multiplied, 1
            equal dn.multiplied, 555
            equal dn.multiplied, 555
            equal dn.calcHits.multiplied, 1

          it "clears cached property values by name or function, ignoring undefined", ->
            dn.x = 6; dn.y = 4
            deepEqual(
              dn.cleanProps(undefined, 'doubled', undefined, ((nme)-> nme is 'multiplied'), undefined)
              , ['doubled', 'multiplied'])

            # cleared, recalculating once
            equal dn.calcHits.doubled, 1
            equal dn.doubled, 12
            equal dn.doubled, 12
            equal dn.calcHits.doubled, 2

            # not cleared, stays as is
            equal dn.calcHits.added, 2
            equal dn.added, 9
            equal dn.added, 9
            equal dn.calcHits.added, 2

            # cleared, recalculating once
            equal dn.calcHits.multiplied, 1
            equal dn.multiplied, 24
            equal dn.multiplied, 24
            equal dn.calcHits.multiplied, 2

          describe "clears all cached property values, recalculates them all on demand", ->

            it "clears all cached property values", ->
              deepEqual dn.cleanProps(), ['doubled', 'added', 'multiplied']

            it "clearing forces recaclulation of inherited property value", ->
              dn.setNums 4, 7
              # cleared, recalculating once
              equal dn.calcHits.doubled, undefined
              equal dn.doubled, 8
              equal dn.doubled, 8
              equal dn.calcHits.doubled, 1

            it "clearing forces recaclulation of property value", ->
              dn.setNums 4, 7
              # not cleared, stays as is
              equal dn.calcHits.added, undefined
              equal dn.added, 11
              equal dn.added, 11
              equal dn.calcHits.added, 1

              # cleared, recalculating once
              equal dn.calcHits.multiplied, undefined
              equal dn.multiplied, 28
              equal dn.multiplied, 28
              equal dn.calcHits.multiplied, 1

        describe "undefined is a valid cached result", ->

          it "undefined is a valid cached result", ->
            # cleared, recalculating once
            equal dn3.calcHits.doubled, undefined
            equal dn3.doubled, undefined
            equal dn3.calcHits.doubled, 1

            equal dn3.doubled, undefined
            equal dn3.doubled, undefined
            equal dn3.calcHits.doubled, 1

            deepEqual dn3.cleanProps('doubled'), ['doubled']
            dn3.setNums 5
            equal dn3.calcHits.doubled, undefined
            equal dn3.doubled, 10
            equal dn3.calcHits.doubled, 1
            equal dn3.doubled, 10
            equal dn3.doubled, 10
            equal dn3.calcHits.doubled, 1

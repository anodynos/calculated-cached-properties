describe "CalculatedCachedProperties:", ->
    class CalculatedCachedProperties2 extends CalculatedCachedProperties

    class SelfishNumber extends CalculatedCachedProperties2
        constructor: ->
            super {isOverwrite: true}
            @setNums.apply @, arguments

        setNums: (@x, @y)->
            @calcHits = {}

        @CCP_calcProperties =
            doubled: ->
                @calcHits.doubled = (@calcHits.doubled or 0) + 1
                if @x < 1000
                    @x + @x
                else
                    undefined # a valid cached result

            added: -> throw new Error('Abstract method')

    class DirtyNumbers extends SelfishNumber

        @CCP_calcProperties =
            added: ->
                @calcHits.added = (@calcHits.added or 0) + 1
                @x + @y

            multiplied: ->
                @calcHits.multiplied = (@calcHits.multiplied or 0) + 1
                @x * @y

    allDnProperties =
        doubled: SelfishNumber.CCP_calcProperties.doubled
        added: DirtyNumbers.CCP_calcProperties.added # overriden
        multiplied: DirtyNumbers.CCP_calcProperties.multiplied

    describe "CalculatedCachedProperties has a VERSION.", ->
        it "It is not empty:", ->
            fals _.isEmpty CalculatedCachedProperties.VERSION

    describe "a class without constructor", ->
        it "can be instantiated", ->
            ok new CalculatedCachedProperties2

    describe "a subclass with constructor", ->

        sum = -> @a + @b

        it "can be instantiated with super", ->

            class Summed extends CalculatedCachedProperties

                constructor: ->
                    _.extend @, a: 1, b: 2
                    super

                @CCP_calcProperties = {sum}

            s = new Summed "some", "args", CCP_options: debugLevel: 100

            equal s.sum, 3

        it "can be instantiated without super, initialized as soon as it's cleaned", ->

            class Summed extends CalculatedCachedProperties

                constructor: ->
                    _.extend @, a: 1, b: 2

                @CCP_calcProperties = {sum}

            s = new Summed "some", "args", CCP_options: debugLevel: 100

            equal s.sum, undefined

            s.CCP_clean()

            equal s.sum, 3

        it.skip "can be passed CCP_options", -> # how do we test this ?

    describe "Get classes & CCP_calcProperties of inherited classes", ->
        dn = new DirtyNumbers
        sn = new SelfishNumber

        describe "called on target instance:", ->
            it "instance #1", ->
                deepEqual dn.CCP_classes, [CalculatedCachedProperties, CalculatedCachedProperties2, SelfishNumber,
                                           DirtyNumbers]

            it "instance #2", ->
                deepEqual sn.CCP_classes, [CalculatedCachedProperties, CalculatedCachedProperties2, SelfishNumber]

        describe "Get all calculated properties, overriding properties in parent classes:", ->
            describe "without params:", ->
                describe "called on instance:", ->
                    it "instance #1", ->
                        deepEqual dn.CCP_getAllCalcProperties(), allDnProperties
                        deepEqual dn.CCP_allCalcProperties, allDnProperties

                    it "instance #2", ->
                        deepEqual sn.CCP_getAllCalcProperties(), SelfishNumber.CCP_calcProperties
                        deepEqual sn.CCP_allCalcProperties, SelfishNumber.CCP_calcProperties

                describe "called statically:", ->
                    it "instance #1", -> deepEqual DirtyNumbers.CCP_getAllCalcProperties(), allDnProperties
                    it "instance #2", -> deepEqual SelfishNumber.CCP_getAllCalcProperties(), SelfishNumber.CCP_calcProperties

            describe "with instance as param:", ->
                describe "called on (any) instance:", ->
                    it "instance #1", -> deepEqual sn.CCP_getAllCalcProperties(dn), allDnProperties
                    it "instance #2", -> deepEqual dn.CCP_getAllCalcProperties(sn), SelfishNumber.CCP_calcProperties

                describe "called statically (on any class):", ->
                    it "instance #1", ->
                        deepEqual DirtyNumbers.CCP_getAllCalcProperties(dn), allDnProperties
                        deepEqual SelfishNumber.CCP_getAllCalcProperties(dn), allDnProperties
                        deepEqual CalculatedCachedProperties.CCP_getAllCalcProperties(dn), allDnProperties
                    it "instance #2", ->
                        deepEqual DirtyNumbers.CCP_getAllCalcProperties(sn), SelfishNumber.CCP_calcProperties
                        deepEqual SelfishNumber.CCP_getAllCalcProperties(sn), SelfishNumber.CCP_calcProperties
                        deepEqual CalculatedCachedProperties.CCP_getAllCalcProperties(sn), SelfishNumber.CCP_calcProperties

            describe "with class as param:", ->
                describe "called on (any) instance:", ->
                    it "instance #1", -> deepEqual sn.CCP_getAllCalcProperties(DirtyNumbers), allDnProperties
                    it "instance #2", -> deepEqual dn.CCP_getAllCalcProperties(SelfishNumber), SelfishNumber.CCP_calcProperties

            describe "called statically (on any class):", ->
                it "instance #1", ->
                    deepEqual CalculatedCachedProperties.CCP_getAllCalcProperties(DirtyNumbers), allDnProperties
                    deepEqual SelfishNumber.CCP_getAllCalcProperties(DirtyNumbers), allDnProperties
                it "instance #2", ->
                    deepEqual CalculatedCachedProperties.CCP_getAllCalcProperties(SelfishNumber), SelfishNumber.CCP_calcProperties
                    deepEqual DirtyNumbers.CCP_getAllCalcProperties(SelfishNumber), SelfishNumber.CCP_calcProperties

    describe "POJSO's prototype registering:", ->
        ObjectDotPrototype = _.clone Object.prototype, true

        calcValue = {some: 'value'}

        obj = CalculatedCachedProperties.register {someProp: 5}, someCalcProperty: -> calcValue

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

        describe "object instance is correctly identified as: ", ->
            it "_B.isHash", ->
                tru _B.isHash obj

            it.skip "_.isPlainObject", ->
                tru _.isPlainObject obj # fails

            it.skip "obj.constructor is Object", ->
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
                describe "Can clean properties before they are even used : for `#{title}`: ", ->
                    deepEqual dn.CCP_clean('doubled'), ['doubled']

                describe "Can clean properties that dont even exist: for `#{title}`: ", ->
                    deepEqual dn.CCP_clean('NOT_EXISTENT'), ['NOT_EXISTENT']

                describe "calculates CCP_calcProperties once: for `#{title}`: ", ->
                    it "instance #1", ->
                        equal dn.doubled, 6
                        equal dn.doubled, 6
                        equal dn.calcHits.doubled, 1

                        equal dn.added, 7
                        equal dn.added, 7
                        equal dn.calcHits.added, 1

                        equal dn.multiplied, 12
                        equal dn.multiplied, 12
                        equal dn.calcHits.multiplied, 1

                    it "instance #2", ->
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
                    it "instance #1", ->
                        dn.x = 55;
                        dn.y = 44;
                        equal dn.added, 7
                        equal dn.added, 7
                        equal dn.calcHits.added, 1

                        equal dn.multiplied, 12
                        equal dn.multiplied, 12
                        equal dn.calcHits.multiplied, 1

                    it "instance #2", ->
                        dn2.x = 22;
                        dn2.y = 33;
                        equal dn2.added, 11
                        equal dn2.added, 11
                        equal dn2.calcHits.added, 1

                        equal dn2.multiplied, 30
                        equal dn2.multiplied, 30
                        equal dn2.calcHits.multiplied, 1

                describe "setting value of property manually becomes the cached result", ->
                    it "instance #1", ->
                        dn.added = 333
                        equal dn.added, 333
                        equal dn.added, 333
                        equal dn.calcHits.added, 1

                        dn.multiplied = 555
                        equal dn.multiplied, 555
                        equal dn.multiplied, 555
                        equal dn.calcHits.multiplied, 1

                    it "instance #2", ->
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
                        deepEqual dn.CCP_clean('added'), ['added']

                        dn.x = 6;
                        dn.y = 3
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
                        dn.x = 6;
                        dn.y = 4
                        deepEqual(
                            dn.CCP_clean(undefined, 'doubled', undefined, ((nme)-> nme is 'multiplied'), undefined)
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
                            deepEqual dn.CCP_clean(), ['doubled', 'added', 'multiplied']

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

                        deepEqual dn3.CCP_clean('doubled'), ['doubled']
                        dn3.setNums 5
                        equal dn3.calcHits.doubled, undefined
                        equal dn3.doubled, 10
                        equal dn3.calcHits.doubled, 1
                        equal dn3.doubled, 10
                        equal dn3.doubled, 10
                        equal dn3.calcHits.doubled, 1

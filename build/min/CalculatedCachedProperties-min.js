/**
* calculated-cached-properties https://github.com/anodynos/calculated-cached-properties
*
* CalculatedCachedProperties allows properties to have values calculated by a function, and then cached. You can then manually invalidate (clean) the cache for one or more (or all) properties, forcing the function to be invoked and recalculate next time the property is accessed. You can also set the value of a property manually. Undefined / null etc are all valid property values. Works with POJSOs, JS constructors and CoffeeScript classes (i.e `MyClass extends CalculatedCachedProperties`, and then just call `super` constructor). A spinoff from uBerscore library. Docs will follow, see the specs till then :-)
* Version 0.2.1 - Compiled on 2015-06-29 16:05:44
* Repository git://github.com/anodynos/calculated-cached-properties
* Copyright(c) 2015 Angelos Pikoulas <agelos.pikoulas@gmail.com>
* License MIT http://www.opensource.org/licenses/mit-license.php
*/

(function(){var e=!("function"!=typeof define||!define.amd),t="object"==typeof exports;(function(r){var o=function(r,o){return e||t||(r.CalculatedCachedProperties=o),o};if("object"==typeof exports)module.exports=o(global,r(require,exports,module));else if("function"==typeof define&&define.amd)define(["require","exports","module"],function(e,t,i){return o(window,r(e,t,i))});else{var i=function(e){throw new Error("uRequire: Loading UMD module as <script>, failed to `require('"+e+"')`: reason unexpected !")},n={},s={exports:n};o(window,r(i,n,s))}}).call(this,function(e,t,r){var o,i,n="0.2.1",s=[].slice;return i={extend:function(e,t){var r;for(r in t)e[r]=t[r]},defaults:function(e,t){var r;for(r in t)e.hasOwnProperty(r)||(e[r]=t[r])},keys:function(e){var t,r;r=[];for(t in e)r.push(t);return r},isFunction:function(e){return"function"==typeof e}},o=function(){function e(e){this._CCP_defineCalcProperties(e)}var t,r,o;return e.VERSION=n,o=function(e){return"__$$_CCP_"+e},r=o("cache"),t={"CalculatedCachedProperties Undefined":!0},e.register=function(t,r,o){var n,s,c;return null==o&&(o=e.optionsDefaults),o!==e.optionsDefaults&&i.defaults(o||(o={}),e.optionsDefaults),i.isFunction(t)?(n=t,i.extend(n.prototype,e.prototype),i.extend(n.CCP_calcProperties||(n.CCP_calcProperties={}),r),n.prototype._CCP_defineCalcProperties(o)):(c=t,i.extend(c.__proto__={},e.prototype),c.constructor=s=function(){},s.prototype=c.__proto__,i.extend(s.prototype,e.prototype),i.extend(s.CCP_calcProperties||(s.CCP_calcProperties={}),r),c._CCP_defineCalcProperties(o)),t},e.prototype.CCP_getClasses=function(e,t){return null==t&&(t=[]),e||(e=this),i.isFunction(e)||(e=e.constructor),t.unshift(e),e.__super__?this.CCP_getClasses(e.__super__.constructor,t):t},e.CCP_getClasses=e.prototype.CCP_getClasses,e.prototype.CCP_getAllCalcProperties=function(e){var t,r,o,i,n,s,c,l;for(null==e&&(e=this),i={},c=this.CCP_getClasses(e),n=0,s=c.length;s>n;n++){t=c[n],l=t.CCP_calcProperties;for(o in l)r=l[o],i[o]=r}return i},e.CCP_getAllCalcProperties=e.prototype.CCP_getAllCalcProperties,Object.defineProperties(e.prototype,{CCP_allCalcProperties:{get:function(){return this.constructor.prototype.hasOwnProperty("_allCalcProperties")||Object.defineProperty(this.constructor.prototype,"_allCalcProperties",{value:this.CCP_getAllCalcProperties(),enumerable:!1}),this.constructor.prototype._allCalcProperties}},CCP_classes:{get:function(){return this.constructor.prototype.hasOwnProperty("_classes")||Object.defineProperty(this.constructor.prototype,"_classes",{value:this.CCP_getClasses(),enumerable:!1}),this.constructor.prototype._classes}}}),e.prototype._CCP_initCache=function(){var e,o,i;Object.defineProperty(this,r,{value:{},enumerable:!0,configurable:!1,writeable:!1}),i=this.CCP_allCalcProperties||this.CCP_getAllCalcProperties();for(o in i)e=i[o],this[r][o]=t},e.prototype._CCP_defineCalcProperties=function(e){var o,i,n;this.constructor.isDebug=function(t){return e.debugLevel>=t},n=this.CCP_allCalcProperties||this.CCP_getAllCalcProperties();for(i in n)o=n[i],(!this.constructor.prototype.hasOwnProperty(i)||e.isOverwrite)&&!function(e){return function(o,i){return Object.defineProperty(e.constructor.prototype,o,{enumerable:!0,configurable:!0,get:function(){var e;return this[r]||this._CCP_initCache(),this[r][o]===t&&(e=i.call(this),this[r][o]=e),this[r][o]},set:function(e){return this[r]||this._CCP_initCache(),this[r][o]=e}})}}(this)(i,o)},e.prototype.CCP_clean=function(){var e,o,n,c,l,p,C,u,a;for(o=1<=arguments.length?s.call(arguments,0):[],0===o.length&&(o=i.keys(this.CCP_allCalcProperties||this.CCP_getAllCalcProperties())),n=[],p=0,u=o.length;u>p;p++)if(e=o[p])if(i.isFunction(e))for(l||(l=i.keys(this.CCP_allCalcProperties||this.CCP_getAllCalcProperties())),C=0,a=l.length;a>C;C++)c=l[C],e(c)&&(this[r]?this[r][c]=t:this._CCP_initCache(),n.push(c));else this[r]?this[r][e]=t:this._CCP_initCache(),n.push(e);return n},e}(),o.optionsDefaults={isOverwrite:!1,debugLevel:0},r.exports=o,r.exports})}).call(this);
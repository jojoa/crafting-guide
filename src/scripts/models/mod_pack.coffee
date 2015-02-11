###
Crafting Guide - mod_pack.coffee

Copyright (c) 2014-2015 by Redwood Labs
All rights reserved.
###

BaseModel            = require './base_model'
{Event}              = require '../constants'
ModVersionParser     = require './mod_version_parser'
{DefaultModVersions} = require '../constants'
{Url}                = require '../constants'

########################################################################################################################

module.exports = class ModPack extends BaseModel

    constructor: (attributes={}, options={})->
        super attributes, options

        @_mods = []

    # Public Methods ###############################################################################

    findItem: (slug, options={})->
        options.includeDisabled ?= false

        [modSlug, itemSlug] = _.decomposeSlug slug
        if modSlug?
            mod = @getMod modSlug
            if mod?
                item = mod.findItem itemSlug, options
                return item if item?

        for mod in @_mods
            continue unless mod.enabled or options.includeDisabled
            item = mod.findItem itemSlug, options
            return item if item?

        return null

    findItemByName: (name, options={})->
        options.enableAsNeeded ?= false
        options.includeDisabled = true if options.enableAsNeeded

        for mod in @_mods
            continue unless mod.enabled or options.includeDisabled
            item = mod.findItemByName name, options
            return item if item?

        return null

    findItemDisplay: (slug)->
        if not slug? then return null

        result = {}
        item = @findItem slug, includeDisabled:true
        if item?
            result.modSlug    = item.modVersion.modSlug
            result.modVersion = item.modVersion.version
            result.slug       = item.slug
            result.itemName   = item.name
        else
            result.modSlug    = @_mods[0].slug
            result.modVersion = @_mods[0].activeVersion
            result.slug       = slug
            result.itemName   = @findName slug, includeDisabled:true

        result.craftingUrl = Url.crafting inventoryText:slug
        result.iconUrl     = Url.itemIcon result
        result.itemUrl     = Url.item result
        return result

    findName: (slug)->
        for mod in @_mods
            continue unless mod.enabled
            name = mod.findName slug
            return name if name

        return null

    findRecipes: (slug, result=[])->
        [modSlug, itemSlug] = _.decomposeSlug slug

        if modSlug?
            mod = @getMod modSlug
            if mod?
                mod.findRecipes slug, result
                return result if result.length > 0

        for mod in @_mods
            continue unless mod.enabled
            mod.findRecipes slug, result
        return result

    isGatherable: (slug)->
        item = @findItem slug
        return true if not item?
        return true if item.isGatherable
        return false if item.isCraftable
        return true

    isValidName: (name)->
        slug = _.slugify name
        existingName = @findName slug

        return name is existingName

    # Property Methods #############################################################################

    addMod: (mod)->
        if not mod? then throw new Error 'mod is required'
        return if @_mods.indexOf(mod) isnt -1

        mod.modPack = this
        @_mods.push mod
        @listenTo mod, Event.change, => @trigger Event.change, this
        @trigger Event.add + ':mod', mod, this

        @_mods.sort (a, b)-> a.compareTo b
        @trigger Event.sort + ':mod', this
        @trigger Event.change, this

        return this

    eachMod: (callback)->
        for mod in @_mods
            callback mod

    getMod: (slug)->
        for mod in @_mods
            return mod if mod.slug is slug
        return null

    getMods: ->
        return @_mods[..]

    # Object Overrides #############################################################################

    toString: ->
        return "ModPack (#{@cid}) {modVersions:«#{@_mods.length} items»}"

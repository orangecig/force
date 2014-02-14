_                     = require 'underscore'
sd                    = require('sharify').data
Backbone              = require 'backbone'
ShareView             = require './share.coffee'
Transition            = require '../../../components/mixins/transition.coffee'
CurrentUser           = require '../../../models/current_user.coffee'
SaveButton            = require '../../../components/save_button/view.coffee'
RelatedPostsView      = require '../../../components/related_posts/view.coffee'
RelatedArtworksView   = require './related-artworks.coffee'
ContactPartnerView    = require '../../../components/contact/contact_partner.coffee'
InquiryView           = require '../../../components/contact/inquiry.coffee'

Artworks = require '../../../collections/artworks.coffee'
artistArtworksTemplate = -> require('../templates/_artist-artworks.jade') arguments...

{ Following, FollowButton } = require '../../../components/follow_button/index.coffee'

module.exports = class ArtworkView extends Backbone.View
  events:
    'click a[data-client]'                : 'intercept'
    'click .circle-icon-button-share'     : 'openShare'
    'click .circle-icon-button-save'      : 'saveArtwork'
    'click .artwork-additional-image'     : 'changeImage'
    'click .artwork-contact-button'       : 'contactPartner'
    'click .artwork-inquiry-button'       : 'inquire'

  initialize: (options) ->
    { @artwork, @artist } = options

    @setupRelatedPosts()
    @setupCurrentUser()
    @setupArtistArtworks()
    @setupFollowButton()
    @setupRelatedArtworks()

    # Setup the primary save button
    @setupSaveButton @$('.circle-icon-button-save'), @artwork
    @syncSavedArtworks @artwork

  setupCurrentUser: ->
    @currentUser = CurrentUser.orNull()
    @currentUser?.initializeDefaultArtworkCollection()
    @saved      = @currentUser?.defaultArtworkCollection()
    @following  = new Following(null, kind: 'artist') if @currentUser?

  setupArtistArtworks: ->
    return unless @artist?.get('artworks_count') > 1
    @listenTo @artist.artworks, 'sync', @renderArtistArtworks
    @artist.artworks.fetch data: size: 5, published: true

  renderArtistArtworks: ->
    # Ensure the current artwork is not in the collection
    @artist.artworks.remove @artwork
    @$('.artwork-artist').attr 'data-state', 'complete'
    @$('#artwork-artist-artworks-container').
      addClass('is-loaded').
      html(artistArtworksTemplate artworks: @artist.artworks)
    @setupArtistArtworkSaveButtons @artist.artworks

  setupArtistArtworkSaveButtons: (artworks) ->
    return unless artworks.length > 0
    _.defer =>
      for artwork in artworks.models
        @setupSaveButton @$(".overlay-button-save[data-id='#{artwork.id}']"), artwork
      @syncSavedArtworks artworks

  # @param {Object or Array or Backbone.Collection}
  syncSavedArtworks: (artworks) ->
    return unless @saved
    @__saved__ ?= new Backbone.Collection
    @__saved__.add artworks?.models or artworks
    @saved.addRepoArtworks @__saved__
    @saved.syncSavedArtworks()

  setupRelatedPosts: ->
    new RelatedPostsView
      el: @$('#artwork-artist-related-posts-container')
      numToShow: 2
      model: @artwork

  setupRelatedArtworks: ->
    new RelatedArtworksView
      model: @artwork
      el: @$('#artwork-related-artworks-section')

  route: (route) ->
    # Initial server rendered route is 'show'
    # No transition unless it's happening client-side
    return if @$el.attr('data-route') is route
    @$el.attr 'data-route-pending', (@__route__ = route)
    Transition.fade @$el,
      duration: 250
      out: =>
        @$el.attr 'data-route', @__route__

  # Handle links with the data-client attribute via pushState
  intercept: (e) ->
    e.preventDefault()
    Backbone.history.navigate $(e.currentTarget).attr('href'), true

  openShare: (e) ->
    e.preventDefault()
    new ShareView width: '350px', artwork: @artwork

  setupFollowButton: ->
    @followButton = new FollowButton
      el: @$('.artwork-artist-follow-button')
      following: @following
      model: @artist

    @following?.syncFollows [@artist.id]

  setupSaveButton: ($el, artwork, options = {}) ->
    new SaveButton
      analyticsSaveMessage: 'Added artwork to collection, via artwork info'
      analyticsUnsaveMessage: 'Removed artwork from collection, via artwork info'
      el: $el
      saved: @saved
      model: artwork

  contactPartner: (e) ->
    e.preventDefault()
    new ContactPartnerView artwork: @artwork, partner: @artwork.get('partner')

  inquire: (e) ->
    e.preventDefault()
    new InquiryView artwork: @artwork

  changeImage: (e) ->
    e.preventDefault()

    (@$artworkAdditionalImages ?= @$('.artwork-additional-image')).
      removeClass 'is-active'
    ($target = $(e.currentTarget)).
      addClass 'is-active'
    (@$artworkImage ?= @$('#the-artwork-image')).
      attr('src', $target.data 'href')

    @artwork.setActiveImage($target.data 'id')

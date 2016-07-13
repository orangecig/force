_ = require 'underscore'
sd = require('sharify').data
CTABarView = require '../../../components/cta_bar/view.coffee'
Backbone = require 'backbone'
analyticsHooks = require '../../../lib/analytics_hooks.coffee'
marketoForm = -> require('../templates/marketo_form.jade') arguments...

module.exports = class GalleryInsightsView extends Backbone.View

  initialize: ->
    @ctaBarView = new CTABarView
      headline: 'Artsy Insights for Galleries'
      mode: 'gallery-insights'
      name: 'gallery-insights-signup'
      persist: true
      subHeadline: "Receive periodical insights from Artsy's Gallery Team"
    return if @ctaBarView.previouslyDismissed() or
              (not @inGIArticlePage() and not @inGIVerticalPage())
    @renderCTA => @setupCTAWaypoints()

  inGIArticlePage: ->
    sd.GALLERY_INSIGHTS_SECTION_ID in (sd.ARTICLE?.section_ids or [])

  inGIVerticalPage: ->
    sd.SECTION?.id is sd.GALLERY_INSIGHTS_SECTION_ID

  renderCTA: (callback) ->
    @$('.articles-insights-show').show()
    @$('.articles-insights-section').show()
    # We have to wait for the first Marketo form embedded at the bottom of
    # the page to render and remove the Marketo id from the element. Otherwise
    # Marketo will try to render the form in both places, causing the form to
    # appear twice at the bottom of the page. We then hack in the Marketo
    # replacing our typical CTA form elements. ┐('～`；)┌
    MktoForms2?.whenReady _.once (form) =>
      @$('#mktoForm_1230').removeAttr 'id'
      @ctaBarView.render()
      @ctaBarView.$el?.find('.cta-bar-small-form').replaceWith marketoForm()
      @$el.append @ctaBarView.$el
      callback()

  setupCTAWaypoints: ->
    if @inGIArticlePage()
      @$(".article-container[data-id=#{sd.ARTICLE.id}]").waypoint (direction) =>
        @ctaBarView.transitionIn() if direction is 'down'
      , { offset: -200 }
      @$(".article-container[data-id=#{sd.ARTICLE.id}]").waypoint (direction) =>
        @ctaBarView.transitionOut() if direction is 'down'
        @ctaBarView.transitionIn() if direction is 'up'
      , { offset: 'bottom-in-view' }
    else if @inGIVerticalPage()
      @$('.js-articles-feed-articles').waypoint (direction) =>
        @ctaBarView.transitionIn() if direction is 'down'
      ,{ offset: '50%' }
      @$('.js-articles-feed-articles').waypoint (direction) =>
        @ctaBarView.transitionOut() if direction is 'down'
        @ctaBarView.transitionIn() if direction is 'up'
      , { offset: 'bottom-in-view' }

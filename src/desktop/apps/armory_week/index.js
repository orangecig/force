import React from 'react'
import { renderLayout } from '@artsy/stitch'

import adminOnly from '../../lib/admin_only'
import JSONPage from '../../components/json_page/es6'
import ArmoryWeekPage from './components/ArmoryWeekPage'
import merge from 'lodash.merge'
import queryString from 'query-string'

const SLUG = 'armory-week'
const MARKETING_MODAL_ID = 'ca18'

class EditableArmoryWeekPage extends JSONPage {
  registerRoutes() {
    this.app.get(this.jsonPage.paths.show, this.show.bind(this))
    this.app.get(this.jsonPage.paths.show + '/data', adminOnly, this.data)
    this.app.get(this.jsonPage.paths.edit, adminOnly, this.edit)
    this.app.post(this.jsonPage.paths.edit, adminOnly, this.upload)
  }

  async show(req, res, next) {
    try {
      if (req.query['m-id'] !== MARKETING_MODAL_ID) {
        const queryStringAsString = queryString.stringify(
          merge({}, req.query, { 'm-id': MARKETING_MODAL_ID })
        )

        return res.redirect(`/${SLUG}?${queryStringAsString}`)
      }

      const data = await this.jsonPage.get()
      const layout = await renderLayout({
        basePath: __dirname,
        layout: '../../components/main_layout/templates/react_index.jade',
        config: {
          styledComponents: true,
        },
        blocks: {
          head: './templates/meta.jade',
          body: ArmoryWeekPage,
        },
        locals: {
          assetPackage: 'banner_pop_up',
        },
        data: {
          ...res.locals,
          ...data,
          displayStickyFooter: !req.user,
          data,
        },
      })

      res.send(layout)
    } catch (error) {
      next(error)
    }
  }
}

export default new EditableArmoryWeekPage({
  name: SLUG,
  paths: { show: `/${SLUG}`, edit: `/${SLUG}/edit` },
}).app

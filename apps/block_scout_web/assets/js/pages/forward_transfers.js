import $ from 'jquery'
import omit from 'lodash.omit'
import humps from 'humps'
import numeral from 'numeral'
import socket from '../socket'
import { connectElements } from '../lib/redux_helpers.js'
import { batchChannel } from '../lib/utils'
import { createAsyncLoadStore } from '../lib/random_access_pagination'
import '../app'

const BATCH_THRESHOLD = 10

export const initialState = {
  channelDisconnected: false,
  forwardTransferCount: null,
  forwardTransfersBatch: []
}

export function reducer (state = initialState, action) {
  switch (action.type) {
    case 'ELEMENTS_LOAD': {
      return Object.assign({}, state, omit(action, 'type'))
    }
    case 'CHANNEL_DISCONNECTED': {
      return Object.assign({}, state, {
        channelDisconnected: true
      })
    }
    case 'RECEIVED_NEW_FORWARD_TRANSFER_BATCH': {
      if (state.channelDisconnected) return state

      const forwardTransferCount = state.forwardTransferCount + action.msgs.length
      const forwardTransferHtml = action.msgs.map(message => message.transactionHtml)

      if (!state.forwardTransfersBatch.length && action.msgs.length < BATCH_THRESHOLD) {
        return Object.assign({}, state, {
          items: [
            ...forwardTransferHtml.reverse(),
            ...state.items
          ],
          forwardTransferCount
        })
      } else {
        return Object.assign({}, state, {
          forwardTransfersBatch: [
            ...forwardTransferHtml.reverse(),
            ...state.forwardTransfersBatch
          ],
          forwardTransferCount
        })
      }
    }
    default:
      return state
  }
}

const elements = {
  '[data-selector="channel-disconnected-message"]': {
    render ($el, state) {
      if (state.channelDisconnected && !window.loading) $el.show()
    }
  },
  '[data-selector="channel-batching-count"]': {
    render ($el, state, oldState) {
      const $channelBatching = $('[data-selector="channel-batching-message"]')
      if (state.forwardTransfersBatch.length) {
        $channelBatching.show()
        $el[0].innerHTML = numeral(state.forwardTransfersBatch.length).format()
      } else {
        $channelBatching.hide()
      }
    }
  },
  '[data-selector="forward-transfer-count"]': {
    load ($el) {
      return { forwardTransferCount: numeral($el.text()).value() }
    },
    render ($el, state, oldState) {
      if (oldState.transactionCount === state.transactionCount) return
      $el.empty().append(numeral(state.transactionCount).format())
    }
  }
}

const $forwardTransfersListPage = $('[data-page="forward-transfer-list"]')
if ($forwardTransfersListPage.length) {
  window.onbeforeunload = () => {
    window.loading = true
  }

  const store = createAsyncLoadStore(reducer, initialState, 'dataset.identifier')
  connectElements({ store, elements })

  const forwardTransfersChannel = socket.channel('forward-transfers:new_transaction')
  forwardTransfersChannel.join()
  forwardTransfersChannel.onError(() => store.dispatch({
    type: 'CHANNEL_DISCONNECTED'
  }))
  forwardTransfersChannel.on('forward_transfer', batchChannel((msgs) => store.dispatch({
    type: 'RECEIVED_NEW_FORWARD_TRANSFER_BATCH',
    msgs: humps.camelizeKeys(msgs)
  })))
}
